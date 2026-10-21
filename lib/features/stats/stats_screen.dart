import 'package:flutter/material.dart';
import '../../core/widgets/learning_scene_background.dart';
import '../../core/widgets/app_shimmer.dart';
import 'widget/mastered_words_summary.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/widgets/stat_card.dart';
import 'controller/stats_controller.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, this.controller});

  final StatsController? controller;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late final StatsController controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      controller = widget.controller!;
    } else if (Get.isRegistered<StatsController>()) {
      controller = Get.find<StatsController>();
    } else {
      controller = Get.put(StatsController());
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController && Get.isRegistered<StatsController>()) {
      Get.delete<StatsController>();
    }
    super.dispose();
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
      body: SafeBottomArea(child: _buildBody(context)),
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
        return const _StatsSkeleton();
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

/// Khung đang tải khớp màn thống kê: thẻ tổng số từ, lưới 4 ô và lời nhắn.
class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) => AppShimmer(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: ResponsiveHelper.contentMaxWidth(context)),
            child: ListView(
              physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.horizontalPadding(context),
                vertical: 24,
              ),
              children: [
                const SkeletonCard(
                  radius: 26,
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        ShimmerBox.circle(size: 42),
                        SizedBox(height: 12),
                        ShimmerBox(width: 70, height: 44, radius: 12),
                        SizedBox(height: 8),
                        ShimmerBox(width: 110, height: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                GridView(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 250,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.35,
                  ),
                  children: [
                    for (var i = 0; i < 4; i++)
                      const SkeletonCard(
                        radius: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ShimmerBox.circle(size: 36),
                            ShimmerBox(width: 56, height: 22),
                            ShimmerLine(widthFactor: .7, height: 11),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                const ShimmerBox(width: 160, height: 19),
                const SizedBox(height: 10),
                const ShimmerLine(height: 13),
                const SizedBox(height: 6),
                const ShimmerLine(widthFactor: .6, height: 13),
              ],
            ),
          ),
        ),
      );
}
