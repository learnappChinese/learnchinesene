import 'package:audioplayers/audioplayers.dart';

class AudioService {
  AudioService({AudioPlayer? player}) : _player = player;

  AudioPlayer? _player;
  AudioPlayer _getPlayer() => _player ??= AudioPlayer();

  Future<void> playUrl(String url) async {
    if (url.trim().isEmpty) {
      throw Exception('Từ này chưa có âm thanh.');
    }

    try {
      final p = _getPlayer();
      await p.stop();
      await p.play(UrlSource(url));
    } catch (_) {
      throw Exception('Không thể phát âm thanh. Vui lòng thử lại.');
    }
  }

  Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (e) {
      // Audio stop failure logged
    }
  }

  Future<void> dispose() async {
    await _player?.dispose();
    _player = null;
  }
}
