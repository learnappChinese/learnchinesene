import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/learning/model/learning_result.dart';
import '../../../core/learning/service/learning_reward_service.dart';
import '../../../core/models/speaking_practice_item.dart';
import '../../../core/services/speech_service.dart';
import '../../../core/services/vocabulary_service.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/helper/permission_helper.dart';
import '../../home/controller/home_controller.dart';

class SpeakingController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final speech = SpeechService();
  final vocabService = VocabularyService();
  final audioService = AudioService();

  int? wordId;
  int? exampleId;
  int? unitId;
  bool random = false;
  bool isBottomSheet = false;

  final items = <SpeakingPracticeItem>[].obs;
  final currentIndex = 0.obs;
  final isLoading = true.obs;
  final errorMessage = RxnString();

  final busy = false.obs;
  final recognized = ''.obs;
  final score = 0.0.obs;
  final correct = RxnBool();
  final learningResult = Rxn<LearningResult>();
  final LearningRewardService _rewardService = LearningRewardService();
  String? _activeAttemptId;

  late final AnimationController pulse;

  SpeakingController({
    int? wordId,
    int? exampleId,
    int? unitId,
    bool random = false,
    bool isBottomSheet = false,
  }) {
    final args = Get.arguments as Map<String, dynamic>?;
    this.wordId = wordId ?? args?['wordId'];
    this.exampleId = exampleId ?? args?['exampleId'];
    this.unitId = unitId ?? args?['unitId'];
    this.random = args?['random'] ?? args?['standalone'] ?? random;
    this.isBottomSheet = args?['isBottomSheet'] ?? isBottomSheet;
  }

  @override
  void onInit() {
    super.onInit();
    pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: .92,
      upperBound: 1.08,
    );
    loadData();
  }

  @override
  void onClose() {
    if (_activeAttemptId != null) {
      unawaited(
        _rewardService.abandonAttempt(
          _activeAttemptId!,
          metadata: const <String, dynamic>{'reason': 'speaking_closed'},
        ),
      );
    }
    pulse.dispose();
    speech.stop();
    audioService.dispose();
    super.onClose();
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;
      List<SpeakingPracticeItem> loaded = [];

      bool isRandom = random;
      int? wId = wordId;
      int? eId = exampleId;
      int? uId = unitId;

      if (wId == null && eId == null && uId == null && !isRandom) {
        isRandom = true;
      }

      if (wId != null) {
        final item = await vocabService.getSpeakingItemByWordId(wId);
        if (item != null) loaded.add(item);
      } else if (eId != null) {
        final item = await vocabService.getSpeakingItemByExampleId(eId);
        if (item != null) loaded.add(item);
      } else if (uId != null) {
        loaded = await vocabService.getSpeakingItemsByUnitId(uId);
      } else if (isRandom) {
        loaded = await vocabService.getRandomSpeakingItems();
      }

      if (isClosed) return;
      items.value = loaded;
      if (items.isEmpty) {
        errorMessage.value = 'Không có dữ liệu luyện tập.';
      }
      isLoading.value = false;
    } catch (e) {
      if (isClosed) return;
      isLoading.value = false;
      errorMessage.value = 'Lỗi tải dữ liệu: $e';
    }
  }

  Future<void> start(BuildContext context) async {
    if (isClosed || items.isEmpty || busy.value) return;

    final granted = await PermissionHelper.requestSpeakingPermissions();
    if (isClosed) return;
    if (!granted) {
      Get.snackbar(
        'Yêu cầu quyền truy cập',
        'Vui lòng cấp quyền micro và nhận diện giọng nói.',
        mainButton: TextButton(
          onPressed: () => PermissionHelper.openSettings(),
          child: const Text('Cài đặt'),
        ),
      );
      return;
    }

    if (isClosed) return;
    final currentItem = items[currentIndex.value];
    final sourceId =
        'spk_${currentItem.wordId ?? currentItem.exampleId ?? currentIndex.value}';
    final attemptId = 'spk_${DateTime.now().microsecondsSinceEpoch}';
    final startedAt = DateTime.now();
    _activeAttemptId = attemptId;

    await _rewardService.startSpeakingAttempt(
      sourceId: sourceId,
      attemptId: attemptId,
      wordId: currentItem.wordId,
      exampleId: currentItem.exampleId,
      targetText: currentItem.targetText,
      unitId: unitId?.toString(),
    );

    busy.value = true;
    recognized.value = '';
    correct.value = null;
    pulse.repeat(reverse: true);

    final result = await speech.listenAndScore(
      targetText: currentItem.targetText,
    );

    if (isClosed) return;
    pulse.stop();
    pulse.value = 1;

    if (!result.isAvailable) {
      await _rewardService.abandonAttempt(
        attemptId,
        metadata: const <String, dynamic>{'reason': 'speech_unavailable'},
      );
      _activeAttemptId = null;
      busy.value = false;
      return;
    }

    try {
      final reward = await _rewardService.processSpeakingReward(
        sourceId: sourceId,
        attemptId: attemptId,
        accuracyScore: result.score,
        pronunciationScore: result.pronunciationScore,
        toneScore: result.toneScore,
        fluencyScore: result.fluencyScore,
        recognizedText: result.recognizedText,
        wordId: currentItem.wordId,
        exampleId: currentItem.exampleId,
        targetText: currentItem.targetText,
        unitId: unitId?.toString(),
        durationSeconds: DateTime.now().difference(startedAt).inSeconds,
      );
      learningResult.value = reward;
      _activeAttemptId = null;

      if (Get.isRegistered<HomeController>()) {
        await Get.find<HomeController>().refreshStats();
      }
    } catch (error) {
      if (!isClosed) {
        errorMessage.value = 'Không thể lưu kết quả phát âm: $error';
      }
    }

    if (isClosed) return;
    busy.value = false;
    recognized.value = result.recognizedText;
    score.value = learningResult.value?.score ?? result.score;
    correct.value = learningResult.value?.passed ?? false;
  }

  void nextItem(BuildContext context) {
    if (isClosed) return;
    if (currentIndex.value < items.length - 1) {
      currentIndex.value++;
      recognized.value = '';
      correct.value = null;
    } else {
      if (!isBottomSheet) {
        Get.snackbar('Hoàn thành', 'Đã hoàn thành bài luyện tập!');
      }
      Get.back();
    }
  }
}
