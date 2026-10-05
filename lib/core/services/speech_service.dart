import 'dart:math' as math;

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechResult {
  final bool isAvailable;
  final String recognizedText;
  final double score;
  final bool isCorrect;

  const SpeechResult({
    required this.isAvailable,
    required this.recognizedText,
    required this.score,
    required this.isCorrect,
  });
}

class SpeechService {
  final SpeechToText _speech = SpeechToText();

  Future<bool> initialize() async {
    return _speech.initialize();
  }

  Future<void> stop() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<SpeechResult> listenAndScore({
    required String targetText,
    String localeId = 'zh_CN',
    Duration listenFor = const Duration(seconds: 8),
  }) async {
    String recognized = '';

    final ok = await initialize();
    if (!ok) {
      return const SpeechResult(
        isAvailable: false,
        recognizedText: '',
        score: 0,
        isCorrect: false,
      );
    }

    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          recognized = result.recognizedWords;
        },
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          listenFor: listenFor,
        ),
      );
    } catch (_) {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          recognized = result.recognizedWords;
        },
        listenOptions: SpeechListenOptions(
          localeId: 'zh-CN',
          listenFor: listenFor,
        ),
      );
    }

    await Future<void>.delayed(listenFor);
    await stop();

    final score = similarityScore(targetText, recognized);
    return SpeechResult(
      isAvailable: true,
      recognizedText: recognized,
      score: score,
      isCorrect: score >= 80,
    );
  }

  double similarityScore(String expected, String actual) {
    final e = _normalize(expected);
    final a = _normalize(actual);

    if (e.isEmpty && a.isEmpty) return 100;
    if (e.isEmpty || a.isEmpty) return 0;

    final distance = _levenshtein(e, a);
    final maxLength = math.max(e.length, a.length);
    final similarity = (1 - (distance / maxLength)) * 100;
    return similarity.clamp(0, 100).toDouble();
  }

  String _normalize(String input) => input.replaceAll(' ', '').trim();

  int _levenshtein(String s, String t) {
    final rows = s.length + 1;
    final cols = t.length + 1;
    final matrix = List.generate(rows, (_) => List<int>.filled(cols, 0));

    for (int i = 0; i < rows; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j < cols; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i < rows; i++) {
      for (int j = 1; j < cols; j++) {
        final cost = s[i - 1] == t[j - 1] ? 0 : 1;
        matrix[i][j] = math.min(
          math.min(matrix[i - 1][j] + 1, matrix[i][j - 1] + 1),
          matrix[i - 1][j - 1] + cost,
        );
      }
    }

    return matrix[s.length][t.length];
  }
}
