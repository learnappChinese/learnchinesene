import 'package:flutter/material.dart';
import 'widget/hsk_exam_content.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/learning_scene_background.dart';
import 'controller/hsk_exam_controller.dart';

class HskExamScreen extends StatefulWidget {
  const HskExamScreen({super.key});

  @override
  State<HskExamScreen> createState() => _HskExamScreenState();
}

class _HskExamScreenState extends State<HskExamScreen> {
  late final HskExamController controller;

  @override
  void initState() {
    super.initState();
    // GetX retains the existing route ownership and cleanup.
    controller = Get.isRegistered<HskExamController>()
        ? Get.find<HskExamController>()
        : Get.put(HskExamController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Thi thử HSK với AI',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [_buildExamAction()],
      ),
      body: LearningSceneBackground(
        theme: LearningSceneTheme.imperialCity,
        child: SafeArea(
          child: _buildExamContent(),
        ),
      ),
    );
  }

  Widget _buildExamAction() {
    return Obx(() {
      if (controller.examState.value == 'started') {
        return TextButton(
          onPressed: controller.submitExam,
          child: const Text('Nộp bài',
              style:
                  TextStyle(color: AppColors.red, fontWeight: FontWeight.bold)),
        );
      }
      if (controller.examState.value == 'submitted') {
        return TextButton(
          onPressed: controller.reset,
          child: const Text('Làm lại', style: TextStyle(color: AppColors.red)),
        );
      }
      return const SizedBox();
    });
  }

  Widget _buildExamContent() {
    return Obx(() {
      final state = controller.examState.value;

      if (state == 'loading') {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang khởi tạo đề thi thử...',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: AppColors.muted)),
            ],
          ),
        );
      }

      if (state == 'submitting') {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('AI đang chấm điểm và đánh giá...',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: AppColors.muted)),
            ],
          ),
        );
      }

      if (state == 'notStarted') {
        return HskExamSetup(
            selectedLevel: controller.selectedLevel.value,
            onLevelChanged: (level) => controller.selectedLevel.value = level,
            onStart: controller.generateExam);
      }

      if (state == 'submitted') {
        return HskExamResult(
            score: controller.score.value,
            questions: controller.questions.toList(),
            answers: controller.userAnswers.toList(),
            analysisLoading: controller.analysisLoading.value,
            assessment: controller.overallAssessment.value,
            strengths: controller.strengths.toList(),
            weaknesses: controller.weaknesses.toList(),
            suggestions: controller.studySuggestions.toList());
      }

      return HskExamQuestions(
          selectedLevel: controller.selectedLevel.value,
          questions: controller.questions.toList(),
          answers: controller.userAnswers.toList(),
          onSpeak: controller.speak,
          onSelect: controller.selectOption);
    });
  }
}
