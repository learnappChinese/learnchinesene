import 'package:flutter/material.dart';
import '../../../core/widgets/app_shimmer.dart';
import 'package:get/get.dart';

import '../../../core/theme/game_visual_tokens.dart';
import '../../../core/theme/learning_theme.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/learning_scene_background.dart';
import '../controller/flashcards_study_controller.dart';
import '../models/flashcard_models.dart';
import '../widget/anki_rating_buttons.dart';
import '../widget/flashcard_card_view.dart';
import '../widget/flashcard_content.dart';

/// Màn hình phiên học Flashcard chuyên sâu theo phong cách Anki và thuật toán FSRS.
class FlashcardStudyScreen extends StatefulWidget {
  final FlashcardDirection direction;
  final int? hskLevel;
  final int? unitId;
  final List<int>? unitIds;
  final bool onlyDue;
  final bool onlyNew;
  final int cardLimit;

  const FlashcardStudyScreen({
    super.key,
    this.direction = FlashcardDirection.zhToVi,
    this.hskLevel,
    this.unitId,
    this.unitIds,
    this.onlyDue = false,
    this.onlyNew = false,
    this.cardLimit = 20,
  });

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;

  static int _nextId = 0;
  late final String _tag;
  late final FlashcardsStudyController controller;

  @override
  void initState() {
    super.initState();
    _tag = 'study-controller-${_nextId++}';
    controller = Get.put(
      FlashcardsStudyController(
        direction: widget.direction,
        hskLevel: widget.hskLevel,
        unitId: widget.unitId,
        unitIds: widget.unitIds,
        onlyDue: widget.onlyDue,
        onlyNew: widget.onlyNew,
        cardLimit: widget.cardLimit,
      ),
      tag: _tag,
    );

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    );

    // Lắng nghe thay đổi card để reset animation
    ever(controller.currentItem, (_) {
      if (mounted) {
        _flipController.reset();
      }
    });
  }

  @override
  void dispose() {
    Get.delete<FlashcardsStudyController>(tag: _tag);
    _flipController.dispose();
    super.dispose();
  }

  void _handleFlip() {
    if (_flipController.isAnimating) return;
    if (controller.isFlipped.value) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    controller.flipCard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LearningColors.background,
      appBar: AppBar(
        systemOverlayStyle: LearningSystemUi.overlay,
        backgroundColor: LearningColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 64,
        leading: Center(
          child: AppHudIconButton(
            icon: Icons.close_rounded,
            tooltip: 'Đóng',
            size: 40,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Obx(() {
          final current = controller.currentItem.value;
          if (current == null) {
            return const Text('Ôn tập Flashcard',
                style: LearningTypography.screenTitle);
          }
          return Text(
            'Thẻ ${controller.reviewedCount.value + 1} / ${controller.reviewedCount.value + controller.remainingCount.value}',
            style: LearningTypography.screenTitle,
          );
        }),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AppHudIconButton(
              icon: Icons.volume_up_rounded,
              tooltip: 'Phát âm từ vựng',
              size: 40,
              onPressed: controller.playAudio,
            ),
          ),
        ],
      ),
      body: LearningSceneBackground(
        theme: LearningSceneTheme.bambooVillage,
        child: SafeArea(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const _FlashcardStudySkeleton();
            }

            if (controller.isSessionFinished.value) {
              return FlashcardCompletion(
                cardsReviewed: controller.queueService.reviewedCount,
                correctCards: controller.queueService.correctCount,
                xpEarned: controller.sessionXpEarned.value,
                onContinue: () {
                  Navigator.pop(context);
                },
                onBackHome: () {
                  Navigator.pop(context);
                },
              );
            }

            final currentCard = controller.currentItem.value;
            if (currentCard == null) {
              return const FlashcardEmptyState(isReview: true);
            }

            final totalInSession =
                controller.reviewedCount.value + controller.remainingCount.value;
            final progressRatio = totalInSession > 0
                ? (controller.reviewedCount.value / totalInSession).clamp(0.0, 1.0)
                : 0.0;

            return Column(
              children: [
                // Thanh tiến độ học tập trên cùng
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progressRatio,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFEDE5D6),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        GameVisualTokens.primaryGreen,
                      ),
                    ),
                  ),
                ),

                // Khung lật thẻ 3D
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FlashcardCardView(
                      item: currentCard,
                      isFlipped: controller.isFlipped.value,
                      flipAnimation: _flipAnimation,
                      onFlip: _handleFlip,
                      onPlayAudio: controller.playAudio,
                    ),
                  ),
                ),

                // Bốn nút đánh giá Anki (Chỉ hiển thị khi đã lật thẻ xem đáp án)
                AnimatedOpacity(
                  opacity: controller.isFlipped.value ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: IgnorePointer(
                    ignoring: !controller.isFlipped.value,
                    child: AnkiRatingButtons(
                      againHint: controller.againHint.value,
                      hardHint: controller.hardHint.value,
                      goodHint: controller.goodHint.value,
                      easyHint: controller.easyHint.value,
                      isEnabled: !controller.isAnswering.value,
                      onRate: controller.rateCard,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            );
          }),
        ),
      ),
    );
  }
}

/// Khung đang tải khớp bố cục màn: thanh tiến độ và mặt trước thẻ flashcard.
class _FlashcardStudySkeleton extends StatelessWidget {
  const _FlashcardStudySkeleton();

  @override
  Widget build(BuildContext context) => const AppShimmer(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ShimmerBox(height: 8, radius: 8),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SkeletonCard(
                  style: SkeletonCardStyle.cream,
                  radius: 28,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        SkeletonPill(width: 170, height: 28),
                        Spacer(),
                        ShimmerBox(width: 120, height: 96, radius: 20),
                        SizedBox(height: 18),
                        ShimmerBox(width: 230, height: 14),
                        Spacer(),
                        SkeletonPill(width: 230, height: 38),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      );
}
