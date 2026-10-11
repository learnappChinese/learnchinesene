import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Centralized Text-To-Speech (TTS) Service for the application.
///
/// Ensures single audio focus, uniform language configuration (zh-CN),
/// sequenced speech playback, and safe exception handling across all screens.
class TtsService {
  TtsService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  bool _isConfigured = false;

  /// Lazily configure the TTS engine.
  Future<void> _ensureConfigured({
    String language = 'zh-CN',
    double speechRate = 0.5,
  }) async {
    if (_isConfigured) return;
    try {
      await _tts.setLanguage(language);
      await _tts.setSpeechRate(speechRate);
      _isConfigured = true;
    } catch (e) {
      debugPrint('TtsService configuration warning: $e');
    }
  }

  /// Speak the provided Chinese or foreign text.
  ///
  /// Automatically stops prior playback before beginning.
  Future<void> speak(
    String text, {
    String language = 'zh-CN',
    double? speechRate,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    try {
      await _ensureConfigured(language: language);
      if (speechRate != null) {
        await _tts.setSpeechRate(speechRate);
      }
      await _tts.stop();
      await _tts.speak(trimmed);
    } catch (e) {
      debugPrint('TtsService speak warning: $e');
    }
  }

  /// Stop any active speech playback.
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('TtsService stop warning: $e');
    }
  }
}
