import 'package:flutter/material.dart';
import 'widget/mastered_words_summary.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/widgets/stat_card.dart';
import 'controller/stats_controller.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late final StatsController controller;

  @override
  void initState() {
    super.initState();
    // The existing GetX route owns this registration.
    controller = Get.isRegistered<StatsController>()
        ? Get.find<StatsController>()
        : Get.put(StatsController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tiến độ của bạn',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildStatsGrid(Map<String, num> stats, num accuracy) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      children: [
        StatCard(
          icon: Icons.auto_stories_rounded,
          value: '${stats['learned']?.toInt() ?? 0}',
          label: 'Từ đã học',
        ),
        StatCard(
          icon: Icons.gps_fixed_rounded,
          value: '${accuracy.round()}%',
          label: 'Độ chính xác',
          color: AppColors.success,
        ),
        StatCard(
          icon: Icons.error_outline_rounded,
          value: '${stats['wrong']?.toInt() ?? 0}',
          label: 'Câu trả lời sai',
          color: AppColors.error,
        ),
        StatCard(
          icon: Icons.mic_rounded,
          value: '${(stats['speakingAverage'] ?? 0).round()}%',
          label: 'Điểm phát âm',
          color: AppColors.orange,
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final s = controller.stats;
      final correct = s['correct'] ?? 0;
      final wrong = s['wrong'] ?? 0;
      final accuracy =
          correct + wrong == 0 ? 0 : correct / (correct + wrong) * 100;
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: ResponsiveHelper.contentMaxWidth(context)),
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.horizontalPadding(context),
              vertical: 24,
            ),
            children: [
              MasteredWordsSummary(count: s['mastered']?.toInt() ?? 0),
              const SizedBox(height: 18),
              _buildStatsGrid(s, accuracy),
              const SizedBox(height: 22),
              const Text(
                'Tiếp tục cố gắng',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Những buổi học ngắn và đều đặn là cách tốt nhất để ghi nhớ từ vựng.',
                style: TextStyle(color: AppColors.muted, height: 1.5),
              ),
            ],
          ),
        ),
      );
    });
  }
}
