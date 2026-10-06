import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';

/// App-wide Mandarin audio service.
///
/// Prefer recorded/cloud audio when a URL exists. If playback fails or the URL
/// is absent, fall back to the device zh-CN TTS engine. A single FlutterTts
/// instance prevents repeated Android engine bind/unbind races across screens.
class TtsService extends GetxService {
  TtsService({
    FlutterTts? tts,
    AudioPlayer? player,
  })  : _tts = tts ?? FlutterTts(),
        _player = player ?? AudioPlayer();

  final FlutterTts _tts;
  final AudioPlayer _player;

  Future<bool>? _initializing;
  bool _ready = false;

  bool get isReady => _ready;

  Future<bool> ensureReady() {
    if (_ready) return Future<bool>.value(true);
    return _initializing ??= _initialize();
  }

  Future<bool> _initialize() async {
    try {
      await _tts.awaitSpeakCompletion(true);

      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          final available = await _tts.isLanguageAvailable('zh-CN');
          if (available == true) {
            await _tts.setLanguage('zh-CN');
            await _tts.setSpeechRate(0.48);
            await _tts.setPitch(1.0);
            await _tts.setVolume(1.0);
            _ready = true;
            return true;
          }
        } catch (_) {
          // Android may still be binding to its TTS engine.
        }

        await Future<void>.delayed(
          Duration(milliseconds: 220 * (attempt + 1)),
        );
      }
    } catch (_) {
      _ready = false;
    } finally {
      _initializing = null;
    }
    return false;
  }

  Future<bool> playUrlOrSpeak({
    String? url,
    required String text,
    bool slow = false,
  }) async {
    final value = text.trim();
    final audioUrl = url?.trim();

    await stop();

    if (audioUrl != null && audioUrl.isNotEmpty) {
      try {
        await _player.play(UrlSource(audioUrl));
        return true;
      } catch (_) {
        // Fall through to device TTS.
      }
    }

    return speakChinese(value, slow: slow);
  }

  Future<bool> speakChinese(
    String text, {
    bool slow = false,
  }) async {
    final value = text.trim();
    if (value.isEmpty) return false;

    final ready = await ensureReady();
    if (!ready) return false;

    try {
      await _player.stop();
      await _tts.stop();
      await _tts.setSpeechRate(slow ? 0.36 : 0.48);
      await _tts.speak(value);
      return true;
    } catch (_) {
      _ready = false;
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
  }

  @override
  void onClose() {
    unawaited(stop());
    unawaited(_player.dispose());
    super.onClose();
  }
}
