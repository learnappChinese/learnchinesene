import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/word.dart';
import '../../../core/learning/service/learning_progress_sync_service.dart';
import '../../flashcards/flashcards_screen.dart';
import '../../hanzi_writing/screens/hanzi_writing_home_screen.dart';
import '../../hanzi_writing/screens/hanzi_writing_screen.dart';
import '../../quiz/quiz_screen.dart';
import '../../speaking/speaking_screen.dart';
import '../../word_detail/word_detail_screen.dart';
import '../data/review_repository.dart';
import '../model/review_item.dart';

class ReviewController extends GetxController {
  ReviewController({
    ReviewRepository? repository,
    LearningProgressSyncService? syncService,
  })  : _repository = repository ?? SupabaseReviewRepository(),
        _syncService = syncService ?? _registeredSyncService();

  final ReviewRepository _repository;
  final LearningProgressSyncService? _syncService;
  LearningSyncRegistration? _syncRegistration;
  int _loadRequest = 0;

  static LearningProgressSyncService? _registeredSyncService() {
    if (!Get.isRegistered<LearningProgressSyncService>()) return null;
    return Get.find<LearningProgressSyncService>();
  }

  final selectedCategory = ReviewCategory.words.obs;
  final summary = Rx<ReviewSummary?>(null);
  final items = <ReviewItem>[].obs;
  final words = <Word>[].obs;
  final isLoading = true.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _syncRegistration = _syncService?.registerRefresher(
      owner: 'review',
      domains: const <LearningDomain>{
        LearningDomain.review,
        LearningDomain.identity,
      },
      refresh: (event) async {
        if (event.type == LearningDomainEventType.identityChanged) {
          summary.value = null;
          items.clear();
          words.clear();
        }
        await loadInitialData(rethrowFailure: true);
      },
    );
    loadInitialData();
  }

  Future<void> loadInitialData({bool rethrowFailure = false}) async {
    final request = ++_loadRequest;
    // Đã có dữ liệu thì làm mới ngầm, không hiện lại loading.
    isLoading.value = summary.value == null;
    errorMessage.value = '';
    try {
      final results = await Future.wait<Object>([
        _repository.loadReviewSummary(),
        _repository.loadReviewItems(selectedCategory.value),
      ]);
      final loadedSummary = results[0] as ReviewSummary;
      final loadedItems = results[1] as List<ReviewItem>;
      if (isClosed || request != _loadRequest) return;
      summary.value = loadedSummary;
      _assignItems(selectedCategory.value, loadedItems);
    } catch (e) {
      if (!isClosed && request == _loadRequest) {
        errorMessage.value = 'Không thể tải dữ liệu ôn tập: $e';
      }
      if (rethrowFailure) rethrow;
    } finally {
      if (!isClosed && request == _loadRequest) isLoading.value = false;
    }
  }

  Future<void> selectCategory(ReviewCategory category) async {
    if (selectedCategory.value == category && items.isNotEmpty) return;
    final request = ++_loadRequest;
    selectedCategory.value = category;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final list = await _repository.loadReviewItems(category);
      if (isClosed || request != _loadRequest) return;
      _assignItems(category, list);
    } catch (e) {
      if (!isClosed && request == _loadRequest) {
        errorMessage.value = 'Không thể tải danh sách ôn tập: $e';
      }
    } finally {
      if (!isClosed && request == _loadRequest) isLoading.value = false;
    }
  }

  Future<void> loadItems(ReviewCategory category) async {
    final request = ++_loadRequest;
    final list = await _repository.loadReviewItems(category);
    if (!isClosed && request == _loadRequest) _assignItems(category, list);
  }

  void _assignItems(ReviewCategory category, List<ReviewItem> list) {
    items.assignAll(list);

    // Keep backwards-compatibility for words property
    if (category == ReviewCategory.words) {
      words.assignAll(_mapItemsToWords(list));
    }
  }

  @override
  void onClose() {
    _loadRequest++;
    _syncRegistration?.dispose();
    super.onClose();
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
        )?.then((_) => loadInitialData());
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
          )?.then((_) => loadInitialData());
        } else {
          Get.to(() => const FlashcardsScreen(initialLevel: 0))
              ?.then((_) => loadInitialData());
        }
        break;
      case ReviewCategory.speaking:
        Get.to(
          () => const SpeakingScreen(random: true),
          arguments: const {'standalone': true},
        )?.then((_) => loadInitialData());
        break;
      case ReviewCategory.hanzi:
        final firstItem =
            items.firstWhereOrNull((it) => it.category == ReviewCategory.hanzi);
        final cid = int.tryParse(firstItem?.id.replaceAll('hanzi_', '') ?? '');
        if (cid != null && cid > 0) {
          Get.to(() => HanziWritingScreen(characterId: cid))
              ?.then((_) => loadInitialData());
        } else {
          Get.to(() => const HanziWritingHomeScreen())
              ?.then((_) => loadInitialData());
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
        Get.to(() => const WordDetailScreen(), arguments: {'word': word})
            ?.then((_) => loadInitialData());
        break;
      case ReviewCategory.listening:
        Get.to(
          () => const QuizScreen(),
          arguments: {
            'unitTitle': 'Luyện nghe câu: ${item.title}',
            'reviewWords':
                words.isNotEmpty ? words.toList() : _mapItemsToWords(items),
          },
        )?.then((_) => loadInitialData());
        break;
      case ReviewCategory.speaking:
        Get.to(
          () => const SpeakingScreen(random: true),
          arguments: const {'standalone': true},
        )?.then((_) => loadInitialData());
        break;
      case ReviewCategory.hanzi:
        final cid = int.tryParse(item.id.replaceAll('hanzi_', ''));
        if (cid != null && cid > 0) {
          Get.to(() => HanziWritingScreen(characterId: cid))
              ?.then((_) => loadInitialData());
        } else {
          Get.to(() => const HanziWritingHomeScreen())
              ?.then((_) => loadInitialData());
        }
        break;
    }
  }
}
