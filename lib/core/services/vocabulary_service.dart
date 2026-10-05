import '../database/db_helper.dart';
import '../models/example_sentence.dart';
import '../models/word.dart';
import '../models/speaking_practice_item.dart';

class VocabularyService {
  VocabularyService({DbHelper? database})
      : _database = database ?? DbHelper.instance;

  final DbHelper _database;

  Future<List<Word>> wordsForUnit(int unitId) =>
      _database.getWordsByUnit(unitId);

  Future<List<ExampleSentence>> examplesForWord(int wordId) =>
      _database.getExamplesByWord(wordId);

  Future<SpeakingPracticeItem?> getSpeakingItemByWordId(int wordId) =>
      _database.getSpeakingItemByWordId(wordId);

  Future<SpeakingPracticeItem?> getSpeakingItemByExampleId(int exampleId) =>
      _database.getSpeakingItemByExampleId(exampleId);

  Future<List<SpeakingPracticeItem>> getSpeakingItemsByUnitId(int unitId) =>
      _database.getSpeakingItemsByUnitId(unitId);

  Future<List<SpeakingPracticeItem>> getRandomSpeakingItems({int limit = 20}) =>
      _database.getRandomSpeakingItems(limit: limit);
}
