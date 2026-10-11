import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/word.dart';
import '../../conversations/conversations_screen.dart';
import '../../hanzi_writing/screens/hanzi_writing_home_screen.dart';
import '../../hanzi_writing/screens/hanzi_writing_screen.dart';
import '../../quiz/quiz_screen.dart';
import '../../speaking/speaking_screen.dart';
import '../../word_detail/word_detail_screen.dart';
import '../data/review_repository.dart';
import '../model/review_item.dart';

class ReviewController extends GetxController {
  ReviewController({ReviewRepository? repository})
      : _repository = repository ?? SupabaseReviewRepository();

  final ReviewRepository _repository;

  final selectedCategory = ReviewCategory.words.obs;
  final summary = Rx<ReviewSummary?>(null);
  final items = <ReviewItem>[].obs;
  final words = <Word>[].obs;
  final isLoading = true.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      summary.value = await _repository.loadReviewSummary();
      await loadItems(selectedCategory.value);
    } catch (e) {
      errorMessage.value = 'Không thể tải dữ liệu ôn tập: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectCategory(ReviewCategory category) async {
    if (selectedCategory.value == category && items.isNotEmpty) return;
    selectedCategory.value = category;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await loadItems(category);
    } catch (e) {
      errorMessage.value = 'Không thể tải danh sách ôn tập: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadItems(ReviewCategory category) async {
    final list = await _repository.loadReviewItems(category);
    items.assignAll(list);

    // Keep backwards-compatibility for words property
    if (category == ReviewCategory.words) {
      words.assignAll(_mapItemsToWords(list));
    }
  }

  List<Word> _mapItemsToWords(List<ReviewItem> reviewItems) {
    final result = <Word>[];
    for (final item in reviewItems) {
      if (item.rawData is Word) {
        result.add(item.rawData as Word);
      } else {
        result.add(Word(
          id: int.tryParse(item.id.replaceAll('word_', '')) ?? 0,
          chinese: item.title,
          pinyin: item.subtitle,
          vietnamese: item.translation,
          english: '',
          ttsUrl: item.audioUrl ?? '',
          hskLevelId: 1,
          sectionTitle: 'Ôn tập',
          groupSubtitle: '',
          wrongCount: item.wrongCount,
          correctCount: (item.score / 10).round(),
        ));
      }
    }
    return result;
  }

  void startCategoryReview(BuildContext context) {
    switch (selectedCategory.value) {
      case ReviewCategory.words:
        final wordList =
            words.isNotEmpty ? words.toList() : _mapItemsToWords(items);
        if (wordList.isEmpty) return;
        Get.to(
          () => const QuizScreen(),
          arguments: {
            'unitTitle': 'Ôn tập Từ vựng',
            'reviewWords': wordList,
          },
        );
        break;
      case ReviewCategory.listening:
        final wordList =
            words.isNotEmpty ? words.toList() : _mapItemsToWords(items);
        if (wordList.isNotEmpty) {
          Get.to(
            () => const QuizScreen(),
            arguments: {
              'unitTitle': 'Ôn tập Luyện nghe',
              'reviewWords': wordList,
            },
          );
        } else {
          Get.to(() => const ConversationsScreen());
        }
        break;
      case ReviewCategory.speaking:
        Get.to(
          () => const SpeakingScreen(random: true),
          arguments: const {'standalone': true},
        );
        break;
      case ReviewCategory.hanzi:
        final firstItem =
            items.firstWhereOrNull((it) => it.category == ReviewCategory.hanzi);
        final cid = int.tryParse(firstItem?.id.replaceAll('hanzi_', '') ?? '');
        if (cid != null && cid > 0) {
          Get.to(() => HanziWritingScreen(characterId: cid));
        } else {
          Get.to(() => const HanziWritingHomeScreen());
        }
        break;
    }
  }

  void openItemPractice(ReviewItem item) {
    switch (item.category) {
      case ReviewCategory.words:
        final word = item.rawData is Word
            ? item.rawData as Word
            : Word(
                id: int.tryParse(item.id.replaceAll('word_', '')) ?? 0,
                chinese: item.title,
                pinyin: item.subtitle,
                vietnamese: item.translation,
                english: '',
                ttsUrl: item.audioUrl ?? '',
                hskLevelId: 1,
                sectionTitle: 'Ôn tập',
                groupSubtitle: '',
                wrongCount: item.wrongCount,
              );
        Get.to(() => const WordDetailScreen(), arguments: {'word': word});
        break;
      case ReviewCategory.listening:
        Get.to(
          () => const QuizScreen(),
          arguments: {
            'unitTitle': 'Luyện nghe câu: ${item.title}',
            'reviewWords':
                words.isNotEmpty ? words.toList() : _mapItemsToWords(items),
          },
        );
        break;
      case ReviewCategory.speaking:
        Get.to(
          () => const SpeakingScreen(random: true),
          arguments: const {'standalone': true},
        );
        break;
      case ReviewCategory.hanzi:
        final cid = int.tryParse(item.id.replaceAll('hanzi_', ''));
        if (cid != null && cid > 0) {
          Get.to(() => HanziWritingScreen(characterId: cid));
        } else {
          Get.to(() => const HanziWritingHomeScreen());
        }
        break;
    }
  }
}
