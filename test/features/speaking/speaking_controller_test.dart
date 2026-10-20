import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pandarin/core/learning/model/learning_result.dart';
import 'package:pandarin/core/learning/service/learning_reward_service.dart';
import 'package:pandarin/core/models/speaking_practice_item.dart';
import 'package:pandarin/core/services/audio_service.dart';
import 'package:pandarin/core/services/speech_service.dart';
import 'package:pandarin/features/speaking/controller/speaking_controller.dart';

/// Mock stream-enabled SpeechService for unit & logic testing
class MockStreamingSpeechService extends SpeechService {
  void Function(String words, bool isFinal)? onResultCallback;
  void Function(String status)? onStatusCallback;
  void Function(String error)? onErrorCallback;

  bool isListeningActive = false;
  int startListeningCallCount = 0;
  int stopCallCount = 0;

  @override
  bool get isListening => isListeningActive;

  @override
  Future<bool> startListeningStream({
    required void Function(String words, bool isFinal) onResult,
    void Function(String status)? onStatus,
    void Function(String error)? onError,
    String localeId = 'zh_CN',
    Duration listenFor = const Duration(seconds: 45),
    Duration pauseFor = const Duration(seconds: 5),
    String? targetText,
  }) async {
    startListeningCallCount++;
    isListeningActive = true;
    onResultCallback = onResult;
    onStatusCallback = onStatus;
    onErrorCallback = onError;
    return true;
  }

  @override
  Future<void> stop() async {
    stopCallCount++;
    isListeningActive = false;
  }

  void simulateWordArrived(String words, {bool isFinal = false}) {
    onResultCallback?.call(words, isFinal);
  }

  void simulateStatus(String status) {
    onStatusCallback?.call(status);
  }

  void simulateError(String error) {
    onErrorCallback?.call(error);
  }
}

class FakeRewardService extends LearningRewardService {
  int startAttempts = 0;
  int abandonAttempts = 0;
  int processRewards = 0;
  double? lastAccuracyScore;
  String? lastRecognizedText;
  String? lastAbandonedReason;

  @override
  Future<void> startSpeakingAttempt({
    required String sourceId,
    required String attemptId,
    int? wordId,
    int? exampleId,
    String? targetText,
    String? unitId,
    String? levelId,
  }) async {
    startAttempts++;
  }

  @override
  Future<void> abandonAttempt(String attemptId,
      {Map<String, dynamic> metadata = const {}}) async {
    abandonAttempts++;
    lastAbandonedReason = metadata['reason'] as String?;
  }

  @override
  Future<LearningResult> processSpeakingReward({
    required String sourceId,
    required String attemptId,
    required double accuracyScore,
    required double? pronunciationScore,
    required double? toneScore,
    required double? fluencyScore,
    String? recognizedText,
    int? wordId,
    int? exampleId,
    String? targetText,
    String? unitId,
    String? levelId,
    int durationSeconds = 0,
  }) async {
    processRewards++;
    lastAccuracyScore = accuracyScore;
    lastRecognizedText = recognizedText;
    final passed = accuracyScore >= 80.0;
    return LearningResult(
      activityType: 'speaking',
      sourceId: sourceId,
      attemptId: attemptId,
      passed: passed,
      stars: passed ? 3 : 1,
      score: accuracyScore,
      accuracy: accuracyScore / 100,
      correctCount: passed ? 1 : 0,
      wrongCount: passed ? 0 : 1,
      xpEarned: passed ? 15 : 0,
      baseXp: 15,
      bonusXp: 0,
      newTotalXp: 15,
      currentStreak: 1,
      firstClear: false,
      perfect: passed,
    );
  }
}

