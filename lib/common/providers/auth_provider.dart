import "dart:async";

import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:pull_up_club/common/services/supabase_service.dart";
import "package:supabase_flutter/supabase_flutter.dart";

/// Provider that manages authentication state
class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _init();
  }

  static final Logger _logger = Logger("AuthProvider");
  final SupabaseClient _supabase = SupabaseService.client;

  User? _user;
  bool _isLoading = true;
  StreamSubscription<AuthState>? _authStateSubscription;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  void _init() {
    // Get initial auth state
    _user = _supabase.auth.currentUser;
    _isLoading = false;
    notifyListeners();

    // Listen to auth state changes
    _authStateSubscription = _supabase.auth.onAuthStateChange.listen((final state) {
      _logger.fine("Auth state changed: ${state.event}");
      _user = state.session?.user;
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Sign up with email and password
  Future<void> signUp({
    required final String email,
    required final String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase.auth.signUp(email: email, password: password);

      if (response.user == null) {
        throw Exception("Sign up failed: No user returned");
      }

      _user = response.user;
      _logger.info("User signed up: ${_user?.email}");
    } catch (e) {
      _logger.severe("Sign up error: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in with email and password
  Future<void> signIn({
    required final String email,
    required final String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      _user = response.user;
      _logger.info("User signed in: ${_user?.email}");
    } catch (e) {
      _logger.severe("Sign in error: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _supabase.auth.signOut();
      _user = null;
      _logger.info("User signed out");
    } catch (e) {
      _logger.severe("Sign out error: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset password
  Future<void> resetPassword(final String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      _logger.info("Password reset email sent to: $email");
    } catch (e) {
      _logger.severe("Password reset error: $e");
      rethrow;
    }
  }

  @override
  void dispose() {
    unawaited(_authStateSubscription?.cancel());
    super.dispose();
  }
}
