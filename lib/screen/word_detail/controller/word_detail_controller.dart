import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/models/word.dart';
import '../../../core/models/example_sentence.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/progress_service.dart';
import '../../speaking/speaking_screen.dart';

class WordDetailController extends GetxController {
  final audio = AudioService();
  final progress = ProgressService();

  Word? word;
  final examples = <ExampleSentence>[].obs;
  final isLoadingExamples = true.obs;

  final learned = false.obs;
  final characterId = RxnInt();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    word = args?['word'] as Word?;
    if (word != null) {
      loadData();
    }
  }

  @override
  void onClose() {
    audio.dispose();
    super.onClose();
  }

  Future<void> loadData() async {
    isLoadingExamples.value = true;
    try {
      final res = await DbHelper.instance.getExamplesByWord(word!.id);
      examples.value = res;
    } finally {
      isLoadingExamples.value = false;
    }

    final charId =
        await DbHelper.instance.getCharacterIdByCharString(word!.chinese);
    characterId.value = charId;
  }

  void speak({int? exampleId}) {
    Get.bottomSheet(
      FractionallySizedBox(
        heightFactor: 0.85,
        child: SpeakingScreen(
          wordId: exampleId == null ? word?.id : null,
          exampleId: exampleId,
          isBottomSheet: true,
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> mark() async {
    if (word == null) return;
    await progress.markLearned(word!.id);
    learned.value = true;
  }
}