class FakeAudioService extends AudioService {
  int stopCalls = 0;
  @override
  Future<void> stop() async {
    stopCalls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Chinese Text Normalization & Speech Matching Logic', () {
    final speechService = SpeechService();

    test('1. Normalization removes punctuation, symbols and whitespace', () {
      expect(SpeechService.normalizeChinese('衣帽间'), equals('衣帽间'));
      expect(SpeechService.normalizeChinese('  衣帽间  '), equals('衣帽间'));
      expect(SpeechService.normalizeChinese('衣帽间。'), equals('衣帽间'));
      expect(SpeechService.normalizeChinese('我今天想学习中文。'), equals('我今天想学习中文'));
      expect(SpeechService.normalizeChinese('我 今天 想 学习 中文！'), equals('我今天想学习中文'));
      expect(SpeechService.normalizeChinese('你、好；吗？'), equals('你好吗'));
    });

    test('2. Exact match returns 100% similarity and isExactMatch=true', () {
      final analysis = speechService.analyzeMatch('衣帽间', '衣帽间');
      expect(analysis.isExactMatch, isTrue);
      expect(analysis.isFullMatch, isTrue);
      expect(analysis.isPassed, isTrue);
      expect(analysis.similarity, equals(100.0));
    });

    test('3. Exact match with trailing punctuation returns 100% similarity', () {
      final analysis = speechService.analyzeMatch('衣帽间', '衣帽间。');
      expect(analysis.isExactMatch, isTrue);
      expect(analysis.isFullMatch, isTrue);
      expect(analysis.isPassed, isTrue);
      expect(analysis.similarity, equals(100.0));
    });

    test('4. Partial match recognizes user in the middle of saying phrase', () {
      final analysis = speechService.analyzeMatch('我今天想学习中文', '我今天想');
      expect(analysis.isExactMatch, isFalse);
      expect(analysis.isFullMatch, isFalse);
      expect(analysis.isPartialMatch, isTrue);
      expect(analysis.isPassed, isFalse);
      expect(analysis.similarity, lessThan(80.0));
    });

    test('5. Wrong word returns low similarity and isPassed=false', () {
      final analysis = speechService.analyzeMatch('你好', '再见');
      expect(analysis.isExactMatch, isFalse);
      expect(analysis.isFullMatch, isFalse);
      expect(analysis.isPassed, isFalse);
      expect(analysis.similarity, lessThan(50.0));
    });
  });

  group('SpeakingController State Machine & Mic Operations', () {
    late MockStreamingSpeechService mockSpeech;
    late FakeRewardService mockReward;
    late FakeAudioService mockAudio;
    late SpeakingController controller;

    setUp(() {
      Get.reset();
      mockSpeech = MockStreamingSpeechService();
      mockReward = FakeRewardService();
      mockAudio = FakeAudioService();

      controller = SpeakingController(
        speechService: mockSpeech,
        rewardService: mockReward,
        audioService: mockAudio,
        permissionChecker: () async => true,
      );

      controller.items.assignAll([
        const SpeakingPracticeItem(
          wordId: 1,
          targetText: '衣帽间',
          pinyin: 'yī mào jiān',
          meaning: 'Phòng giữ đồ',
        ),
      ]);
      controller.onInit();
    });

    tearDown(() {
      controller.onClose();
    });

    test('1. Initial state is IDLE with mic icon and friendly message', () {
      expect(controller.uiState.value, equals(SpeakingUiState.idle));
      expect(controller.micIcon, equals(Icons.mic_rounded));
      expect(controller.statusMessage, equals('Chạm micro để bắt đầu'));
      expect(controller.busy.value, isFalse);
    });

    test('2. First Tap: IDLE -> INITIALIZING -> LISTENING with Stop Icon', () async {
      await controller.startListening();

      expect(controller.uiState.value, equals(SpeakingUiState.listening));
      expect(controller.micIcon, equals(Icons.stop_rounded));
      expect(controller.statusMessage, equals('Đang nghe... chạm để dừng'));
      expect(controller.busy.value, isTrue);
      expect(mockSpeech.startListeningCallCount, equals(1));
      expect(mockAudio.stopCalls, equals(1));
      expect(mockReward.startAttempts, equals(1));
    });

    test('3. Tap 2: Stop before speaking does NOT mark as failure', () async {
      await controller.startListening();
      expect(controller.uiState.value, equals(SpeakingUiState.listening));

      // User immediately taps stop without speaking
      await controller.stopAndEvaluate();

      // Cleanly resets to IDLE without error card or punishment
      expect(controller.uiState.value, equals(SpeakingUiState.idle));
      expect(controller.micIcon, equals(Icons.mic_rounded));
      expect(controller.statusMessage, equals('Chạm micro để bắt đầu'));
      expect(controller.busy.value, isFalse);
      expect(mockReward.processRewards, equals(0)); // NOT recorded as failure
      expect(mockReward.abandonAttempts, equals(1));
      expect(mockReward.lastAbandonedReason, equals('user_cancelled_before_speech'));
    });

    test('4. Tap 2: Stop after partial speech evaluates and goes to RETRY', () async {
      await controller.startListening();

      // User says half the sentence
      mockSpeech.simulateWordArrived('衣帽');
      expect(controller.recognized.value, equals('衣帽'));

      // User taps stop to check partial speech
      await controller.stopAndEvaluate();

      expect(controller.uiState.value, equals(SpeakingUiState.retry));
      expect(controller.micIcon, equals(Icons.mic_rounded));
      expect(controller.statusMessage, equals('Chưa chính xác, hãy thử lại'));
      expect(controller.busy.value, isFalse);
      expect(controller.correct.value, isFalse);
      expect(controller.recognized.value, equals('衣帽'));
      expect(mockReward.processRewards, equals(1));
    });

    test('5. Auto-completion: Full sentence spoken automatically completes and transitions to SUCCESS', () async {
      await controller.startListening();

      // User speaks step 1: 衣
      mockSpeech.simulateWordArrived('衣');
      expect(controller.uiState.value, equals(SpeakingUiState.listening));

      // User speaks step 2: 衣帽
      mockSpeech.simulateWordArrived('衣帽');
      expect(controller.uiState.value, equals(SpeakingUiState.listening));

      // User speaks step 3: 衣帽间 (Full match!)
      mockSpeech.simulateWordArrived('衣帽间');
      expect(controller.recognized.value, equals('衣帽间'));

      // Wait 700ms for the debounce timer to stabilize and auto-complete
      await Future<void>.delayed(const Duration(milliseconds: 700));

      expect(controller.uiState.value, equals(SpeakingUiState.success));
      expect(controller.micIcon, equals(Icons.mic_rounded));
      expect(controller.statusMessage, equals('Chính xác! Tuyệt vời!'));
      expect(controller.busy.value, isFalse);
      expect(controller.correct.value, isTrue);
      expect(controller.score.value, equals(100.0));
      expect(mockReward.processRewards, equals(1));
    });

    test('6. Silence Detection: 2.5s pause after partial speech evaluates to RETRY', () async {
      await controller.startListening();

      // User speaks partial phrase
      mockSpeech.simulateWordArrived('衣');

      // Wait 2500ms silence
      await Future<void>.delayed(const Duration(milliseconds: 2600));

      expect(controller.uiState.value, equals(SpeakingUiState.retry));
      expect(controller.correct.value, isFalse);
      expect(controller.recognized.value, equals('衣'));
    });

    test('7. Rapid consecutive taps do not trigger multiple concurrent speech sessions', () async {
      // Tap twice rapidly
      unawaited(controller.startListening());
      unawaited(controller.startListening());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(mockSpeech.startListeningCallCount, equals(1));
    });

    test('8. No speech detected after timeout cleanly resets to IDLE without error card', () async {
      await controller.startListening();
      expect(controller.uiState.value, equals(SpeakingUiState.listening));

      // Wait 7.6 seconds for no speech timer
      await Future<void>.delayed(const Duration(milliseconds: 7600));

      expect(controller.uiState.value, equals(SpeakingUiState.idle));
      expect(controller.micIcon, equals(Icons.mic_rounded));
      expect(controller.busy.value, isFalse);
      expect(mockReward.processRewards, equals(0)); // no penalty
      expect(mockReward.abandonAttempts, equals(1));
      expect(mockReward.lastAbandonedReason, equals('no_speech_detected'));
    });
  });

  group('SpeakingScreen Widget & UI Integrity', () {
    testWidgets('Renders microphone control with preserved UI styling and responds to taps', (tester) async {
      Get.reset();
      final mockSpeech = MockStreamingSpeechService();
      final mockReward = FakeRewardService();
      final mockAudio = FakeAudioService();

      final controller = SpeakingController(
        speechService: mockSpeech,
        rewardService: mockReward,
        audioService: mockAudio,
        permissionChecker: () async => true,
      );

      controller.items.assignAll([
        const SpeakingPracticeItem(
          wordId: 10,
          targetText: '水杯',
          pinyin: 'shuǐ bēi',
          meaning: 'Cốc nước',
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InkWell(
                onTap: () => controller.handleMicTap(tester.element(find.byType(Scaffold))),
                child: Column(
                  children: [
                    Obx(() => Icon(controller.micIcon)),
                    Obx(() => Text(controller.statusMessage)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Verify IDLE UI
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
      expect(find.text('Chạm micro để bắt đầu'), findsOneWidget);

      // Tap 1: Start listening
      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
      expect(find.text('Đang nghe... chạm để dừng'), findsOneWidget);

      // Tap 2: Stop and clean reset
      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
      expect(find.text('Chạm micro để bắt đầu'), findsOneWidget);

      controller.onClose();
    });
  });
}
