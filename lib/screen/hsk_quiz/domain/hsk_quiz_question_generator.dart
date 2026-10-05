import 'dart:math' as math;

class HskQuizQuestionGenerator {
  static List<dynamic> generate(List<dynamic> vocabulary) {
    final allWords = List<dynamic>.of(vocabulary);
    if (allWords.length < 10) {
      throw Exception('Không đủ từ vựng để tạo bài thi.');
    }

    // Generate 10 random questions
    allWords.shuffle();
    final wordsForQuiz = allWords.take(10).toList();

    final List<dynamic> generatedQuestions = [];
    final random = math.Random();

    for (var word in wordsForQuiz) {
      // Types: 0: meaning, 1: hanzi, 2: pinyin
      final typeIndex = random.nextInt(3);
      final String correctAnswer;
      final String questionText;
      final String matchProperty;

      if (typeIndex == 0) {
        questionText = 'Nghĩa của "${word['hanzi']}" là gì?';
        correctAnswer = word['meaning_vi'] ?? '';
        matchProperty = 'meaning_vi';
      } else if (typeIndex == 1) {
        questionText = 'Từ nào có nghĩa là "${word['meaning_vi']}"?';
        correctAnswer = word['hanzi'] ?? '';
        matchProperty = 'hanzi';
      } else {
        questionText = 'Pinyin của "${word['hanzi']}" là gì?';
        correctAnswer = word['pinyin'] ?? '';
        matchProperty = 'pinyin';
      }

      // Build distractors
      final List<String> distractors = allWords
          .where((w) => w[matchProperty] != correctAnswer)
          .map((w) => (w[matchProperty] as String? ?? ''))
          .where((str) => str.isNotEmpty)
          .toList();

      distractors.shuffle();
      final List<String> options = distractors.take(3).toList();
      options.add(correctAnswer);
      options.shuffle();

      generatedQuestions.add({
        'word': word,
        'questionText': questionText,
        'correctAnswer': correctAnswer,
        'options': options,
        'typeIndex': typeIndex,
      });
    }

    return generatedQuestions;
  }
}
