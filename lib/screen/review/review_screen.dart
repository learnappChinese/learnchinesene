import 'package:flutter/material.dart';
import 'widget/review_word_item.dart';
import '../../core/widgets/bottom_action_bar.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/primary_button.dart';
import '../quiz/quiz_screen.dart';
import '../word_detail/word_detail_screen.dart';
import 'controller/review_controller.dart';
import '../../core/models/word.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final ReviewController controller;

  @override
  void initState() {
    super.initState();
    // The existing GetX route owns this registration.
    controller = Get.isRegistered<ReviewController>()
        ? Get.find<ReviewController>()
        : Get.put(ReviewController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ôn lại từ sai',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _buildReviewContent(context),
    );
  }

  Widget _buildReviewActions(List<Word> words) {
    return BottomActionBar(
        child: PrimaryButton(
      label: 'Bắt đầu ôn tập',
      icon: Icons.quiz_rounded,
      onPressed: () => Get.to(
        () => const QuizScreen(),
        arguments: {'unitTitle': 'Ôn tập', 'reviewWords': words},
      ),
    ));
  }

  Widget _buildReviewContent(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final words = controller.words;
      if (words.isEmpty) {
        return const EmptyStateWidget(
          icon: Icons.verified_rounded,
          title: 'Bạn đã ôn xong!',
          message: 'Hiện không còn từ khó nào cần ôn lại.',
        );
      }
      return Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: ResponsiveHelper.contentMaxWidth(context)),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    ResponsiveHelper.horizontalPadding(context),
                    8,
                    ResponsiveHelper.horizontalPadding(context),
                    22,
                  ),
                  children: [
                    _ReviewHero(count: words.length),
                    const SizedBox(height: 20),
                    for (final word in words)
                      ReviewWordItem(
                          key: ValueKey(word.id),
                          word: word,
                          onTap: () => Get.to(() => const WordDetailScreen(),
                              arguments: {"word": word})),
                  ],
                ),
              ),
            ),
          ),
          _buildReviewActions(words),
        ],
      );
    });
  }
}

class _ReviewHero extends StatelessWidget {
  const _ReviewHero({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.redDark, AppColors.red],
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            const Icon(Icons.psychology_alt_rounded,
                color: Colors.white, size: 38),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count từ cần củng cố',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ôn tập có trọng tâm giúp bạn biến lỗi sai thành kiến thức vững chắc.',
                    style: TextStyle(color: Colors.white70, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
