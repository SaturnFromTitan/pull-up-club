import "dart:convert";

import "package:crypto/crypto.dart";
import "package:logging/logging.dart";
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
}
