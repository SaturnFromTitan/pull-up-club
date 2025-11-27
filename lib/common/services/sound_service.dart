import "package:audioplayers/audioplayers.dart";
import "package:logging/logging.dart";

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _player = AudioPlayer();
  static final Logger _logger = Logger("SoundService");

  Future<void> _playSound(final String fileName) async {
    _logger.fine("Playing sound: $fileName");
    try {
      await _player.play(AssetSource("sounds/$fileName"));
      _logger.fine("Completed sound successfully: $fileName");
    } on Exception catch (e, stackTrace) {
      _logger.severe("Error while playing '$fileName'", e, stackTrace);
    }
  }

  Future<void> playCountdown() async {
    await _playSound("beep-countdown.wav");
  }

  Future<void> playCountdownCompleted() async {
    await _playSound("beep-countdown-completed.wav");
  }

  Future<void> playTriumphant() async {
    await _playSound("triumphant.wav");
  }

  Future<void> stop() async {
    _logger.fine("Stopping all sounds");
    try {
      await _player.stop();
      _logger.fine("All sounds stopped successfully");
    } on Exception catch (e, stackTrace) {
      _logger.severe("Error while stopping all sounds", e, stackTrace);
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
