import 'package:flutter/material.dart';
import 'widget/quiz_content.dart';
import 'package:get/get.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../review/review_screen.dart';
import 'controller/quiz_controller.dart';
import '../../core/widgets/learning_scaffold.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, this.controller});

  final QuizController? controller;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final QuizController controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      controller = widget.controller!;
    } else if (Get.isRegistered<QuizController>()) {
      controller = Get.find<QuizController>();
    } else {
      controller = Get.put(QuizController());
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController && Get.isRegistered<QuizController>()) {
      Get.delete<QuizController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: 'Luyện tập nhanh',
      body: _buildQuizContent(context),
    );
  }

  Widget _buildQuizContent(BuildContext context) {
    return Obx(() {
      if (controller.loading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.questions.isEmpty) {
        return const EmptyStateWidget(
          icon: Icons.quiz_outlined,
          title: 'Chưa đủ từ để kiểm tra',
          message: 'Hoạt động này cần ít nhất bốn đáp án khác nhau.',
        );
      }
      if (controller.isCompleting.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.complete.value) {
        return QuizResultView(
            result: controller.learningResult.value!,
            onRetry: controller.load,
            onReview: () => Get.off(() => const ReviewScreen()));
      }
      return QuizQuestionView(
          q: controller.questions[controller.index.value],
          index: controller.index.value,
          questionCount: controller.questions.length,
          selected: controller.selected.value,
          onPlayAudio: () => controller
              .playAudio(controller.questions[controller.index.value].audioUrl),
          onChoose: (answer) => controller.choose(
              controller.questions[controller.index.value], answer),
          onNext: controller.next);
    });
  }
}
