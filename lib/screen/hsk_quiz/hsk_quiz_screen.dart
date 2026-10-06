import 'controller/hsk_quiz_controller.dart';
import 'package:flutter/material.dart';
import 'widget/hsk_quiz_content.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/gemini_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/responsive/responsive_layout.dart';
import 'package:get/get.dart';
import '../subscription/controller/subscription_controller.dart';
import '../../core/helper/upgrade_dialog_helper.dart';

class HskQuizScreen extends StatefulWidget {
  const HskQuizScreen({super.key});

  @override
  State<HskQuizScreen> createState() => _HskQuizScreenState();
}

class _HskQuizScreenState extends State<HskQuizScreen> {
  int _selectedLevel = 1;
  static int _nextControllerId = 0;
  late final String _controllerTag;
  late final HskQuizController controller;
  late final Worker _errorWorker;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'hsk-quiz-${_nextControllerId++}';
    controller = Get.put(
        HskQuizController(
            loadVocabulary: (level) =>
                Get.find<GeminiService>().fetchHskVocabulary(level, count: 40)),
        tag: _controllerTag);
    _errorWorker = ever<String?>(controller.error, (message) {
      if (!mounted || message == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.error));
    });
  }

  @override
  void dispose() {
    _errorWorker.dispose();
    Get.delete<HskQuizController>(tag: _controllerTag);
    super.dispose();
  }

  Future<void> _generateQuestions() => controller.generate(_selectedLevel);

  Future<void> _playTts(String text) {
    return Get.find<TtsService>().speakChinese(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trắc nghiệm từ vựng HSK',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _buildQuizViewport(context),
    );
  }

  Widget _buildBody() {
    switch (controller.state.value) {
      case QuizState.setup:
        return HskQuizSetup(
            selectedLevel: _selectedLevel,
            unlockedLevels: {
              for (var level = 1; level <= 6; level++)
                if (Get.find<SubscriptionController>().isLevelUnlocked(level))
                  level
            },
            onLevelSelected: _selectLevel,
            onStart: _generateQuestions);
      case QuizState.playing:
        return HskQuizQuestionView(
            questions: controller.questions.toList(),
            currentIndex: controller.currentIndex.value,
            score: controller.score.value,
            selectedAnswer: controller.selectedAnswer.value,
            onAnswer: controller.answer,
            onPlayAudio: _playTts,
            onNext: controller.nextQuestion);
      case QuizState.finished:
        return HskQuizResultView(
            questions: controller.questions.toList(),
            userAnswers: controller.userAnswers.toList(),
            score: controller.score.value,
            selectedLevel: _selectedLevel,
            onRetry: _generateQuestions,
            onChangeLevel: () => controller.state.value = QuizState.setup);
    }
  }

  void _selectLevel(int level) {
    final isUnlocked =
        Get.find<SubscriptionController>().isLevelUnlocked(level);
    if (isUnlocked) {
      setState(() {
        _selectedLevel = level;
      });
    } else {
      UpgradeDialogHelper.showUpgradeDialog(
        context: context,
        title: 'Mở khóa Trắc nghiệm HSK $level',
        message:
            'Bài trắc nghiệm cấp độ HSK $level yêu cầu nâng cấp gói cước để truy cập.',
        benefits: level <= 3
            ? ['Luyện tập trắc nghiệm HSK 1-3', 'Lưu tiến độ trên đám mây']
            : [
                'Luyện tập trắc nghiệm HSK 1-6',
                'Hội thoại AI không giới hạn',
                'Thi thử HSK với AI'
              ],
      );
    }
  }

  Widget _buildQuizViewport(BuildContext context) {
    final maxWidth = ResponsiveHelper.contentMaxWidth(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Obx(() => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : _buildBody()),
      ),
    );
  }
}
