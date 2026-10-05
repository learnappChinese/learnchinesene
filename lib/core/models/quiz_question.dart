enum QuizType {
  chineseToVietnamese,
  vietnameseToChinese,
  chineseToPinyin,
  listening,
}

class QuizQuestion {
  final int wordId;
  final QuizType type;
  final String question;
  final String? audioUrl;
  final List<String> options;
  final String correctAnswer;

  const QuizQuestion({
    required this.wordId,
    required this.type,
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.audioUrl,
  });
}
