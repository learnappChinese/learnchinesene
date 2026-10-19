import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

abstract interface class VocabularyAudioService {
  Future<void> speak(String text, {bool slow = false});
  Future<void> stop();
  void dispose();
}

class FlutterVocabularyAudioService implements VocabularyAudioService {
  FlutterVocabularyAudioService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;

  @override
  Future<void> speak(String text, {bool slow = false}) async {
    if (text.trim().isEmpty) return;
    await _tts.stop();
    await _tts.setLanguage('zh-CN');
    await _tts.setSpeechRate(slow ? .32 : .48);
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }

  @override
  void dispose() {
    unawaited(stop());
  }
}
