import "package:flutter/services.dart";
import "package:logging/logging.dart";

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  static const MethodChannel _channel = MethodChannel("pull_up_club/sounds");
  static final Logger _logger = Logger("SoundService");

  /// Plays a beep sound with the specified frequency and duration
  ///
  /// [frequency] - Frequency in Hz (e.g., 800 for countdown, 600 for complete)
  /// [duration] - Duration in seconds (e.g., 0.1 for countdown, 0.3 for complete)
  Future<void> _playBeep(final double frequency, final double duration) async {
    try {
      await _channel.invokeMethod("playBeep", {
        "frequency": frequency,
        "duration": duration,
      });
    } on Exception catch (e) {
      _logger.severe("Error while playing beep: $e");
    }
  }

  /// Plays countdown beep (higher pitch, shorter duration)
  /// Matches the React prototype: playBeep(800, 0.1)
  Future<void> playCountdown() async {
    await _playBeep(800, 0.1);
  }

  /// Plays completion beep (lower pitch, longer duration)
  /// Matches the React prototype: playBeep(600, 0.3)
  Future<void> playComplete() async {
    await _playBeep(600, 0.3);
  }

  /// Stops all currently playing sounds
  Future<void> stopAll() async {
    try {
      await _channel.invokeMethod("stopAll");
    } on Exception catch (e) {
      // Silently fail if stopping fails
      _logger.severe("Error while stopping all sounds: $e");
    }
  }
}
