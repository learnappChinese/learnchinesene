import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/database/db_helper.dart';
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
      busy.value = false;
      return;
    }

    if (currentItem.wordId != null || currentItem.exampleId != null) {
      await DbHelper.instance.saveSpeakingPractice(
        wordId: currentItem.wordId ?? 0,
        exampleId: currentItem.exampleId,
        targetText: currentItem.targetText,
        recognizedText: result.recognizedText,
        score: result.score,
        isCorrect: result.isCorrect,
      );

      // Unified learning reward & streak sync
      try {
        final rewardService = LearningRewardService();
        final sid = 'spk_${currentItem.wordId ?? currentItem.exampleId ?? 0}';
        final attId = 'spk_${DateTime.now().millisecondsSinceEpoch}';
        await rewardService.processSpeakingReward(
          sourceId: sid,
          attemptId: attId,
          accuracyScore: result.score,
          pronunciationScore: result.score,
          toneScore: result.isCorrect ? result.score : (result.score * 0.8),
          fluencyScore: result.score,
          recognizedText: result.recognizedText,
        );

        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().refreshStats();
        }
      } catch (_) {}
    }

    if (currentItem.wordId != null) {
      await DbHelper.instance.upsertProgress(
        wordId: currentItem.wordId!,
        isCorrect: result.isCorrect,
      );
    }

    if (isClosed) return;
    busy.value = false;
    recognized.value = result.recognizedText;
    score.value = result.score;
    correct.value = result.isCorrect;
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
