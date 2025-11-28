import "dart:convert";
import "dart:io";

import "package:http/http.dart" as http;
import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:pull_up_club/common/constants/app_constants.dart";

/// Configuration model for remote app configuration
class AppConfig {
  const AppConfig({required this.minAppVersion, required this.sentryDsn});

  factory AppConfig.fromJson(final Map<String, dynamic> json) {
    return AppConfig(
      minAppVersion: json["minAppVersion"] as String,
      sentryDsn: json["sentryDsn"] as String,
    );
  }
  final String minAppVersion;
  final String sentryDsn;

  Map<String, dynamic> toJson() {
    return {"minAppVersion": minAppVersion, "sentryDsn": sentryDsn};
  }

  @override
  String toString() {
    return toJson().toString();
  }

  /// Default fallback configuration
  static const AppConfig defaultConfig = AppConfig(
    minAppVersion: AppConstants.defaultMinAppVersion,
    sentryDsn: AppConstants.defaultSentryDsn,
  );
}

/// Service for managing remote app configuration with caching.
/// Loads config from GitHub Pages and caches it locally.
/// Only re-downloads if the remote file has changed (via ETag header).
class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();
  static final Logger _logger = Logger("RemoteConfigService");

  static const String _configFileName = "app_config.json";
  static const String _etagFileName = "app_config.etag";

  AppConfig? _cachedConfig;
  bool _isInitialized = false;
  File? _configFile;
  File? _etagFile;

  /// Initialize the service and load configuration.
  /// Returns the loaded config (or default if loading fails).
  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.info("Remote config is already initialized");
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      _configFile = File("${directory.path}/$_configFileName");
      _etagFile = File("${directory.path}/$_etagFileName");

      // Try to load from cache first
      _cachedConfig = await _loadFromCache();
      await _updateCacheWithRemoteConfig();

      _isInitialized = true;
      _logger
        ..info("RemoteConfigService initialized; using ${getConfig()}")
        ..fine("Config file path: ${_configFile!.path}")
        ..fine("ETag file path: ${_etagFile!.path}");
      return;
    } on Exception catch (e, stackTrace) {
      _logger.severe("Failed to initialize RemoteConfigService", e, stackTrace);
      return;
    }
  }

  /// Get the current configuration.
  /// Returns default config if not initialized.
  AppConfig getConfig() {
    if (_cachedConfig == null) {
      _logger.info("No cached config found, returning default config");
      return AppConfig.defaultConfig;
    }
    return _cachedConfig!;
  }

  /// Download remote configuration using If-None-Match header for efficiency.
  /// Returns null if config hasn't changed (304) or if download fails.
  /// Returns the new config if it has changed (200).
  Future<void> _updateCacheWithRemoteConfig() async {
    try {
      // Read cached ETag if available
      String? cachedEtag;
      if (_etagFile != null && _etagFile!.existsSync()) {
        try {
          cachedEtag = (await _etagFile!.readAsString()).trim();
        } on Exception catch (e) {
          _logger.info("Failed to read cached ETag: $e");
        }
      }

      // Build request headers with If-None-Match if we have a cached ETag
      final headers = <String, String>{};
      if (cachedEtag != null && cachedEtag.isNotEmpty) {
        headers["If-None-Match"] = cachedEtag;
      }

      final response = await http
          .get(Uri.parse(AppConstants.remoteConfigUrl), headers: headers)
          .timeout(const Duration(milliseconds: 2000));

      // 304 Not Modified - config hasn't changed, use cached version
      if (response.statusCode == 304) {
        _logger.info("Remote config unchanged (304 Not Modified)");
        return;
      } else if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final config = AppConfig.fromJson(json);
        final etag = response.headers["etag"];

        // Update the cached config
        _cachedConfig = config;
        await _saveToDisk(config, etag);

        _logger.info("Updated cache with remote config");
        return;
      } else {
        _logger.warning("Failed to download config: status ${response.statusCode}");
        return;
      }
    } on Exception catch (e, stackTrace) {
      _logger.severe(
        "Unexpected failure while downloading remote config",
        e,
        stackTrace,
      );
      return;
    }
  }

  /// Load configuration from local cache.
  Future<AppConfig?> _loadFromCache() async {
    if (_configFile == null || !_configFile!.existsSync()) {
      _logger.info("No cached config file found");
      return null;
    }

    try {
      final content = await _configFile!.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      _logger.info("Loaded config from cache");
      return AppConfig.fromJson(json);
    } on Exception catch (e) {
      _logger.warning("Failed to load config from cache: $e");
      return null;
    }
  }

  /// Save configuration to local cache.
  Future<void> _saveToDisk(final AppConfig config, final String? etag) async {
    if (_configFile == null) {
      return;
    }

    try {
      final json = jsonEncode(config.toJson());
      await _configFile!.writeAsString(json);

      if (etag != null && _etagFile != null) {
        await _etagFile!.writeAsString(etag.trim());
      }
      _logger.info("Successfully config and etag to disk");
    } on Exception catch (e) {
      _logger.warning("Failed to save config to cache: $e");
    }
  }
}
