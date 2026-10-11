import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../ai/model/ai_gateway_exception.dart';
import '../backend/supabase_config.dart';
import '../config/app_config.dart';

/// Secure Gemini Service for Flutter Client.
///
/// In accordance with PR 05 Security Standards:
/// 1. No Google Gemini API key or secret exists on the client.
/// 2. All requests are routed through Supabase Edge Function [gemini-ai-gateway].
/// 3. Rate limits, user quota, and premium entitlement checks are executed server-side.
/// 4. Structured error codes ([AiGatewayException]) allow UI to provide helpful feedback.
class GeminiService {
  GeminiService({
    SupabaseClient? supabaseClient,
    http.Client? client,
  })  : _supabase = supabaseClient,
        _client = client ?? http.Client();

  final SupabaseClient? _supabase;
  final http.Client _client;

  Uri get _gatewayUri => Uri.parse(
      '${SupabaseConfig.url}/functions/v1/${AppConfigVer1Ne.geminiGatewayFunction}');

  Future<dynamic> _invokeGateway({
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    final token = _supabase?.auth.currentSession?.accessToken ??
        SupabaseConfig.publishableKey;

    final headers = {
      'Content-Type': 'application/json',
      'apikey': SupabaseConfig.publishableKey,
      'Authorization': 'Bearer $token',
    };

    final requestBody = jsonEncode({
      'action': action,
      'payload': payload,
    });

    final http.Response response;
    try {
      response = await _client.post(
        _gatewayUri,
        headers: headers,
        body: requestBody,
      );
    } catch (e) {
      throw AiGatewayException(
        code: AiGatewayErrorCode.aiTemporarilyUnavailable,
        message: 'Không thể kết nối đến máy chủ AI gateway: $e',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('data')) {
          return decoded['data'];
        }
        return decoded;
      }
      return decoded;
    }

    final errorMessage = (decoded is Map ? decoded['message'] : null) ??
        'Lỗi AI Gateway (${response.statusCode})';
    final errorCodeStr = decoded is Map ? decoded['error']?.toString() : null;
    final errorCode = AiGatewayErrorCode.fromString(errorCodeStr);

    throw AiGatewayException(
      code: errorCode,
      message: errorMessage.toString(),
      details: decoded,
    );
  }

  List<dynamic> _convertToList(dynamic result) {
    if (result is List) {
      return result;
    }
    if (result is Map) {
      if (result.containsKey('items')) {
        return result['items'] as List<dynamic>;
      }
      return result['contents'] ?? result['list'] ?? [result];
    }
    return [result];
  }

  /// Tra cứu từ điển Việt ↔ Trung bằng Gemini Gateway
  Future<Map<String, dynamic>> fetchDictionaryEntry(String word) async {
    final result = await _invokeGateway(
      action: 'dictionary',
      payload: {'word': word},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  /// Dịch văn bản giữa tiếng Việt và tiếng Trung
  Future<Map<String, dynamic>> translate(String text) async {
    final result = await _invokeGateway(
      action: 'translate',
      payload: {'text': text},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  /// Trích xuất chữ Hán từ hình ảnh (OCR)
  Future<String> extractTextFromImage(
    String base64Image,
    String mimeType,
  ) async {
    final result = await _invokeGateway(
      action: 'ocr',
      payload: {'base64Image': base64Image, 'mimeType': mimeType},
    );
    return result?.toString() ?? '';
  }

  /// Lấy hoặc tạo đoạn hội thoại theo cấp độ HSK và chủ đề
  Future<List<dynamic>> fetchConversation(int level, String? topic) async {
    final result = await _invokeGateway(
      action: 'conversation',
      payload: {'level': level, if (topic != null) 'topic': topic},
    );
    return _convertToList(result);
  }

  /// Lấy thêm câu tiếp theo cho cuộc hội thoại
  Future<List<dynamic>> fetchMoreConversationLines(
    List<Map<String, dynamic>> existingLines,
    int level,
  ) async {
    final result = await _invokeGateway(
      action: 'conversation_continuation',
      payload: {'existingLines': existingLines, 'level': level},
    );
    return _convertToList(result);
  }

  /// Tạo danh sách bài học chủ đề cho cấp độ HSK
  Future<List<dynamic>> fetchLessonTopics(int level) async {
    final result = await _invokeGateway(
      action: 'lesson_topics',
      payload: {'level': level},
    );
    return _convertToList(result);
  }

  /// Tạo chi tiết bài học (Dialogue, Key Vocabulary, Grammar Points)
  Future<Map<String, dynamic>> fetchLessonDetail(
    int level,
    String topic,
  ) async {
    final result = await _invokeGateway(
      action: 'lesson_detail',
      payload: {'level': level, 'topic': topic},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  /// Tạo đề thi thử HSK cho cấp độ
  Future<List<dynamic>> fetchHskExam(int level) async {
    final result = await _invokeGateway(
      action: 'hsk_exam',
      payload: {'level': level},
    );
    return _convertToList(result);
  }

  /// Đánh giá kết quả làm bài thi HSK
  Future<Map<String, dynamic>> analyzeHskExamPerformance({
    required int level,
    required List<Map<String, dynamic>> questionsAndAnswers,
    required int score,
    required int totalQuestions,
  }) async {
    final result = await _invokeGateway(
      action: 'hsk_exam_analysis',
      payload: {
        'level': level,
        'questionsAndAnswers': questionsAndAnswers,
        'score': score,
        'totalQuestions': totalQuestions,
      },
    );
    return Map<String, dynamic>.from(result as Map);
  }

  /// Sinh ngẫu nhiên danh sách từ vựng HSK để phục vụ trắc nghiệm
  Future<List<dynamic>> fetchHskVocabulary(int level, {int count = 20}) async {
    final result = await _invokeGateway(
      action: 'hsk_vocabulary',
      payload: {'level': level, 'count': count},
    );
    return _convertToList(result);
  }
}
