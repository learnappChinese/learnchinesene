import 'dart:convert';
import 'package:pandarin/core/ai/model/ai_gateway_exception.dart';
import 'package:pandarin/core/services/gemini_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PR 05 — Gemini AI Gateway & Error Sanitization', () {
    test('GeminiService routes through gateway and returns structured payload',
        () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('gemini-ai-gateway'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['action'], equals('dictionary'));
        expect(body['payload']['word'], equals('你好'));

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'source_lang': 'zh',
              'target_lang': 'vi',
              'hanzi': '你好',
              'pinyin': 'nǐ hǎo',
              'vi_meaning': 'Xin chào',
              'examples': [],
              'grammar_notes': [],
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = GeminiService(client: mockClient);
      final result = await service.fetchDictionaryEntry('你好');

      expect(result['hanzi'], equals('你好'));
      expect(result['vi_meaning'], equals('Xin chào'));
    });

    test('GeminiService maps 429 quota_exceeded into typed AiGatewayException',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': 'quota_exceeded',
            'message': 'Bạn đã đạt giới hạn lượt sử dụng AI trong ngày.',
          }),
          429,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = GeminiService(client: mockClient);

      expect(
        () => service.fetchDictionaryEntry('测试'),
        throwsA(isA<AiGatewayException>().having(
          (e) => e.code,
          'code',
          equals(AiGatewayErrorCode.quotaExceeded),
        )),
      );
    });

    test('GeminiService handles server offline or network timeout gracefully',
        () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });

      final service = GeminiService(client: mockClient);

      expect(
        () => service.fetchConversation(1, null),
        throwsA(isA<AiGatewayException>().having(
          (e) => e.code,
          'code',
          equals(AiGatewayErrorCode.aiTemporarilyUnavailable),
        )),
      );
    });
  });
}
