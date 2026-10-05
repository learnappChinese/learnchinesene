import 'package:flash_learn_chinese/screen/vocabulary/data/models/progress_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ProgressModel parses Supabase boolean and last_review_at', () {
    final model = ProgressModel.fromMap({
      'word_id': 42,
      'correct_count': 3,
      'wrong_count': 1,
      'level': 2,
      'mastered': true,
      'last_review_at': '2026-09-29T08:00:00.000Z',
    });

    expect(model.wordId, 42);
    expect(model.correctCount, 3);
    expect(model.wrongCount, 1);
    expect(model.level, 2);
    expect(model.mastered, isTrue);
    expect(model.lastPractice?.toUtc().toIso8601String(),
        '2026-09-29T08:00:00.000Z');
  });
}
