import 'package:flutter/material.dart';
import '../../core/widgets/app_shimmer.dart';
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
  const WordListScreen({super.key, this.controller});

  final WordListController? controller;

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  late final WordListController controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      controller = widget.controller!;
    } else if (Get.isRegistered<WordListController>()) {
      controller = Get.find<WordListController>();
    } else {
      controller = Get.put(WordListController());
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController && Get.isRegistered<WordListController>()) {
      Get.delete<WordListController>();
    }
    super.dispose();
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
        return const _WordListSkeleton();
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

/// Khung đang tải khớp màn học từ: thanh tiến độ, thẻ từ lớn và hàng nút đáy.
class _WordListSkeleton extends StatelessWidget {
  const _WordListSkeleton();

  @override
  Widget build(BuildContext context) => AppShimmer(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: Row(
                children: [
                  Expanded(child: ShimmerBox(height: 8, radius: 8)),
                  SizedBox(width: 12),
                  ShimmerBox(width: 40, height: 14),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.horizontalPadding(context),
                ),
                child: const SkeletonCard(
                  style: SkeletonCardStyle.cream,
                  radius: 28,
                  padding: EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ShimmerBox(width: 130, height: 80, radius: 18),
                        SizedBox(height: 16),
                        ShimmerBox(width: 100, height: 18),
                        SizedBox(height: 12),
                        SkeletonPill(width: 140, height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                ResponsiveHelper.horizontalPadding(context),
                12,
                ResponsiveHelper.horizontalPadding(context),
                12 + MediaQuery.paddingOf(context).bottom,
              ),
              child: const Row(
                children: [
                  ShimmerBox.circle(size: 48),
                  SizedBox(width: 12),
                  Expanded(child: ShimmerBox(height: 52, radius: 18)),
                ],
              ),
            ),
          ],
        ),
      );
}
