import 'package:get/get.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/models/hanzi_character.dart';

class HanziWritingHomeController extends GetxController {
  HanziWritingHomeController({DbHelper? database})
      : _database = database ?? DbHelper.instance;
  final DbHelper _database;
  final characters = <HanziCharacter>[].obs;
  final isLoading = true.obs;
  int _request = 0;

  void invalidateSearch() => _request++;

  Future<void> loadCharacters({required String keyword, int? hskLevel}) async {
    if (isClosed) return;
    final request = ++_request;
    isLoading.value = true;
    try {
      final result = await _database.getCharactersForWriting(
          keyword: keyword.isEmpty ? null : keyword, hskLevel: hskLevel);
      if (isClosed || request != _request) return;
      characters.assignAll(result);
    } catch (_) {
      // Preserve the existing empty/previous list on a failed search.
    } finally {
      if (!isClosed && request == _request) isLoading.value = false;
    }
  }
}
