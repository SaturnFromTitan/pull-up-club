import "package:audioplayers/audioplayers.dart";
import "package:logging/logging.dart";

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _player = AudioPlayer();
  static final Logger _logger = Logger("SoundService");

  Future<void> _playSound(final String fileName) async {
    try {
      await _player.play(AssetSource("sounds/$fileName"));
    } on Exception catch (e) {
      _logger.severe("Error while playing '$fileName': $e");
    }
  }

  Future<void> playCountdown() async {
    await _playSound("beep-countdown.wav");
  }

  Future<void> playCountdownCompleted() async {
    await _playSound("beep-countdown-completed.wav");
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } on Exception catch (e) {
      _logger.severe("Error while stopping all sounds: $e");
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
