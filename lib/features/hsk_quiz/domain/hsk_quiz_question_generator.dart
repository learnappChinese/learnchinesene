import 'dart:math' as math;

/// Generates curriculum-grounded questions for HSK vocabulary quizzes.
///
/// Ensures all questions, options, and distractors strictly originate from
/// the canonical curriculum vocabulary pool for the specified level.
class HskQuizQuestionGenerator {
  static List<Map<String, dynamic>> generate(
    List<dynamic> vocabulary, {
    int questionCount = 10,
    math.Random? random,
  }) {
    final allWords = List<Map<String, dynamic>>.from(
      vocabulary.map((w) => Map<String, dynamic>.from(w as Map)),
    );

    if (allWords.length < 4) {
      throw Exception('Không đủ từ vựng để tạo bài thi (cần ít nhất 4 từ).');
    }

    final rand = random ?? math.Random();

    // Shuffle and pick target words
    allWords.shuffle(rand);
    final count = math.min(questionCount, allWords.length);
    final wordsForQuiz = allWords.take(count).toList();

    final List<Map<String, dynamic>> generatedQuestions = [];

    for (var word in wordsForQuiz) {
      final hanzi = (word['hanzi'] ?? word['word'] ?? '').toString();
      final pinyin = (word['pinyin'] ?? '').toString();
      final meaningVi = (word['meaning_vi'] ?? '').toString();
      final wordId =
          (word['id'] ?? word['word_id'] ?? word['source_word_id'] ?? 0);
      final level = word['hsk_level'] ?? 1;

      // Types: 0: meaning, 1: hanzi, 2: pinyin
      final typeIndex = rand.nextInt(3);
      final String correctAnswer;
      final String questionText;
      final String matchProperty;

      if (typeIndex == 0) {
        questionText = 'Nghĩa của "$hanzi" là gì?';
        correctAnswer = meaningVi;
        matchProperty = 'meaning_vi';
      } else if (typeIndex == 1) {
        questionText = 'Từ nào có nghĩa là "$meaningVi"?';
        correctAnswer = hanzi;
        matchProperty = 'hanzi';
      } else {
        questionText = 'Pinyin của "$hanzi" là gì?';
        correctAnswer = pinyin;
        matchProperty = 'pinyin';
      }

      // Build unique distractors from the curriculum pool
      final Set<String> distractorSet = {};
      for (final candidate in allWords) {
        final val = (candidate[matchProperty] ??
                (matchProperty == 'hanzi' ? candidate['word'] : null) ??
                '')
            .toString()
            .trim();
        if (val.isNotEmpty && val != correctAnswer) {
          distractorSet.add(val);
        }
      }

      final distractorList = distractorSet.toList()..shuffle(rand);
      final chosenDistractors = distractorList.take(3).toList();

      final List<String> options = [...chosenDistractors, correctAnswer]
        ..shuffle(rand);

      final explanation =
          'Từ vựng HSK $level: $hanzi ($pinyin) có nghĩa là "$meaningVi".';

      generatedQuestions.add({
        'word': word,
        'source_word_id': wordId,
        'word_id': wordId,
        'hsk_level': level,
        'questionText': questionText,
        'correctAnswer': correctAnswer,
        'options': options,
        'typeIndex': typeIndex,
        'explanation': explanation,
      });
    }

    return generatedQuestions;
  }
}
