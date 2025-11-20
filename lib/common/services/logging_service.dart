import "dart:async";
import "dart:convert";
import "dart:io";

import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";

/// Service for managing application logs with file-based logging.
/// Logs are written to a file for developer debugging and to support Sentry error reporting.
class LoggingService {
  LoggingService._();
  static final LoggingService instance = LoggingService._();
  static final Logger _logger = Logger("LoggingService");

  static const String _logFileName = "app_logs.jsonl"; // JSON Lines format
  static const int _maxLogFileSize = 1024 * 1024; // 1MB
  static const int _maxLogLines = 1000;

  File? _logFile;
  final List<String> _logBuffer = [];
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      _logFile = File("${directory.path}/$_logFileName");

      // Rotate log file if it's too large
      if (_logFile!.existsSync()) {
        final fileSize = await _logFile!.length();
        if (fileSize > _maxLogFileSize) {
          await _rotateLogFile();
        }
      }

      // Configure logger to handle both file logging and console output
      Logger.root.onRecord.listen(_handleLogRecord);

      _isInitialized = true;
      _logger.info("LoggingService initialized");
    } on Exception catch (e) {
      // Use Logger instead of debugPrint for consistency
      _logger.severe("Failed to initialize LoggingService", e);
    }
  }

  void _handleLogRecord(final LogRecord record) {
    // Console output (development only)
    if (kDebugMode) {
      debugPrint(
        "${record.time.toUtc().toIso8601String()} ${record.level.name} ${record.loggerName}: ${record.message}",
      );
    }

    // Write to file
    _writeLogToFile(record);
  }

  /// Write a log record to the file
  void _writeLogToFile(final LogRecord record) {
    if (_logFile == null) {
      return;
    }

    final logLine = _formatLogLine(record);
    _logBuffer.add(logLine);

    // Keep buffer size manageable
    if (_logBuffer.length > _maxLogLines) {
      _logBuffer.removeAt(0);
    }

    // Write to file asynchronously
    unawaited(
      _logFile!.writeAsString("$logLine\n", mode: FileMode.append, flush: true),
    );
  }

  String _formatLogLine(final LogRecord record) {
    final logEntry = <String, dynamic>{
      "timestamp": record.time.toUtc().toIso8601String(),
      "level": record.level.name,
      "logger": record.loggerName,
      "message": record.message,
    };

    if (record.error != null) {
      logEntry["error"] = record.error.toString();
    }

    if (record.stackTrace != null) {
      logEntry["stackTrace"] = record.stackTrace.toString();
    }

    return jsonEncode(logEntry);
  }

  /// Rotate the log file by keeping only recent entries
  Future<void> _rotateLogFile() async {
    if (_logFile == null || !_logFile!.existsSync()) {
      return;
    }

    try {
      final lines = await _logFile!.readAsLines();
      // Keep only the last 500 lines
      final recentLines = lines.length > 500
          ? lines.sublist(lines.length - 500)
          : lines;
      await _logFile!.writeAsString(recentLines.join("\n"));
    } on Exception catch (e) {
      _logger.warning("Failed to rotate log file", e);
    }
  }

  /// Get the path to the log file for debugging purposes
  /// This is primarily for developer use (e.g., retrieving logs via Xcode/Finder)
  Future<String?> getLogFilePath() async {
    if (_logFile == null) {
      await initialize();
    }

    if (_logFile == null || !_logFile!.existsSync()) {
      return null;
    }

    return _logFile!.path;
  }

  /// Clear all logs
  Future<void> clearLogs() async {
    if (_logFile == null) {
      await initialize();
    }

    try {
      if (_logFile!.existsSync()) {
        await _logFile!.delete();
      }
      _logBuffer.clear();
      _logger.info("Logs cleared");
    } on Exception catch (e) {
      _logger.warning("Failed to clear logs", e);
    }
  }
}
