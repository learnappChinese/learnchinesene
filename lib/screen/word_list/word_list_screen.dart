import 'package:flutter/material.dart';
import '../../core/widgets/bottom_action_bar.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/word_card.dart';
import '../../core/widgets/learning_scene_background.dart';
import '../quiz/quiz_screen.dart';
import '../word_detail/word_detail_screen.dart';
import 'controller/word_list_controller.dart';
import '../../core/models/word.dart';

class WordListScreen extends StatefulWidget {
  const WordListScreen({super.key});

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  late final WordListController controller;

  @override
  void initState() {
    super.initState();
    // The existing GetX route owns this registration.
    controller = Get.isRegistered<WordListController>()
        ? Get.find<WordListController>()
        : Get.put(WordListController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.title,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
      body: LearningSceneBackground(
        theme: LearningSceneTheme.bambooVillage,
        child: _buildWordContent(context),
      ),
    );
  }

  Widget _buildWordProgress(List<Word> words) {
    return Obx(() => Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
          child: Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: (controller.index.value + 1) / words.length,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${controller.index.value + 1} / ${words.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildWordPages(List<Word> words) {
    return PageView.builder(
      controller: controller.pageController,
      itemCount: words.length,
      onPageChanged: controller.setIndex,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 14),
        child: WordCard(
          hero: true,
          word: words[i],
          onTap: () => Get.to(
            () => const WordDetailScreen(),
            arguments: {'word': words[i]},
          ),
        ),
      ),
    );
  }

  Widget _buildWordActions(List<Word> words) {
    return BottomActionBar(
        verticalPadding: 14,
        shadowBlur: 18,
        shadowOffset: -5,
        child: Obx(() {
          final current =
              words[controller.index.value.clamp(0, words.length - 1)];
          return Row(
            children: [
              IconButton.filledTonal(
                onPressed: controller.learned.contains(current.id)
                    ? null
                    : () => controller.markLearned(current),
                icon: Icon(
                  controller.learned.contains(current.id)
                      ? Icons.check_rounded
                      : Icons.bookmark_add_outlined,
                ),
                tooltip: 'Đánh dấu đã học',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: controller.index.value == words.length - 1
                      ? 'Kiểm tra bài học'
                      : 'Từ tiếp theo',
                  icon: controller.index.value == words.length - 1
                      ? Icons.quiz_rounded
                      : Icons.arrow_forward_rounded,
                  onPressed: () {
                    if (controller.index.value == words.length - 1) {
                      Get.to(
                        () => const QuizScreen(),
                        arguments: {
                          'unitId': controller.unitId,
                          'unitTitle': controller.title
                        },
                      );
                    } else {
                      controller.next();
                    }
                  },
                ),
              ),
            ],
          );
        }));
  }

  Widget _buildWordContent(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.hasError.value) {
        return const EmptyStateWidget(
          icon: Icons.error_outline_rounded,
          title: 'Không thể tải bài học',
          message: 'Không thể mở bài từ vựng ngoại tuyến này.',
        );
      }
      final words = controller.words;
      if (words.isEmpty) {
        return const EmptyStateWidget(
          icon: Icons.style_outlined,
          title: 'Chưa có từ vựng',
          message: 'Bài học này chưa có dữ liệu từ vựng.',
        );
      }

      return Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: ResponsiveHelper.contentMaxWidth(context)),
                child: Column(
                  children: [
                    _buildWordProgress(words),
                    Expanded(
                      child: _buildWordPages(words),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildWordActions(words),
        ],
      );
    });
  }
}
