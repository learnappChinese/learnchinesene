import 'package:get/get.dart';
import 'duo_game_repository.dart';
import '../../../core/database/duo_db_helper.dart';
import '../../home/controller/home_controller.dart';

class DuoGameRunnerController extends GetxController {
  final int gameId;
  final String gameCode;
  final String levelId;

  DuoGameRunnerController({
    required this.gameId,
    required this.gameCode,
    required this.levelId,
  });

  final isLoading = true.obs;
  
  // Danh sách các câu hỏi/thử thách
  final challenges = <dynamic>[].obs;
  
  final currentIndex = 0.obs;
  final isAnsweredCorrectly = RxnBool();
  
  final correctCount = 0.obs;
  final wrongCount = 0.obs;
  final score = 0.obs;
  
  // Lưu danh sách câu sai để làm lại ở cuối
  final incorrectChallenges = <dynamic>[].obs;

  final isCompleted = false.obs;
  final calculatedStars = 0.obs;
  final finalScore = 0.obs;

  @override
  void onInit() {
    super.onInit();
    initSession();
  }

  Future<void> initSession() async {
    isLoading.value = true;
    try {
      // 1. Kiểm tra xem có session làm dở dang không
      final active = await DuoDbHelper.instance.getActiveSession(gameId, levelId);
      
      // Load questions tương ứng
      List<dynamic> list = [];
      if (gameCode == 'learn_words') {
        list = await DuoGameRepository.instance.getLearnWordsQuestions(levelId);
      } else if (gameCode == 'word_connect') {
        list = await DuoGameRepository.instance.getWordConnectQuestions(levelId);
      } else if (gameCode == 'select_answer') {
        list = await DuoGameRepository.instance.getSelectQuestions(levelId);
      } else if (gameCode == 'listen_select') {
        list = await DuoGameRepository.instance.getListenQuestions(levelId);
      } else if (gameCode == 'translate') {
        list = await DuoGameRepository.instance.getTranslateQuestions(levelId);
      } else if (gameCode == 'gap_fill') {
        list = await DuoGameRepository.instance.getGapFillQuestions(levelId);
      } else if (gameCode == 'tap_complete') {
        list = await DuoGameRepository.instance.getTapCompleteQuestions(levelId);
      } else if (gameCode == 'dialogue') {
        list = await DuoGameRepository.instance.getDialogueQuestions(levelId);
      } else if (gameCode == 'sentence_order') {
        list = await DuoGameRepository.instance.getSentenceOrderQuestions(levelId);
      } else if (gameCode == 'speaking') {
        list = await DuoGameRepository.instance.getSpeakingQuestions(levelId);
      }

      challenges.assignAll(list);

      if (active != null) {
        // Khôi phục session cũ
        currentIndex.value = active['current_index'] as int;
        score.value = active['score'] as int;
        correctCount.value = active['correct_count'] as int;
        wrongCount.value = active['wrong_count'] as int;
      } else {
        currentIndex.value = 0;
        correctCount.value = 0;
        wrongCount.value = 0;
        score.value = 0;
      }

      isCompleted.value = false;
      _resetTurn();
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể khởi tạo màn chơi: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _resetTurn() {
    isAnsweredCorrectly.value = null;
  }

  // Gửi câu trả lời
  void submitAnswer(bool isCorrect) async {
    if (isAnsweredCorrectly.value != null) return;
    
    isAnsweredCorrectly.value = isCorrect;
    
    if (isCorrect) {
      correctCount.value++;
      score.value += 10;
    } else {
      wrongCount.value++;
      incorrectChallenges.add(challenges[currentIndex.value]);
    }

    // Tự động lưu session dở dang vào Supabase (guest dùng local fallback)
    await DuoDbHelper.instance.saveActiveSession(
      gameId,
      levelId,
      currentIndex.value,
      score.value,
      correctCount.value,
      wrongCount.value,
    );
  }

  void nextChallenge() async {
    if (currentIndex.value < challenges.length - 1) {
      currentIndex.value++;
      _resetTurn();
      
      // Cập nhật session dở dang
      await DuoDbHelper.instance.saveActiveSession(
        gameId,
        levelId,
        currentIndex.value,
        score.value,
        correctCount.value,
        wrongCount.value,
      );
    } else {
      // Nếu có câu sai -> cho làm lại các câu sai
      if (incorrectChallenges.isNotEmpty) {
        challenges.assignAll(incorrectChallenges.toList());
        incorrectChallenges.clear();
        currentIndex.value = 0;
        _resetTurn();
      } else {
        _finishSession();
      }
    }
  }

  Future<void> _finishSession() async {
    final total = correctCount.value + wrongCount.value;
    final ratio = total > 0 ? (correctCount.value / total) : 1.0;
    
    int stars = 1;
    if (ratio >= 1.0) {
      stars = 3;
    } else if (ratio >= 0.8) {
      stars = 2;
    } else if (ratio >= 0.7) {
      stars = 1;
    } else {
      stars = 0;
    }

    final bool passed = ratio >= 0.7; // Đạt trên 70% là qua môn

    calculatedStars.value = stars;
    finalScore.value = score.value;
    isCompleted.value = true;

    // Xóa session dở dang vì đã hoàn thành
    await DuoDbHelper.instance.clearActiveSession(gameId, levelId);

    // Lưu kết quả tiến trình & mở khóa màn sau
    await DuoGameRepository.instance.saveProgress(
      gameId,
      levelId,
      score.value,
      stars,
      passed,
    );

    if (Get.isRegistered<HomeController>()) {
      await Get.find<HomeController>().refreshStats();
    }

    // Xử lý logic Unlock Level kế tiếp nếu thi đỗ
    if (passed) {
      await _unlockNextAvailableLevel();
    }
  }

  // Phương thức tìm và unlock level kế tiếp (bỏ qua các level bị Empty)
  Future<void> _unlockNextAvailableLevel() async {
    final levels = await DuoDbHelper.instance.getGamePath(gameId, gameCode);
    bool foundCurrent = false;
    
    for (var l in levels) {
      final id = l['level_id'] as String;
      final cCount = l['challenge_count'] as int;

      if (foundCurrent) {
        if (cCount > 0) {
          await DuoDbHelper.instance.unlockLevel(gameId, id);
          break;
        }
      } else if (id == levelId) {
        foundCurrent = true;
      }
    }
  }
}
