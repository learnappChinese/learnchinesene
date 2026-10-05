import 'package:get/get.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/models/word.dart';

class FlashcardsController extends GetxController {
  FlashcardsController({DbHelper? database})
      : _database = database ?? DbHelper.instance;
  final DbHelper _database;
  final deck = <Word>[].obs;
  final isLoading = false.obs;
  int _request = 0;

  Future<void> loadDeck(int level) async {
    if (isClosed) return;
    final request = ++_request;
    isLoading.value = true;
    deck.clear();
    try {
      final words = <Word>[];
      if (level == 0) {
        words.addAll(await _database.getReviewWords());
      } else {
        final units = await _database.getUnitsByLevel(level);
        if (isClosed || request != _request) return;
        for (final unit in units) {
          words.addAll(await _database.getWordsByUnit(unit.id));
          if (isClosed || request != _request) return;
        }
      }
      if (isClosed || request != _request) return;
      words.shuffle();
      deck.assignAll(words.take(30));
    } catch (_) {
      // Preserve the existing empty-deck presentation for failed loads.
    } finally {
      if (!isClosed && request == _request) isLoading.value = false;
    }
  }

  Future<void> rate(Word word, String rating) async {
    if (isClosed) return;
    try {
      await _database.upsertProgress(
          wordId: word.id, isCorrect: rating != 'hard');
    } catch (_) {
      // Preserve advancing the card even when the progress write fails.
    }
  }
}
