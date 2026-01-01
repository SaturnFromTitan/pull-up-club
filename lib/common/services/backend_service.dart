import "dart:convert";

import "package:crypto/crypto.dart";
import "package:logging/logging.dart";
import "package:pull_up_club/domain/models.dart";
import "package:pull_up_club/domain/server_models.dart";
import "package:sign_in_with_apple/sign_in_with_apple.dart";
import "package:supabase_flutter/supabase_flutter.dart";

/// Service to interact with a remote BE for user auth and to persist workout data remotely.
class BackendService {
  BackendService._();
  static final BackendService instance = BackendService._();
  static final Logger _logger = Logger("BackendService");

  // Edge functions
  static const String _edgeFunctionUserSelfDelete = "user-self-delete";

  SupabaseClient? _client;
  bool _initialized = false;

  /// Initializes the BE client with the provided URL and publishable key.
  /// Should be called during app startup.
  Future<void> initialize({
    required final String backendUrl,
    required final String backendPublishableKey,
  }) async {
    if (_initialized) {
      _logger.warning("Backend already initialized");
      return;
    }

    try {
      await Supabase.initialize(url: backendUrl, anonKey: backendPublishableKey);
      _client = Supabase.instance.client;
      _initialized = true;
      _logger.info("Backend initialized successfully");
    } catch (error, stackTrace) {
      _logger.severe("Failed to initialize backend", error, stackTrace);
      rethrow;
    }
  }

  /// Gets the current user's ID.
  /// Returns null if not authenticated.
  String? get currentUserId => _client?.auth.currentUser?.id;

  /// Checks if the user is currently authenticated.
  bool get isAuthenticated => currentUserId != null;

  /// Signs in with Apple using native iOS Sign In with Apple.
  /// Returns true on success, false on cancellation.
  /// This will show the native Apple Sign In dialog on iOS.
  /// Based on: https://supabase.com/docs/guides/auth/social-login/auth-apple?queryGroups=platform&platform=flutter
  Future<bool> signInWithApple() async {
    if (!_initialized) {
      throw Exception("Backend not initialized");
    }

    try {
      _logger.info("Starting Apple Sign In");

      // Generate a raw nonce using Supabase's method
      final rawNonce = _client!.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      // Request Apple ID credential with hashed nonce
      // No scopes requested - only basic authentication, no email/name permissions
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email],
        nonce: hashedNonce,
      );

      _logger.info("Apple credential received: ${appleCredential.userIdentifier}");

      // Extract identity token
      final idToken = appleCredential.identityToken;
      if (idToken == null) {
        throw Exception("Could not find ID Token from generated credential");
      }

