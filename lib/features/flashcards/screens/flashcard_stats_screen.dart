import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/game_visual_tokens.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Thống kê ôn tập',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: GameVisualTokens.primaryGreen,
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Thẻ chỉ số tổng quan
            _buildOverviewRow(),
            const SizedBox(height: 18),

            // 2. Phân bổ xếp hạng (Again, Hard, Good, Easy)
            _buildRatingsBreakdown(),
            const SizedBox(height: 18),

            // 3. Dự báo số thẻ đến hạn (Forecast)
            _buildForecastCard(),
            const SizedBox(height: 18),

            // 4. Lịch học Heatmap
            _buildHeatmapCard(),
            const SizedBox(height: 24),
          ],
        );
      }),
    );
  }

  Widget _buildOverviewRow() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricBox(
            title: 'LƯỢT ÔN',
            value: '${controller.totalReviews.value}',
            icon: '🔄',
            color: GameVisualTokens.primaryGreenDark,
            bgColor: GameVisualTokens.primaryGreenSoft,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricBox(
            title: 'ĐỘ NHỚ ĐÚNG',
            value: '${controller.retentionRate.value.toStringAsFixed(1)}%',
            icon: '🎯',
            color: const Color(0xFFD97706),
            bgColor: const Color(0xFFFEF3C7),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricBox({
    required String title,
    required String value,
    required String icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
              Text(icon, style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: GameVisualTokens.ink,
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

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PHÂN BỔ ĐÁNH GIÁ (FSRS RATINGS)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          _buildRatingBar('Quên (Again)', again, total, const Color(0xFFEF4444)),
          const SizedBox(height: 8),
          _buildRatingBar('Khó (Hard)', hard, total, const Color(0xFFF97316)),
          const SizedBox(height: 8),
          _buildRatingBar('Nhớ (Good)', good, total, GameVisualTokens.primaryGreen),
          const SizedBox(height: 8),
          _buildRatingBar('Dễ (Easy)', easy, total, const Color(0xFF0284C7)),
        ],
      ),
    );
  }

  Widget _buildRatingBar(String label, int count, int total, Color color) {
    final ratio = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: GameVisualTokens.ink,
              ),
            ),
            Text(
              '$count lượt (${(ratio * 100).toInt()}%)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildForecastCard() {
    final forecast = controller.forecastData;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DỰ BÁO LỊCH ÔN (DUE FORECAST)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          if (forecast.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Chưa có thẻ nào được lên lịch trong những ngày tới.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            )
          else
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: forecast.length,
                itemBuilder: (context, index) {
                  final row = forecast[index];
                  final date = '${row['due_date']}'.substring(5); // MM-dd
                  final count = (row['card_count'] as num?)?.toInt() ?? 0;

                  return Container(
                    width: 60,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: GameVisualTokens.primaryGreenDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'thẻ',
                          style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                        ),
                        const Spacer(),
                        Text(
                          date,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeatmapCard() {
    final heatmap = controller.heatmapData;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LỊCH SỬ ÔN TẬP GẦN ĐÂY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          if (heatmap.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Bắt đầu học Flashcard hôm nay để ghi lại chuỗi ôn tập nhé!',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: heatmap.map((day) {
                final count = (day['total_reviews'] as num?)?.toInt() ?? 0;
                final date = day['review_date'] as String? ?? '';
                final Color cellColor = count == 0
                    ? const Color(0xFFF1F5F9)
                    : count < 5
                        ? GameVisualTokens.primaryGreenLight.withValues(alpha: 0.4)
                        : count < 15
                            ? GameVisualTokens.primaryGreenLight
                            : GameVisualTokens.primaryGreenDark;

                return Tooltip(
                  message: '$date: $count thẻ',
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: cellColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
