import 'package:flutter/material.dart';
import '../../../core/widgets/app_shimmer.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/game_visual_tokens.dart';
import '../../../core/widgets/learning_scaffold.dart';
import '../../../core/widgets/learning_scene_background.dart';
import '../controller/flashcards_stats_controller.dart';

/// Màn hình Thống kê ghi nhớ và lịch sử ôn tập Flashcard (Heatmap, Forecast, Xếp hạng).
class FlashcardStatsScreen extends StatefulWidget {
  const FlashcardStatsScreen({super.key});

  @override
  State<FlashcardStatsScreen> createState() => _FlashcardStatsScreenState();
}

class _FlashcardStatsScreenState extends State<FlashcardStatsScreen> {
  late final FlashcardsStatsController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(FlashcardsStatsController());
  }

  @override
  void dispose() {
    Get.delete<FlashcardsStatsController>();
    super.dispose();
  }

  static const _line = Color(0xFFE8E1D6);
  static const _track = Color(0xFFEDE5D6);

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: 'Thống kê ôn tập',
      // Nội dung cuộn tràn xuống đáy, khoảng đệm nằm ở cuối danh sách.
      useSafeArea: false,
      body: LearningSceneBackground(
        theme: LearningSceneTheme.bambooVillage,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const _FlashcardStatsSkeleton();
          }

          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              24 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            children: [
              // 1. Thẻ chỉ số tổng quan
              _buildOverviewRow(),
              const SizedBox(height: 16),

              // 2. Phân bổ xếp hạng (Again, Hard, Good, Easy)
              _buildRatingsBreakdown(),
              const SizedBox(height: 16),

              // 3. Dự báo số thẻ đến hạn (Forecast)
              _buildForecastCard(),
              const SizedBox(height: 16),

              // 4. Lịch học Heatmap
              _buildHeatmapCard(),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildOverviewRow() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricBox(
            title: 'Lượt ôn',
            value: '${controller.totalReviews.value}',
            icon: Icons.replay_rounded,
            color: AppColors.homeGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricBox(
            title: 'Độ nhớ đúng',
            value: '${controller.retentionRate.value.toStringAsFixed(1)}%',
            icon: Icons.track_changes_rounded,
            color: AppColors.imperialGold,
          ),
        ),
      ],
    );
  }

  /// Ô chỉ số phẳng: icon màu trong vòng tròn, nhãn xám, số lớn.
  Widget _buildMetricBox({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 17, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.homeSubtitle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.homeTitle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14635D3B),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      );

  /// Thẻ nhóm: tiêu đề có icon tròn màu, nội dung bên dưới.
  Widget _buildSectionCard({
    required IconData icon,
    required Color color,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.homeInk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  /// Hộp trống nhẹ nhàng thay cho dòng chữ xám khi chưa có dữ liệu.
  Widget _buildEmptyNote(IconData icon, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2E8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.homeSubtitle),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.homeBody,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingsBreakdown() {
    final ratings = controller.ratingCounts;
    final again = ratings[1] ?? 0;
    final hard = ratings[2] ?? 0;
    final good = ratings[3] ?? 0;
    final easy = ratings[4] ?? 0;
    final total = again + hard + good + easy;

    return _buildSectionCard(
      icon: Icons.bar_chart_rounded,
      color: GameVisualTokens.blue,
      title: 'Phân bổ đánh giá',
      child: Column(
        children: [
          _buildRatingBar('Quên', again, total, GameVisualTokens.crimson),
          const SizedBox(height: 12),
          _buildRatingBar('Khó', hard, total, GameVisualTokens.orange),
          const SizedBox(height: 12),
          _buildRatingBar('Nhớ', good, total, AppColors.homeGreen),
          const SizedBox(height: 12),
          _buildRatingBar('Dễ', easy, total, GameVisualTokens.blue),
        ],
      ),
    );
  }

  Widget _buildRatingBar(String label, int count, int total, Color color) {
    final ratio = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.homeTitle,
                ),
              ),
            ),
            Text(
              '$count lượt · ${(ratio * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: Color.lerp(color, Colors.black, .15),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: _track,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildForecastCard() {
    final forecast = controller.forecastData;

    return _buildSectionCard(
      icon: Icons.event_rounded,
      color: AppColors.imperialGold,
      title: 'Dự báo lịch ôn',
      child: forecast.isEmpty
          ? _buildEmptyNote(
              Icons.event_available_rounded,
              'Chưa có thẻ nào được lên lịch trong những ngày tới.',
            )
          : SizedBox(
              height: 96,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: forecast.length,
                itemBuilder: (context, index) {
                  final row = forecast[index];
                  final date = '${row['due_date']}'.substring(5); // MM-dd
                  final count = (row['card_count'] as num?)?.toInt() ?? 0;

                  return Container(
                    width: 62,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDF6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _line, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: AppColors.homeGreenText,
                          ),
                        ),
                        const Text(
                          'thẻ',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.homeSubtitle,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          date,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.homeBody,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildHeatmapCard() {
    final heatmap = controller.heatmapData;

    return _buildSectionCard(
      icon: Icons.local_fire_department_rounded,
      color: GameVisualTokens.orange,
      title: 'Lịch sử ôn tập gần đây',
      child: heatmap.isEmpty
          ? _buildEmptyNote(
              Icons.style_rounded,
              'Bắt đầu học Flashcard hôm nay để ghi lại chuỗi ôn tập nhé!',
            )
          : Wrap(
              spacing: 6,
              runSpacing: 6,
              children: heatmap.map((day) {
                final count = (day['total_reviews'] as num?)?.toInt() ?? 0;
                final date = day['review_date'] as String? ?? '';
                final Color cellColor = count == 0
                    ? _track
                    : count < 5
                        ? AppColors.homeGreen.withValues(alpha: .35)
                        : count < 15
                            ? AppColors.homeGreen.withValues(alpha: .65)
                            : AppColors.homeGreen;

                return Tooltip(
                  message: '$date: $count thẻ',
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: cellColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

/// Khung đang tải khớp màn thống kê thẻ: hai ô tổng quan và ba thẻ nhóm.
class _FlashcardStatsSkeleton extends StatelessWidget {
  const _FlashcardStatsSkeleton();

  @override
  Widget build(BuildContext context) => AppShimmer(
        child: ListView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const Row(
              children: [
                Expanded(child: _MetricBoxSkeleton()),
                SizedBox(width: 12),
                Expanded(child: _MetricBoxSkeleton()),
              ],
            ),
            const SizedBox(height: 16),
            SkeletonCard(
              radius: 20,
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const _SectionTitleSkeleton(),
                  for (var i = 0; i < 4; i++) ...[
                    const SizedBox(height: 14),
                    const Row(
                      children: [
                        ShimmerBox.circle(size: 10),
                        SizedBox(width: 8),
                        ShimmerBox(width: 46, height: 14),
                        Spacer(),
                        ShimmerBox(width: 72, height: 12),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const ShimmerBox(height: 8, radius: 99),
                  ],
                ],
              ),
            ),
            for (var i = 0; i < 2; i++) ...[
              const SizedBox(height: 16),
              const SkeletonCard(
                radius: 20,
                padding: EdgeInsets.all(18),
                child: Column(
                  children: [
                    _SectionTitleSkeleton(),
                    SizedBox(height: 14),
                    ShimmerBox(height: 48, radius: 14),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
}

class _SectionTitleSkeleton extends StatelessWidget {
  const _SectionTitleSkeleton();

  @override
  Widget build(BuildContext context) => const Row(
        children: [
          ShimmerBox.circle(size: 28),
          SizedBox(width: 10),
          ShimmerBox(width: 150, height: 16),
        ],
      );
}

class _MetricBoxSkeleton extends StatelessWidget {
  const _MetricBoxSkeleton();

  @override
  Widget build(BuildContext context) => const SkeletonCard(
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerBox.circle(size: 30),
                SizedBox(width: 8),
                ShimmerBox(width: 64, height: 13),
              ],
            ),
            SizedBox(height: 12),
            ShimmerBox(width: 70, height: 26),
          ],
        ),
      );
}
