import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flash_learn_chinese/core/services/tts_service.dart';

class MockFlutterTts extends FlutterTts {
  String? spokenText;
  String? setLang;
  double? setRate;
  bool wasStopped = false;

  @override
  Future<dynamic> setLanguage(String language) async {
    setLang = language;
    return 1;
  }

  @override
  Future<dynamic> setSpeechRate(double rate) async {
    setRate = rate;
    return 1;
  }

  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    spokenText = text;
    return 1;
  }

  @override
  Future<dynamic> stop() async {
    wasStopped = true;
    return 1;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TtsService', () {
    test('does not speak on empty or whitespace string', () async {
      final mockTts = MockFlutterTts();
      final service = TtsService(tts: mockTts);

      await service.speak('');
      expect(mockTts.spokenText, isNull);

      await service.speak('   ');
      expect(mockTts.spokenText, isNull);
    });

    test('configures language and speech rate and speaks trimmed text',
        () async {
      final mockTts = MockFlutterTts();
      final service = TtsService(tts: mockTts);

      await service.speak('  你好  ', speechRate: 0.75);

      expect(mockTts.setLang, equals('zh-CN'));
      expect(mockTts.setRate, equals(0.75));
      expect(mockTts.spokenText, equals('你好'));
      expect(mockTts.wasStopped, isTrue);
    });

    test('stops playback when stop is called', () async {
      final mockTts = MockFlutterTts();
      final service = TtsService(tts: mockTts);

      await service.stop();
      expect(mockTts.wasStopped, isTrue);
    });
  });
}
