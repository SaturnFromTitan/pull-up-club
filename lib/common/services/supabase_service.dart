import "dart:convert";

import "package:crypto/crypto.dart";
import "package:logging/logging.dart";
import "package:pull_up_club/domain/models.dart";
import "package:pull_up_club/domain/server_models.dart";
import "package:sign_in_with_apple/sign_in_with_apple.dart";
import "package:supabase_flutter/supabase_flutter.dart";

/// Service for managing Supabase authentication and API calls.
/// Handles user authentication and workout data synchronization.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();
  static final Logger _logger = Logger("SupabaseService");

  SupabaseClient? _client;
  bool _initialized = false;

  /// Initializes Supabase with the provided URL and publishable key.
  /// Should be called during app startup.
  Future<void> initialize({
    required final String backendUrl,
    required final String backendPublishableKey,
  }) async {
    if (_initialized) {
      _logger.warning("Supabase already initialized");
      return;
    }

    try {
      await Supabase.initialize(url: backendUrl, anonKey: backendPublishableKey);
      _client = Supabase.instance.client;
      _initialized = true;
      _logger.info("Supabase initialized successfully");
    } catch (error, stackTrace) {
      _logger.severe("Failed to initialize Supabase", error, stackTrace);
      rethrow;
    }
  }

  /// Gets the Supabase client instance.
  /// Returns null if not initialized.
  SupabaseClient? get client => _client;

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
      throw Exception("Supabase not initialized");
    }

    try {
      _logger.info("Starting Apple Sign In");

      // Generate a raw nonce using Supabase's method
      final rawNonce = _client!.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      // Request Apple ID credential with hashed nonce
      // No scopes requested - only basic authentication, no email/name permissions
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [],
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
      _logger.warning("Cannot sign out: Supabase not initialized");
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

  /// Fetches workouts from Supabase with optional delta sync.
  /// If [since] is provided, filters by end >= since OR deleted_at >= since.
  /// Returns empty list if not authenticated or on error.
  Future<List<ServerWorkout>> fetchWorkouts({final DateTime? since}) async {
    if (!isAuthenticated) {
      _logger.warning("Cannot fetch workouts: not authenticated");
      return [];
    }

    try {
      _logger.info(
        "Fetching workouts from Supabase${since != null ? " (delta sync since $since)" : ""}",
      );
      var query = _client!.from("workouts").select("*, workout_sets(*)");

      if (since != null) {
        final sinceStr = since.toIso8601String();
        query = query.or("end.gte.$sinceStr,deleted_at.gte.$sinceStr");
      }

      final response = await query.order("start", ascending: false);
      _logger.info("Fetched ${response.length} workouts from Supabase");

      return (response as List<dynamic>)
          .map((final json) => ServerWorkout.fromJson(json as Map<String, dynamic>))
          .toList();
    } on Exception catch (error, stackTrace) {
      _logger.severe("Failed to fetch workouts from Supabase", error, stackTrace);
      return [];
    }
  }

  /// Creates a new workout on Supabase.
  /// Note: Supabase/PostgREST does not support nested inserts, so we make two separate calls.
  /// Returns the created workout ID on success, null on error.
  Future<int?> createWorkout(final Workout workout) async {
    if (!isAuthenticated) {
      _logger.warning("Cannot create workout: not authenticated");
      return null;
    }

    try {
      _logger.info("Creating workout on Supabase: $workout");
      final workoutData = {
        "workout_type": workout.workoutType.name,
        "max_groups": workout.maxGroups,
        "start": workout.start.toIso8601String(),
        "end": workout.end?.toIso8601String(),
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

  /// Soft deletes a workout on Supabase by setting deleted_at field.
  /// Returns true on success, false on error.
  Future<bool> deleteWorkout(final int workoutId) async {
    if (!isAuthenticated) {
      _logger.warning("Cannot delete workout: not authenticated");
      return false;
    }

    try {
      _logger.info("Soft deleting workout on Supabase: id=$workoutId");
      await _client!
          .from("workouts")
          .update({"deleted_at": DateTime.now().toIso8601String()})
          .eq("id", workoutId);
      _logger.info("Workout soft deleted successfully on Supabase: id=$workoutId");
      return true;
    } on Exception catch (error, stackTrace) {
      _logger.severe("Failed to soft delete workout on Supabase", error, stackTrace);
      return false;
    }
  }
}
