import "dart:convert";
import "dart:io";

import "package:http/http.dart" as http;
import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";

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

  /// Default fallback configuration
  static const AppConfig defaultConfig = AppConfig(
    minAppVersion: "1.0.0",
    sentryDsn:
        "https://e8445aeb8a976bca9c47de2073137e70@o4510399352012800.ingest.de.sentry.io/4510399355289680",
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
  static const String _configUrl =
      "https://saturnfromtitan.github.io/pull-up-club/app-config.json";

  AppConfig? _cachedConfig;
  bool _isInitialized = false;
  File? _configFile;
  File? _etagFile;

  /// Initialize the service and load configuration.
  /// Returns the loaded config (or default if loading fails).
  Future<AppConfig> initialize() async {
    if (_isInitialized && _cachedConfig != null) {
      return _cachedConfig!;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      _configFile = File("${directory.path}/$_configFileName");
      _etagFile = File("${directory.path}/$_etagFileName");

      // Try to load from cache first
      _cachedConfig = await _loadFromCache();

      // Check if remote config has changed
      final shouldDownload = await _shouldDownloadRemoteConfig();
      if (shouldDownload) {
        _logger.info("Remote config changed, downloading...");
        final remoteConfig = await _downloadRemoteConfig();
        if (remoteConfig != null) {
          _cachedConfig = remoteConfig;
          await _saveToCache(remoteConfig);
          _logger.info("Successfully loaded and cached remote config");
        } else if (_cachedConfig == null) {
          // If download failed and no cache exists, use defaults
          _cachedConfig = AppConfig.defaultConfig;
          _logger.warning("Failed to load remote config, using defaults");
        } else {
          _logger.warning("Failed to load remote config, using cached version");
        }
      } else {
        _logger.info("Remote config unchanged, using cached version");
      }

      _isInitialized = true;
      return _cachedConfig ?? AppConfig.defaultConfig;
    } on Exception catch (e, stackTrace) {
      _logger.severe("Failed to initialize RemoteConfigService", e, stackTrace);
      return _cachedConfig ?? AppConfig.defaultConfig;
    }
  }

  /// Get the current configuration.
  /// Returns default config if not initialized.
  AppConfig getConfig() {
    return _cachedConfig ?? AppConfig.defaultConfig;
  }

  /// Check if remote config should be downloaded by comparing ETag.
  Future<bool> _shouldDownloadRemoteConfig() async {
    try {
      // Use HEAD request to check ETag
      final headResponse = await http
          .head(Uri.parse(_configUrl))
          .timeout(const Duration(milliseconds: 2000));

      if (headResponse.statusCode != 200) {
        _logger.warning("HEAD request failed with status ${headResponse.statusCode}");
        return true; // Try to download anyway
      }

      // Check ETag
      final remoteEtag = headResponse.headers["etag"];
      if (remoteEtag != null && _etagFile != null && _etagFile!.existsSync()) {
        final cachedEtag = await _etagFile!.readAsString();
        if (cachedEtag.trim() == remoteEtag.trim()) {
          _logger.fine("ETag matches, no download needed");
          return false;
        }
        _logger.fine("ETag changed, download needed");
        return true;
      }

      // If no ETag available or no cached ETag, we should download
      if (_configFile == null || !_configFile!.existsSync()) {
        return true;
      }

      // If we have cached config but no ETag info, download to get ETag
      return true;
    } on Exception catch (e) {
      _logger.warning("Failed to check remote config status: $e");
      // If we have cached config, don't download on error
      return _configFile == null || !_configFile!.existsSync();
    }
  }

  /// Download remote configuration.
  Future<AppConfig?> _downloadRemoteConfig() async {
    try {
      final response = await http
          .get(Uri.parse(_configUrl))
          .timeout(const Duration(milliseconds: 2000));

      if (response.statusCode != 200) {
        _logger.warning("Failed to download config: status ${response.statusCode}");
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final config = AppConfig.fromJson(json);

      // Save ETag if available
      final etag = response.headers["etag"];
      if (etag != null && _etagFile != null) {
        await _etagFile!.writeAsString(etag);
      }

      return config;
    } on Exception catch (e, stackTrace) {
      _logger.severe("Failed to download remote config", e, stackTrace);
      return null;
    }
  }

  /// Load configuration from local cache.
  Future<AppConfig?> _loadFromCache() async {
    if (_configFile == null || !_configFile!.existsSync()) {
      _logger.warning("No cached config file found");
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
  Future<void> _saveToCache(final AppConfig config) async {
    if (_configFile == null) {
      return;
    }

    try {
      final json = jsonEncode(config.toJson());
      await _configFile!.writeAsString(json);
    } on Exception catch (e) {
      _logger.warning("Failed to save config to cache: $e");
    }
  }
}
