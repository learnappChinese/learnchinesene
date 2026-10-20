import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/learning/model/learning_result.dart';
import '../../../core/learning/model/learning_source_context.dart';
import '../../../core/learning/service/learning_reward_service.dart';
import '../../../core/models/speaking_practice_item.dart';
import '../../../core/services/speech_service.dart';
import '../../../core/services/vocabulary_service.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/helper/permission_helper.dart';

/// Các trạng thái giao diện và chu trình nhận diện giọng nói
enum SpeakingUiState {
  idle,
  initializing,
  listening,
  finalizing,
  evaluating,
  success,
  retry,
  error,
}

class SpeakingController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final SpeechService speech;
  final VocabularyService vocabService;
  final AudioService audioService;
  final Future<bool> Function() _permissionChecker;

  int? wordId;
  int? exampleId;
  int? unitId;
  bool random = false;
  bool isBottomSheet = false;
  LearningSourceContext? sourceContext;

  final items = <SpeakingPracticeItem>[].obs;
  final currentIndex = 0.obs;
  final isLoading = true.obs;
  final errorMessage = RxnString();

  final uiState = SpeakingUiState.idle.obs;
  final busy = false.obs;
  final recognized = ''.obs;
  final score = 0.0.obs;
  final correct = RxnBool();
  final learningResult = Rxn<LearningResult>();
  final LearningRewardService _rewardService;
  String? _activeAttemptId;

  // Quản lý phiên làm việc, timers và debounce
  int _sessionEpoch = 0;
  bool _hasSpoken = false;
  String _latestRecognized = '';
  DateTime? _listeningStartedAt;
  Timer? _noSpeechTimer;
  Timer? _silenceDebounceTimer;
  Timer? _fullMatchDebounceTimer;

  late final AnimationController pulse;

  bool get _hasPulse {
    try {
      return pulse.duration != null;
    } catch (_) {
      return false;
    }
  }

  /// Thông điệp phản hồi hiển thị dưới nút Micro
  String get statusMessage {
    switch (uiState.value) {
      case SpeakingUiState.idle:
        return 'Chạm micro để bắt đầu';
      case SpeakingUiState.initializing:
        return 'Đang mở micro...';
      case SpeakingUiState.listening:
        return 'Đang nghe... chạm để dừng';
      case SpeakingUiState.finalizing:
        return 'Đang hoàn tất nhận diện...';
      case SpeakingUiState.evaluating:
        return 'Đang kiểm tra...';
      case SpeakingUiState.success:
        return 'Chính xác! Tuyệt vời!';
      case SpeakingUiState.retry:
        return 'Chưa chính xác, hãy thử lại';
      case SpeakingUiState.error:
        return errorMessage.value ??
            'Lỗi micro hoặc chưa cấp quyền. Chạm để thử lại.';
    }
  }

  /// Icon trên nút Micro tròn màu xanh
  IconData get micIcon {
    switch (uiState.value) {
      case SpeakingUiState.listening:
        return Icons.stop_rounded;
      case SpeakingUiState.finalizing:
        return Icons.hourglass_top_rounded;
      case SpeakingUiState.evaluating:
        return Icons.sync_rounded;
      default:
        return Icons.mic_rounded;
    }
  }

  SpeakingController({
    int? wordId,
    int? exampleId,
    int? unitId,
    bool random = false,
    bool isBottomSheet = false,
    this.sourceContext,
    LearningRewardService? rewardService,
    SpeechService? speechService,
    VocabularyService? vocabularyService,
    AudioService? audioService,
    Future<bool> Function()? permissionChecker,
  })  : _rewardService = rewardService ?? LearningRewardService(),
        speech = speechService ?? SpeechService(),
        vocabService = vocabularyService ?? VocabularyService(),
        audioService = audioService ?? AudioService(),
        _permissionChecker =
            permissionChecker ?? PermissionHelper.requestSpeakingPermissions {
    final args = Get.arguments as Map<String, dynamic>?;
    this.wordId = wordId ?? args?['wordId'];
    this.exampleId = exampleId ?? args?['exampleId'];
    this.unitId = unitId ?? args?['unitId'];
    this.random = args?['random'] ?? args?['standalone'] ?? random;
    this.isBottomSheet = args?['isBottomSheet'] ?? isBottomSheet;
    if (args?['sourceContext'] is LearningSourceContext) {
      sourceContext = args?['sourceContext'] as LearningSourceContext;
    }
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
    _cancelAllTimers();
    _sessionEpoch++;
    if (_activeAttemptId != null) {
      unawaited(
        _rewardService.abandonAttempt(
          _activeAttemptId!,
          metadata: const <String, dynamic>{'reason': 'speaking_closed'},
        ),
      );
    }
    if (_hasPulse) pulse.dispose();
    speech.stop();
    audioService.dispose();
    super.onClose();
  }

  void _cancelAllTimers() {
    _noSpeechTimer?.cancel();
    _noSpeechTimer = null;
    _silenceDebounceTimer?.cancel();
    _silenceDebounceTimer = null;
    _fullMatchDebounceTimer?.cancel();
    _fullMatchDebounceTimer = null;
  }

  Future<void> loadData() async {
    if (items.isNotEmpty) {
      isLoading.value = false;
      return;
    }
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

  /// Xử lý chạm nút micro theo toggle:
  /// Bấm lần 1: Bắt đầu nghe.
  /// Bấm lần 2: Dừng và kiểm tra ngay.
  void handleMicTap(BuildContext context) {
    switch (uiState.value) {
      case SpeakingUiState.idle:
      case SpeakingUiState.retry:
      case SpeakingUiState.error:
      case SpeakingUiState.success:
        startListening(context);
        break;
      case SpeakingUiState.listening:
        stopAndEvaluate(context);
        break;
      case SpeakingUiState.initializing:
      case SpeakingUiState.finalizing:
      case SpeakingUiState.evaluating:
        // Đang trong chuyển đổi trạng thái tạm thời, phớt lờ thao tác gõ nhanh
        break;
    }
  }

  /// Tương thích ngược với các widget/card gọi `controller.start(context)`
  Future<void> start([BuildContext? context]) => startListening(context);

  /// Bắt đầu lượt nhận diện giọng nói
  Future<void> startListening([BuildContext? context]) async {
    if (isClosed || items.isEmpty) return;
    if (uiState.value == SpeakingUiState.initializing ||
        uiState.value == SpeakingUiState.finalizing ||
        uiState.value == SpeakingUiState.evaluating ||
        uiState.value == SpeakingUiState.listening) {
      return;
    }

    _cancelAllTimers();
    _sessionEpoch++;
    final currentEpoch = _sessionEpoch;

    uiState.value = SpeakingUiState.initializing;
    busy.value = true;
    recognized.value = '';
    _latestRecognized = '';
    _hasSpoken = false;
    correct.value = null;
    errorMessage.value = null;

    final granted = await _permissionChecker();
    if (isClosed || currentEpoch != _sessionEpoch) return;

    if (!granted) {
      uiState.value = SpeakingUiState.error;
      busy.value = false;
      errorMessage.value = 'Chưa cấp quyền truy cập micro.';
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

    // Dừng phát âm thanh mẫu nếu đang mở
    await audioService.stop();
    if (isClosed || currentEpoch != _sessionEpoch) return;

    final currentItem = items[currentIndex.value];
    final sourceId =
        'spk_${currentItem.wordId ?? currentItem.exampleId ?? currentIndex.value}';
    final attemptId = 'spk_${DateTime.now().microsecondsSinceEpoch}';
    _activeAttemptId = attemptId;
    _listeningStartedAt = DateTime.now();

    final String? rewardUnitId = (sourceContext?.isCurriculum == true)
        ? sourceContext!.duoUnitId
        : (unitId != null &&
                (sourceContext == null || !sourceContext!.isPractice)
            ? 'unit_$unitId'
            : null);
    final String? rewardLevelId =
        (sourceContext?.isCurriculum == true) ? sourceContext!.levelId : null;

    await _rewardService.startSpeakingAttempt(
      sourceId: sourceId,
      attemptId: attemptId,
      wordId: currentItem.wordId,
      exampleId: currentItem.exampleId,
      targetText: currentItem.targetText,
      unitId: rewardUnitId,
      levelId: rewardLevelId,
    );

    if (isClosed || currentEpoch != _sessionEpoch) return;

    final started = await speech.startListeningStream(
      targetText: currentItem.targetText,
      onResult: (words, isFinal) =>
          _onSpeechResult(currentEpoch, words, isFinal),
      onStatus: (status) => _onSpeechStatus(currentEpoch, status),
      onError: (err) => _onSpeechError(currentEpoch, err),
    );

    if (isClosed || currentEpoch != _sessionEpoch) return;

    if (!started) {
      if (_hasPulse) {
        pulse.stop();
        pulse.value = 1.0;
      }
      await _rewardService.abandonAttempt(
        attemptId,
        metadata: const <String, dynamic>{'reason': 'speech_unavailable'},
      );
      _activeAttemptId = null;
      busy.value = false;
      uiState.value = SpeakingUiState.error;
      errorMessage.value = errorMessage.value ?? 'Thiết bị chưa hỗ trợ nhận diện giọng nói (Google Speech Services).';
      return;
    }

    uiState.value = SpeakingUiState.listening;
    busy.value = true;
    if (_hasPulse) pulse.repeat(reverse: true);

    // Timer phát hiện người dùng hoàn toàn chưa nói gì trong 7.5 giây đầu
    _noSpeechTimer = Timer(const Duration(milliseconds: 7500), () {
      if (currentEpoch != _sessionEpoch || isClosed) return;
      if (!_hasSpoken && uiState.value == SpeakingUiState.listening) {
        _handleNoSpeechTimeout(currentEpoch);
      }
    });
  }

  /// Nhận partial results liên tục theo thời gian thực từ Speech engine
  void _onSpeechResult(int epoch, String words, bool isFinal) {
    if (epoch != _sessionEpoch || isClosed) return;
    if (uiState.value != SpeakingUiState.listening) return;

    if (words.trim().isNotEmpty) {
      _hasSpoken = true;
      _latestRecognized = words;
      recognized.value = words;
      _noSpeechTimer?.cancel();
    }

    final currentItem = items[currentIndex.value];
    final analysis = speech.analyzeMatch(currentItem.targetText, words);

    // TRƯỜNG HỢP 1: ĐÃ NÓI ĐỦ VÀ ĐÚNG CÂU MỤC TIÊU
    if (analysis.isExactMatch || analysis.isFullMatch) {
      _silenceDebounceTimer?.cancel();
      _fullMatchDebounceTimer?.cancel();

      // Đợi ổn định 600ms để tránh cắt mất âm cuối khi người dùng vẫn đang nói
      _fullMatchDebounceTimer = Timer(const Duration(milliseconds: 600), () {
        if (epoch != _sessionEpoch || isClosed) return;
        _finishAndEvaluate(epoch, autoCompleted: true);
      });
      return;
    }

    // TRƯỜNG HỢP 2: ĐANG NÓI HOẶC TẠM DỪNG GIỮA CÂU
    _fullMatchDebounceTimer?.cancel();
    _silenceDebounceTimer?.cancel();

    // Nếu im lặng 2.4 giây sau khi đã nói dở dang một phần -> kết thúc và đánh giá
    _silenceDebounceTimer = Timer(const Duration(milliseconds: 2400), () {
      if (epoch != _sessionEpoch || isClosed) return;
      _finishAndEvaluate(epoch, autoCompleted: false);
    });

    if (isFinal) {
      _finishAndEvaluate(epoch, autoCompleted: false);
    }
  }

  void _onSpeechStatus(int epoch, String status) {
    if (epoch != _sessionEpoch || isClosed) return;
    if (status == 'notListening' || status == 'done') {
      if (uiState.value == SpeakingUiState.listening) {
        if (_hasSpoken) {
          _finishAndEvaluate(epoch, autoCompleted: false);
        } else {
          _handleNoSpeechTimeout(epoch);
        }
      }
    }
  }

  void _onSpeechError(int epoch, String err) {
    if (epoch != _sessionEpoch || isClosed) return;
    if (uiState.value == SpeakingUiState.listening) {
      if (_hasSpoken) {
        _finishAndEvaluate(epoch, autoCompleted: false);
      } else {
        _handleNoSpeechTimeout(epoch);
      }
    }
  }

  /// Khi hết thời gian chờ mà người dùng hoàn toàn chưa bắt đầu nói:
  /// Đưa về IDLE, không tính là làm sai.
  Future<void> _handleNoSpeechTimeout(int epoch) async {
    if (epoch != _sessionEpoch || isClosed) return;
    _cancelAllTimers();
    await speech.stop();
    if (_hasPulse) {
      pulse.stop();
      pulse.value = 1.0;
    }
    if (_activeAttemptId != null) {
      await _rewardService.abandonAttempt(
        _activeAttemptId!,
        metadata: const <String, dynamic>{'reason': 'no_speech_detected'},
      );
      _activeAttemptId = null;
    }
    busy.value = false;
    uiState.value = SpeakingUiState.idle;
    recognized.value = '';
    correct.value = null;
  }

  /// Người dùng chủ động bấm Dừng trên nút Micro
  Future<void> stopAndEvaluate([BuildContext? context]) async {
    if (isClosed || uiState.value != SpeakingUiState.listening) return;
    final currentEpoch = _sessionEpoch;
    _cancelAllTimers();

    // Nếu bấm dừng ngay khi chưa nói gì: không tính là sai
    if (!_hasSpoken || _latestRecognized.trim().isEmpty) {
      await speech.stop();
      if (_hasPulse) {
        pulse.stop();
        pulse.value = 1.0;
      }
      if (_activeAttemptId != null) {
        await _rewardService.abandonAttempt(
          _activeAttemptId!,
          metadata: const <String, dynamic>{
            'reason': 'user_cancelled_before_speech'
          },
        );
        _activeAttemptId = null;
      }
      busy.value = false;
      uiState.value = SpeakingUiState.idle;
      recognized.value = '';
      correct.value = null;
      return;
    }

    await _finishAndEvaluate(currentEpoch, autoCompleted: false);
  }

  /// Hoàn tất nhận diện và chấm điểm câu nói
  Future<void> _finishAndEvaluate(
    int epoch, {
    required bool autoCompleted,
  }) async {
    if (epoch != _sessionEpoch || isClosed) return;
    if (uiState.value == SpeakingUiState.finalizing ||
        uiState.value == SpeakingUiState.evaluating ||
        uiState.value == SpeakingUiState.success) {
      return;
    }

    _cancelAllTimers();
    uiState.value = SpeakingUiState.finalizing;
    if (_hasPulse) {
      pulse.stop();
      pulse.value = 1.0;
    }

    await speech.stop();
    if (epoch != _sessionEpoch || isClosed) return;

    uiState.value = SpeakingUiState.evaluating;

    final currentItem = items[currentIndex.value];
    final spokenText = _latestRecognized.trim();
    final analysis = speech.analyzeMatch(currentItem.targetText, spokenText);

    final finalScore = analysis.similarity;
    final isPassed = analysis.isPassed;

    final sourceId =
        'spk_${currentItem.wordId ?? currentItem.exampleId ?? currentIndex.value}';
    final attemptId =
        _activeAttemptId ?? 'spk_${DateTime.now().microsecondsSinceEpoch}';
    final durationSeconds = _listeningStartedAt != null
        ? DateTime.now().difference(_listeningStartedAt!).inSeconds
        : 1;

    final String? rewardUnitId = (sourceContext?.isCurriculum == true)
        ? sourceContext!.duoUnitId
        : (unitId != null &&
                (sourceContext == null || !sourceContext!.isPractice)
            ? 'unit_$unitId'
            : null);
    final String? rewardLevelId =
        (sourceContext?.isCurriculum == true) ? sourceContext!.levelId : null;

    try {
      final reward = await _rewardService.processSpeakingReward(
        sourceId: sourceId,
        attemptId: attemptId,
        accuracyScore: finalScore,
        pronunciationScore: finalScore,
        toneScore: isPassed ? 92.0 : 60.0,
        fluencyScore: isPassed ? 95.0 : 60.0,
        recognizedText: spokenText,
        wordId: currentItem.wordId,
        exampleId: currentItem.exampleId,
        targetText: currentItem.targetText,
        unitId: rewardUnitId,
        levelId: rewardLevelId,
        durationSeconds: durationSeconds,
      );
      learningResult.value = reward;
    } catch (e) {
      if (!isClosed) {
        debugPrint('Reward error: $e');
      }
    }
    _activeAttemptId = null;

    if (epoch != _sessionEpoch || isClosed) return;
    busy.value = false;
    recognized.value = spokenText;
    score.value = learningResult.value?.score ?? finalScore;
    correct.value = learningResult.value?.passed ?? isPassed;

    if (correct.value == true) {
      uiState.value = SpeakingUiState.success;
    } else {
      uiState.value = SpeakingUiState.retry;
    }
  }

  void nextItem(BuildContext context) {
    if (isClosed) return;
    _cancelAllTimers();
    speech.stop();
    uiState.value = SpeakingUiState.idle;
    busy.value = false;
    recognized.value = '';
    correct.value = null;
    score.value = 0.0;
    learningResult.value = null;

    if (currentIndex.value < items.length - 1) {
      currentIndex.value++;
    } else {
      if (isBottomSheet) {
        Navigator.pop(context);
      } else {
        Navigator.pop(context);
      }
    }
  }
}
