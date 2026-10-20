import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechResult {
  final bool isAvailable;
  final String recognizedText;
  final double score;
  final bool isCorrect;
  final double? pronunciationScore;
  final double? toneScore;
  final double? fluencyScore;

  const SpeechResult({
    required this.isAvailable,
    required this.recognizedText,
    required this.score,
    required this.isCorrect,
    this.pronunciationScore,
    this.toneScore,
    this.fluencyScore,
  });
}

/// Kết quả phân tích đối chiếu chi tiết giữa câu nói người dùng và câu mục tiêu
class SpeechMatchAnalysis {
  final String rawTarget;
  final String rawRecognized;
  final String normalizedTarget;
  final String normalizedRecognized;
  final double similarity;
  final bool isExactMatch;
  final bool isFullMatch;
  final bool isPartialMatch;
  final bool isPassed;

  const SpeechMatchAnalysis({
    required this.rawTarget,
    required this.rawRecognized,
    required this.normalizedTarget,
    required this.normalizedRecognized,
    required this.similarity,
    required this.isExactMatch,
    required this.isFullMatch,
    required this.isPartialMatch,
    required this.isPassed,
  });
}

class SpeechService {
  final SpeechToText _speech = SpeechToText();

  static final RegExp _punctuationAndWhitespaceRegex = RegExp(
    r'[\s\p{P}\p{S}\.,!?;:"' "'" r'\(\)\[\]{}<>《》〈〉「」『』【】〔〕—–…·~`@#$%^&*+=|\\/]+',
    unicode: true,
  );

  /// Chuẩn hoá chuỗi tiếng Trung: loại bỏ toàn bộ khoảng trắng và dấu câu
  static String normalizeChinese(String input) {
    return input.replaceAll(_punctuationAndWhitespaceRegex, '').trim();
  }

  bool get isListening => _speech.isListening;
  bool get isAvailable => _speech.isAvailable;

  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  }) async {
    try {
      return await _speech.initialize(
        onStatus: onStatus,
        onError: onError != null ? (e) => onError(e.errorMsg) : null,
      );
    } on PlatformException catch (e) {
      debugPrint('SpeechService initialize PlatformException: ${e.code} - ${e.message}');
      onError?.call(e.message ?? e.code);
      return false;
    } catch (e) {
      debugPrint('SpeechService initialize unexpected error: $e');
      onError?.call(e.toString());
      return false;
    }
  }

  Future<void> stop() async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (_) {}
  }

  Future<void> cancel() async {
    try {
      if (_speech.isListening) {
        await _speech.cancel();
      }
    } catch (_) {}
  }

  /// Khởi chạy nhận diện giọng nói dạng stream theo thời gian thực (real-time).
  /// Nhận partial results liên tục mà không bắt người dùng phải đợi timeout cố định.
  Future<bool> startListeningStream({
    required void Function(String recognizedWords, bool isFinal) onResult,
    void Function(String status)? onStatus,
    void Function(String error)? onError,
    String localeId = 'zh_CN',
    Duration listenFor = const Duration(seconds: 45),
    Duration pauseFor = const Duration(seconds: 5),
    String? targetText,
  }) async {
    bool ok = false;
    try {
      ok = await initialize(
        onStatus: onStatus,
        onError: onError,
      );
    } catch (e) {
      ok = false;
    }

    if (!ok) {
      // Dự phòng cho môi trường kiểm thử (test unit) hoặc thiết bị thiếu speech service
      if (targetText != null) {
        final fallback = await listenAndScore(
          targetText: targetText,
          localeId: localeId,
        );
        if (fallback.isAvailable) {
          onResult(fallback.recognizedText, true);
          return true;
        }
      }
      return false;
    }

    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          onResult(result.recognizedWords, result.finalResult);
        },
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          listenFor: listenFor,
          pauseFor: pauseFor,
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.confirmation,
        ),
      );
      return true;
    } catch (_) {
      try {
        await _speech.listen(
          onResult: (SpeechRecognitionResult result) {
            onResult(result.recognizedWords, result.finalResult);
          },
          listenOptions: SpeechListenOptions(
            localeId: 'zh-CN',
            listenFor: listenFor,
            pauseFor: pauseFor,
            partialResults: true,
            cancelOnError: false,
            listenMode: ListenMode.confirmation,
          ),
        );
        return true;
      } catch (e) {
        onError?.call(e.toString());
        return false;
      }
    }
  }

  /// Phân tích đối chiếu câu mục tiêu và câu nhận diện thời gian thực.
  SpeechMatchAnalysis analyzeMatch(String targetText, String recognizedText) {
    final normTarget = normalizeChinese(targetText);
    final normRec = normalizeChinese(recognizedText);

    if (normTarget.isEmpty && normRec.isEmpty) {
      return const SpeechMatchAnalysis(
        rawTarget: '',
        rawRecognized: '',
        normalizedTarget: '',
        normalizedRecognized: '',
        similarity: 100.0,
        isExactMatch: true,
        isFullMatch: true,
        isPartialMatch: false,
        isPassed: true,
      );
    }

    if (normRec.isEmpty) {
      return SpeechMatchAnalysis(
        rawTarget: targetText,
        rawRecognized: recognizedText,
        normalizedTarget: normTarget,
        normalizedRecognized: '',
        similarity: 0.0,
        isExactMatch: false,
        isFullMatch: false,
        isPartialMatch: false,
        isPassed: false,
      );
    }

    final isExact = normTarget == normRec;
    final similarity = similarityScore(targetText, recognizedText);

    // Khớp đủ: chính xác 100% hoặc nhận dạng chứa trọn câu mục tiêu với độ tương đồng cao
    final containsTarget =
        normRec.contains(normTarget) || normRec.endsWith(normTarget);
    final isFull = isExact || (containsTarget && similarity >= 80.0);

    // Khớp một phần: người dùng đang nói dở phần đầu của câu
    final isPartial =
        normTarget.startsWith(normRec) && normRec.length < normTarget.length;

    final isPassed = isExact || isFull || similarity >= 80.0;

    return SpeechMatchAnalysis(
      rawTarget: targetText,
      rawRecognized: recognizedText,
      normalizedTarget: normTarget,
      normalizedRecognized: normRec,
      similarity: isExact ? 100.0 : similarity,
      isExactMatch: isExact,
      isFullMatch: isFull,
      isPartialMatch: isPartial,
      isPassed: isPassed,
    );
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
    final e = normalizeChinese(expected);
    final a = normalizeChinese(actual);

    if (e.isEmpty && a.isEmpty) return 100;
    if (e.isEmpty || a.isEmpty) return 0;

    final distance = _levenshtein(e, a);
    final maxLength = math.max(e.length, a.length);
    final similarity = (1 - (distance / maxLength)) * 100;
    return similarity.clamp(0, 100).toDouble();
  }

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
