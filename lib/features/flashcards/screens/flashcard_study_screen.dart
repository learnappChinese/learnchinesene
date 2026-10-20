import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/game_visual_tokens.dart';
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: GameVisualTokens.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Obx(() {
          final current = controller.currentItem.value;
          if (current == null) return const Text('Ôn tập Flashcard');
          return Text(
            'Thẻ ${controller.reviewedCount.value + 1} / ${controller.reviewedCount.value + controller.remainingCount.value}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: GameVisualTokens.ink,
            ),
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded, color: GameVisualTokens.primaryGreenDark),
            tooltip: 'Phát âm từ vựng',
            onPressed: controller.playAudio,
          ),
        ],
      ),
      body: LearningSceneBackground(
        theme: LearningSceneTheme.bambooVillage,
        child: SafeArea(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(
                  color: GameVisualTokens.primaryGreen,
                ),
              );
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
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE2E8F0),
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
