import "package:audioplayers/audioplayers.dart";
import "package:logging/logging.dart";

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _countdownPlayer = AudioPlayer();
  final AudioPlayer _completePlayer = AudioPlayer();
  static final Logger _logger = Logger("SoundService");

  Future<void> playCountdown() async {
    try {
      await _countdownPlayer.play(AssetSource("sounds/beep-countdown.wav"));
    } on Exception catch (e) {
      _logger.severe("Error while playing countdown sound: $e");
    }
  }

  Future<void> playComplete() async {
    try {
      await _completePlayer.play(AssetSource("sounds/beep-final.wav"));
    } on Exception catch (e) {
      _logger.severe("Error while playing complete sound: $e");
    }
  }

  Future<void> stopAll() async {
    try {
      await _countdownPlayer.stop();
      await _completePlayer.stop();
    } on Exception catch (e) {
      _logger.severe("Error while stopping all sounds: $e");
    }
  }

  Future<void> dispose() async {
    await _countdownPlayer.dispose();
    await _completePlayer.dispose();
  }
}