      // Exchange Apple credential with Supabase using raw nonce
      final response = await _client!.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      _logger.info("User signed in successfully with Apple: ${response.user?.id}");
      return true;
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        _logger.info("Apple Sign In canceled by user");
        return false;
      }
      _logger.severe("Apple Sign In authorization failed", error, StackTrace.current);
      rethrow;
    } catch (error, stackTrace) {
      _logger.severe("Failed to sign in with Apple", error, stackTrace);
      rethrow;
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    if (!_initialized) {
      _logger.warning("Cannot sign out: Backend not initialized");
      return;
    }

    try {
      _logger.info("Signing out user");
      await _client!.auth.signOut();
      _logger.info("User signed out successfully");
    } catch (error, stackTrace) {
      _logger.severe("Failed to sign out user", error, stackTrace);
      rethrow;
    }
  }

  /// Fetches all workouts from the backend.
  /// Returns empty list if not authenticated or on error.
  Future<List<Workout>> fetchWorkouts() async {
    if (!isAuthenticated) {
      _logger.warning("Cannot fetch workouts: not authenticated");
      return [];
    }

    try {
      _logger.info("Fetching workouts from Supabase");
      final response = await _client!
          .from("workouts")
          .select("*, workout_sets(*)")
          .order("end", ascending: false);
      _logger.info("Fetched ${response.length} workouts from Supabase");

      return (response as List<dynamic>)
          .map(
            (final json) =>
                ServerWorkout.fromJson(json as Map<String, dynamic>).toLocal(),
          )
          .toList();
    } on Exception catch (error, stackTrace) {
      _logger.severe("Failed to fetch workouts from Supabase", error, stackTrace);
      return [];
    }
  }

  /// Creates a new workout on the backend.
  /// Note: Supabase/PostgREST does not support nested inserts, so we make two separate calls.
  /// Returns the created workout ID on success, null on error.
  Future<int?> createWorkout(final Workout workout) async {
    if (!isAuthenticated) {
      _logger.warning("Cannot create workout: not authenticated");
      return null;
    }
    if (workout.end == null) {
      throw ArgumentError("Can only upload finished workouts");
    }

    try {
      _logger.info("Creating workout on Supabase: $workout");
      final workoutData = {
        "workout_type": workout.workoutType.name,
        "max_groups": workout.maxGroups,
        // sqlite only supports seconds precision, so for consistency we drop higher precisions here as well
        "start": workout.start
            .copyWith(microsecond: 0, millisecond: 0)
            .toIso8601String(),
        "end": workout.end!.copyWith(microsecond: 0, millisecond: 0).toIso8601String(),
        "idempotency_key": workout.idempotencyKey,
      };

      // Insert workout and get the ID
      final workoutResponse = await _client!
          .from("workouts")
          .insert(workoutData)
          .select("id")
          .single();
      final workoutId = workoutResponse["id"] as int;

      // Insert sets separately (PostgREST doesn't support nested inserts)
      if (workout.sets.isNotEmpty) {
        final setsData = workout.sets
            .map(
              (final set_) => {
                "workout_id": workoutId,
                "group_number": set_.group,
                "target_reps": set_.targetReps,
                "completed_reps": set_.completedReps,
                "number": set_.number,
                "idempotency_key": set_.idempotencyKey,
              },
            )
            .toList();

        await _client!.from("workout_sets").insert(setsData);
      }

      _logger.info("Workout created successfully on Supabase: id=$workoutId");
      return workoutId;
    } on Exception catch (error, stackTrace) {
      _logger.severe("Failed to create workout on Supabase", error, stackTrace);
      return null;
    }
  }

  /// Soft deletes a workout on the backend by setting deleted_at field.
  /// Returns true on success, false on error.
  Future<bool> deleteWorkout({required final Workout localWorkout}) async {
    if (!isAuthenticated) {
      _logger.warning("Cannot delete workout: not authenticated");
      return false;
    }
    if (localWorkout.deletedAt == null) {
      throw ArgumentError("The local workout isn't deleted yet");
    }
    if (localWorkout.serverId == null) {
      _logger.warning(
        "Can't push the deletion as the workout doesn't have a serverId yet",
      );
      return false;
    }

    try {
      _logger.info("Soft deleting workout on Supabase: id=${localWorkout.serverId}");
      await _client!
          .from("workouts")
          // sqlite only supports seconds precision, so for consistency we drop higher precisions here as well
          .update({
            "deleted_at": localWorkout.deletedAt!
                .copyWith(microsecond: 0, millisecond: 0)
                .toIso8601String(),
          })
          .eq("id", localWorkout.serverId!);
      _logger.info(
        "Workout soft deleted successfully on Supabase: id=${localWorkout.serverId}",
      );
      return true;
    } on Exception catch (error, stackTrace) {
      _logger.severe("Failed to soft delete workout on Supabase", error, stackTrace);
      return false;
    }
  }

  /// Deletes the current user's account and all associated data & sign out..
  Future<bool> deleteAccount() async {
    if (!isAuthenticated) {
      _logger.warning("Cannot delete account: not authenticated");
      return false;
    }

    try {
      final userId = currentUserId;
      _logger.info("Starting account deletion for current user: $userId");

      try {
        _logger.info("Calling $_edgeFunctionUserSelfDelete edge function");
        await _client!.functions.invoke(_edgeFunctionUserSelfDelete);
        _logger.info("User account deleted successfully");
      } on Exception catch (error, stackTrace) {
        _logger.severe(
          "Failed to call $_edgeFunctionUserSelfDelete edge function",
          error,
          stackTrace,
        );
        rethrow;
      }

      // Sign out the user
      await signOut();
      return true;
    } on Exception catch (error, stackTrace) {
      _logger.severe("Failed to delete account", error, stackTrace);
      return false;
    }
  }
}
