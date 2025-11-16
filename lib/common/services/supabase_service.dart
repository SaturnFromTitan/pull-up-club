import "package:logging/logging.dart";
import "package:supabase_flutter/supabase_flutter.dart";

/// Service for managing Supabase client initialization and configuration
class SupabaseService {
  SupabaseService._();
  static final Logger _logger = Logger("SupabaseService");
  static bool _isInitialized = false;

  /// Initialize Supabase with your project URL and anon key
  /// Call this in main() before runApp()
  static Future<void> initialize({
    required final String supabaseUrl,
    required final String supabaseAnonKey,
  }) async {
    if (_isInitialized) {
      _logger.warning("Supabase already initialized");
      return;
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: false, // Set to true for development
      );
      _isInitialized = true;
      _logger.info("Supabase initialized successfully");
    } catch (e) {
      _logger.severe("Failed to initialize Supabase: $e");
      rethrow;
    }
  }

  /// Get the Supabase client instance
  static SupabaseClient get client {
    if (!_isInitialized) {
      throw StateError(
        "Supabase not initialized. Call SupabaseService.initialize() first.",
      );
    }
    return Supabase.instance.client;
  }

  /// Check if Supabase is initialized
  static bool get isInitialized => _isInitialized;
}
