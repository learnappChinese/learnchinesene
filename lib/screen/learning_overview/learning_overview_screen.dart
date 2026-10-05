import 'package:flutter/material.dart';
import 'widget/learning_activity_tile.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/responsive/responsive_layout.dart';
import '../quiz/quiz_screen.dart';
import '../speaking/speaking_screen.dart';
import '../word_list/word_list_screen.dart';
import 'controller/learning_overview_controller.dart';

class LearningOverviewScreen extends StatefulWidget {
  const LearningOverviewScreen({super.key});

  @override
  State<LearningOverviewScreen> createState() => _LearningOverviewScreenState();
}

class _LearningOverviewScreenState extends State<LearningOverviewScreen> {
  late final LearningOverviewController controller;

  @override
  void initState() {
    super.initState();
    // The existing GetX route owns this registration.
    controller = Get.isRegistered<LearningOverviewController>()
        ? Get.find<LearningOverviewController>()
        : Get.put(LearningOverviewController());
  }

  void _go(Widget screen, int unitId, String title) {
    Get.to(
      () => screen,
      arguments: {'unitId': unitId, 'unitTitle': title},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: _buildActivities(context),
    );
  }

  Widget _buildMetric(IconData i, String t) => Expanded(
        child: Row(
          children: [
            Icon(i, color: Colors.white70, size: 17),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                t,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildLessonHeader(int words, int examples) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.redDark, AppColors.red],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BÀI HỌC TIẾP THEO',
            style: TextStyle(
              color: Color(0xCCFFFFFF),
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            controller.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _buildMetric(Icons.style_rounded, '$words từ'),
              const SizedBox(width: 18),
              _buildMetric(
                Icons.chat_bubble_outline_rounded,
                '$examples câu mẫu',
              ),
              const SizedBox(width: 18),
              _buildMetric(
                Icons.schedule_rounded,
                '${(words * .7).ceil()} phút',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivities(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final m = controller.metrics;
      final words = m['words'] ?? 0;
      final examples = m['examples'] ?? 0;

      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: ResponsiveHelper.contentMaxWidth(context)),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              ResponsiveHelper.horizontalPadding(context),
              0,
              ResponsiveHelper.horizontalPadding(context),
              32,
            ),
            children: [
              _buildLessonHeader(words, examples),
              const SizedBox(height: 26),
              const Text(
                'Chọn hoạt động',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              LearningActivityTile(
                  icon: Icons.style_rounded,
                  title: 'Học từ vựng',
                  subtitle: 'Ghi nhớ từ mới qua thẻ học trực quan',
                  color: AppColors.red,
                  onTap: () => _go(const WordListScreen(), controller.unitId,
                      controller.title)),
              LearningActivityTile(
                  icon: Icons.quiz_rounded,
                  title: 'Bắt đầu kiểm tra',
                  subtitle: 'Luyện nghĩa, pinyin và nghe hiểu',
                  color: AppColors.orange,
                  onTap: () => _go(
                      const QuizScreen(), controller.unitId, controller.title)),
              LearningActivityTile(
                  icon: Icons.mic_rounded,
                  title: 'Luyện phát âm',
                  subtitle: 'Nhận phản hồi phát âm ngay lập tức',
                  color: AppColors.success,
                  onTap: () => _go(const SpeakingScreen(), controller.unitId,
                      controller.title)),
            ],
          ),
        ),
      );
    });
  }
}
