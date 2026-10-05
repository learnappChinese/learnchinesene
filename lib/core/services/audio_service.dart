import 'package:audioplayers/audioplayers.dart';

class AudioService {
  AudioService() : _player = AudioPlayer();

  final AudioPlayer _player;

  Future<void> playUrl(String url) async {
    if (url.trim().isEmpty) {
      throw Exception('Từ này chưa có âm thanh.');
    }

    try {
      await _player.stop();
      await _player.play(UrlSource(url));
    } catch (_) {
      throw Exception('Không thể phát âm thanh. Vui lòng thử lại.');
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
