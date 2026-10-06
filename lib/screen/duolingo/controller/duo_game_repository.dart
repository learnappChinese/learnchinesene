import '../../../core/database/duo_db_helper.dart';
import '../../../core/models/duo_challenge.dart';
import '../../../core/models/duo_flashcard.dart';

class DuoGameRepository {
  static final DuoGameRepository instance = DuoGameRepository._();
  DuoGameRepository._();

  Future<List<Map<String, dynamic>>> getGames() async {
    return await DuoDbHelper.instance.getGamesForCenter();
  }

  Future<List<Map<String, dynamic>>> getGameLevels(int gameId, String gameCode) async {
    return await DuoDbHelper.instance.getGamePath(gameId, gameCode);
  }

  // --- HỌC TỪ MỚI (GAME 1) ---
  Future<List<DuoFlashcard>> getLearnWordsQuestions(String levelId) async {
    // 1. Lấy distinct các từ tiếng Trung từ select/assist challenges của Level này
    final challenges = await DuoDbHelper.instance.getChallengesForGameLevel(levelId, 'learn_words', limit: 30);
    final Set<String> wordsSet = {};
    for (var c in challenges) {
      if (c.choicesText != null) {
        // Lấy từ đúng
        final correctIdx = c.choicesCorrect?.indexOf(1) ?? -1;
        if (correctIdx >= 0 && correctIdx < c.choicesText!.length) {
          wordsSet.add(c.choicesText![correctIdx]);
        }
      }
    }

    final wordsList = wordsSet.toList();
    if (wordsList.isEmpty) {
      // Fallback: Lấy 10 từ ngẫu nhiên từ flashcards
      return await DuoDbHelper.instance.getRandomFlashcards(limit: 10);
    }

    // 2. Query thông tin chi tiết của các từ này từ flashcards
    final flashcards = await DuoDbHelper.instance.getFlashcardsForWords(wordsList);
    if (flashcards.length < 10) {
      // Điền thêm nếu thiếu
      final additional = await DuoDbHelper.instance.getRandomFlashcards(limit: 10 - flashcards.length);
      flashcards.addAll(additional);
    }

    flashcards.shuffle();
    return flashcards.take(10).toList();
  }

  // --- NỐI CHỮ (GAME 2) ---
  Future<List<Map<String, String>>> getWordConnectQuestions(String levelId) async {
    final challenges = await DuoDbHelper.instance.getChallengesForGameLevel(levelId, 'word_connect', limit: 30);
    final Set<String> chineseWords = {};
    for (var c in challenges) {
      if (c.choicesText != null) {
        final correctIdx = c.choicesCorrect?.indexOf(1) ?? -1;
        if (correctIdx >= 0 && correctIdx < c.choicesText!.length) {
          chineseWords.add(c.choicesText![correctIdx]);
        }
      }
    }

    final wordsList = chineseWords.toList();
    if (wordsList.isEmpty) {
      return [
        {'zh': '你好', 'vi': 'chào bạn'},
        {'zh': '谢谢', 'vi': 'cám ơn'},
        {'zh': '茶', 'vi': 'trà'},
        {'zh': '水', 'vi': 'nước'},
        {'zh': '咖啡', 'vi': 'cà phê'},
      ];
    }

    final flashcards = await DuoDbHelper.instance.getFlashcardsForWords(wordsList);
    final List<Map<String, String>> pairs = [];
    for (var f in flashcards) {
      if (f.word.isNotEmpty && f.meaning != null && f.meaning!.isNotEmpty) {
        pairs.add({'zh': f.word, 'vi': f.meaning!});
      }
    }

    if (pairs.length < 5) {
      // Fallback
      final additional = await DuoDbHelper.instance.getRandomFlashcards(limit: 5 - pairs.length);
      for (var f in additional) {
        pairs.add({'zh': f.word, 'vi': f.meaning ?? 'Nghĩa'});
      }
    }

    pairs.shuffle();
    return pairs.take(6).toList(); // Lấy 6 cặp để nối
  }

  // --- TRẮC NGHIỆM / CHỌN ĐÁP ÁN (GAME 3) ---
  Future<List<DuoChallenge>> getSelectQuestions(String levelId) async {
    return await DuoDbHelper.instance.getChallengesForGameLevel(levelId, 'select_answer', limit: 10);
  }

  // --- NGHE VÀ CHỌN (GAME 4) ---
  Future<List<DuoChallenge>> getListenQuestions(String levelId) async {
    return await DuoDbHelper.instance.getChallengesForGameLevel(levelId, 'listen_select', limit: 10);
  }

  // --- DỊCH CÂU (GAME 5) ---
  Future<List<DuoChallenge>> getTranslateQuestions(String levelId) async {
    return await DuoDbHelper.instance.getChallengesForGameLevel(levelId, 'translate', limit: 10);
  }

  // --- ĐIỀN TỪ (GAME 6) ---
  Future<List<DuoChallenge>> getGapFillQuestions(String levelId) async {
    return await DuoDbHelper.instance.getChallengesForGameLevel(levelId, 'gap_fill', limit: 10);
  }

  // --- HOÀN THÀNH CÂU (GAME 7) ---
  Future<List<DuoChallenge>> getTapCompleteQuestions(String levelId) async {
    return await DuoDbHelper.instance.getChallengesForGameLevel(levelId, 'tap_complete', limit: 10);
  }

  // --- HỘI THOẠI (GAME 8) ---
  Future<List<DuoChallenge>> getDialogueQuestions(String levelId) async {
    return await DuoDbHelper.instance.getChallengesForGameLevel(levelId, 'dialogue', limit: 10);
  }

  // --- SẮP XẾP CÂU (GAME 9) ---
  Future<List<DuoChallenge>> getSentenceOrderQuestions(String levelId) async {
    final list = await DuoDbHelper.instance.getChallengesForGameLevel(levelId, 'sentence_order', limit: 10);
    // Xử lý thông minh fallback nếu không có tokens_text
    final List<DuoChallenge> processed = [];
    for (var c in list) {
      if (c.tokensText == null || c.tokensText!.isEmpty) {
        // Tự bẻ câu prompt/solution thành các mảnh chữ để xếp
        final textToSplit = c.solutions ?? c.prompt ?? '';
        final List<String> fakeTokens = textToSplit.split(' ').where((w) => w.trim().isNotEmpty).toList();
        
        // Tạo map mới để lưu
        processed.add(DuoChallenge(
          id: c.id,
          type: 'orderTapComplete',
          prompt: c.prompt,
          tts: c.tts,
          choicesText: fakeTokens..shuffle(),
          choicesCorrect: List.generate(fakeTokens.length, (index) => index + 1), // Trả về index thứ tự
          solutions: textToSplit,
          tokensText: fakeTokens,
        ));
      } else {
        processed.add(c);
      }
    }
    return processed;
  }

  // --- LUYỆN PHÁT ÂM (GAME 10) ---
  Future<List<DuoChallenge>> getSpeakingQuestions(String levelId) async {
    return await DuoDbHelper.instance.getChallengesForGameLevel(levelId, 'speaking', limit: 10);
  }

  // --- LƯU TRỮ TIẾN TRÌNH ---
  Future<void> saveProgress(
    int gameId,
    String levelId,
    int score,
    int stars,
    bool passed,
  ) async {
    await DuoDbHelper.instance.saveLevelProgress(
      gameId,
      levelId,
      score,
      stars,
      passed,
    );
  }

  Future<void> unlockLevel(int gameId, String levelId) {
    return DuoDbHelper.instance.unlockLevel(gameId, levelId);
  }
}
