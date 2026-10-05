import 'dart:math';

import '../database/db_helper.dart';
import '../models/quiz_question.dart';
import '../models/word.dart';

class QuizService {
  final DbHelper _dbHelper;
  final Random _random;

  QuizService({DbHelper? dbHelper, Random? random})
      : _dbHelper = dbHelper ?? DbHelper.instance,
        _random = random ?? Random();

  Future<List<QuizQuestion>> generateForUnit(int unitId) async {
    final words = await _dbHelper.getWordsByUnit(unitId);
    return _buildQuestions(words);
  }

  Future<List<QuizQuestion>> generateForWords(List<Word> words) async {
    return _buildQuestions(words);
  }

  List<QuizQuestion> _buildQuestions(List<Word> words) {
    if (words.length < 4) return <QuizQuestion>[];

    final questions = <QuizQuestion>[];

    for (final word in words) {
      if (word.vietnamese.isNotEmpty) {
        questions.add(_cnToVi(word, words));
        questions.add(_viToCn(word, words));
      }
      if (word.pinyin.isNotEmpty) {
        questions.add(_cnToPinyin(word, words));
      }
      if (word.ttsUrl.isNotEmpty) {
        questions.add(_listening(word, words));
      }
    }

    questions.shuffle(_random);
    return questions.take(20).toList();
  }

  QuizQuestion _cnToVi(Word word, List<Word> pool) {
    final wrong = _pickWrongValues(
      pool: pool,
      currentWordId: word.id,
      extractor: (w) => w.vietnamese,
    );

    final options = <String>[word.vietnamese, ...wrong]..shuffle(_random);
    return QuizQuestion(
      wordId: word.id,
      type: QuizType.chineseToVietnamese,
      question: '“${word.chinese}” có nghĩa là gì?',
      options: options,
      correctAnswer: word.vietnamese,
    );
  }

  QuizQuestion _viToCn(Word word, List<Word> pool) {
    final wrong = _pickWrongValues(
      pool: pool,
      currentWordId: word.id,
      extractor: (w) => w.chinese,
    );

    final options = <String>[word.chinese, ...wrong]..shuffle(_random);
    return QuizQuestion(
      wordId: word.id,
      type: QuizType.vietnameseToChinese,
      question: 'Từ tiếng Trung nào có nghĩa là “${word.vietnamese}”?',
      options: options,
      correctAnswer: word.chinese,
    );
  }

  QuizQuestion _cnToPinyin(Word word, List<Word> pool) {
    final wrong = _pickWrongValues(
      pool: pool,
      currentWordId: word.id,
      extractor: (w) => w.pinyin,
    );

    final options = <String>[word.pinyin, ...wrong]..shuffle(_random);
    return QuizQuestion(
      wordId: word.id,
      type: QuizType.chineseToPinyin,
      question: 'Pinyin của “${word.chinese}” là gì?',
      options: options,
      correctAnswer: word.pinyin,
    );
  }

  QuizQuestion _listening(Word word, List<Word> pool) {
    final wrong = _pickWrongValues(
      pool: pool,
      currentWordId: word.id,
      extractor: (w) => w.chinese,
    );

    final options = <String>[word.chinese, ...wrong]..shuffle(_random);
    return QuizQuestion(
      wordId: word.id,
      type: QuizType.listening,
      question: 'Hãy nghe và chọn từ chính xác.',
      options: options,
      correctAnswer: word.chinese,
      audioUrl: word.ttsUrl,
    );
  }

  List<String> _pickWrongValues({
    required List<Word> pool,
    required int currentWordId,
    required String Function(Word) extractor,
  }) {
    final candidates = pool
        .where((w) => w.id != currentWordId)
        .map(extractor)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList();

    candidates.shuffle(_random);
    return candidates.take(3).toList();
  }
}
