import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:pull_up_club/common/constants/app_constants.dart";

/// Service for managing app package information.
/// Loads version and build number once at app startup and provides cached access.
class PackageInfoService {
  PackageInfoService._();
  static final PackageInfoService instance = PackageInfoService._();
  static final Logger _logger = Logger("PackageInfoService");

  static const String _defaultBuildNumber = "0";
  static PackageInfo _getDefaultPackageInfo({required final String version}) =>
      PackageInfo(
        packageName: AppConstants.defaultPackageName,
        appName: AppConstants.appTitle,
        version: version,
        buildNumber: _defaultBuildNumber,
      );
  bool _initialized = false;

  PackageInfo _packageInfo = _getDefaultPackageInfo(version: "unknown");
  PackageInfo get packageInfo => _packageInfo;

  String get versionString {
    final sb = StringBuffer()
      ..write("${packageInfo.packageName}@${packageInfo.version}");
    if (packageInfo.buildNumber.isNotEmpty &&
        packageInfo.buildNumber != _defaultBuildNumber) {
      sb.write("+${packageInfo.buildNumber}");
    }
    return sb.toString();
  }

  /// Initializes the service by loading package information.
  /// Should be called once during app startup.
  Future<void> initialize() async {
    if (_initialized) {
      _logger.warning("PackageInfoService already initialized");
      return;
    }
    if (kDebugMode) {
      _packageInfo = _getDefaultPackageInfo(version: "debug");
    } else {
      try {
        _packageInfo = await PackageInfo.fromPlatform();
        _logger.info(
          "PackageInfoService initialized: packageName=${_packageInfo.packageName}, version=${_packageInfo.version}, build=${_packageInfo.buildNumber}",
        );
      } on Exception catch (error, stackTrace) {
        _logger.severe("Failed to initialize PackageInfoService", error, stackTrace);
      }
    }
    _initialized = true;
  }
}
