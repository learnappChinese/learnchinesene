import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/responsive/responsive_layout.dart';
import '../../../core/theme/game_visual_tokens.dart';
import '../../stats/page/xp_history_screen.dart';
import '../controller/home_controller.dart';
import 'shared_tab_background.dart';
import 'tab_header.dart';

class HomeProgressTab extends StatelessWidget {
  const HomeProgressTab({
    super.key,
    required this.onStats,
    required this.onExam,
    required this.onHistory,
  });

  final VoidCallback onStats, onExam, onHistory;

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: SharedTabBackground(
        child: Column(
          children: [
            const TabHeader(
              icon: Icons.bar_chart_rounded,
              title: 'Tiến độ &',
              accentTitle: 'Hành trình',
              subtitle: 'Theo dõi năng lực tiếng Trung và lịch sử kinh nghiệm',
            ),
            Expanded(
              child: Obx(() {
                final todayXp = controller?.todayXp.value ?? 0;
                final lifetimeXp = controller?.lifetimeXp.value ?? 0;
                final streak = controller?.streak.value ?? 0;
                final mastery = controller?.masteryProfile.value;
                final overallPercent = mastery?.overallPercent ?? 0;
                final sevenDayData = controller?.sevenDayXp.toList() ?? [];
                final timeline = controller?.recentTimeline.toList() ?? [];

                return SingleChildScrollView(
                  key: const PageStorageKey('home-progress-scroll'),
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    16.w,
                    8.w,
                    16.w,
                    120.w + MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: ResponsiveHelper.contentMaxWidth(context),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryGrid(
                            todayXp: todayXp,
                            lifetimeXp: lifetimeXp,
                            streak: streak,
                            overallPercent: overallPercent,
                          ),
                          SizedBox(height: 18.w),
                          _buildWeeklyChart(sevenDayData),
                          SizedBox(height: 18.w),
                          _buildSkillMasterySection(mastery),
                          SizedBox(height: 18.w),
                          _buildRecentTimelineSection(timeline),
                          SizedBox(height: 18.w),
                          _buildQuickActions(context),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid({
    required int todayXp,
    required int lifetimeXp,
    required int streak,
    required int overallPercent,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10.w,
      mainAxisSpacing: 10.w,
      childAspectRatio: 1.6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _summaryCard(
          icon: '⚡',
          label: 'XP HÔM NAY',
          value: '+$todayXp XP',
          color: GameVisualTokens.imperialGold,
          bg: const Color(0xFFFEF3C7),
        ),
        _summaryCard(
          icon: '🔥',
          label: 'CHUỖI NGÀY',
          value: '$streak ngày',
          color: GameVisualTokens.crimson,
          bg: const Color(0xFFFEE2E2),
        ),
        _summaryCard(
          icon: '🎯',
          label: 'THÀNH THẠO',
          value: '$overallPercent%',
          color: GameVisualTokens.jade,
          bg: const Color(0xFFD1FAE5),
        ),
        _summaryCard(
          icon: '🏆',
          label: 'TỔNG TÍCH LŨY',
          value: '$lifetimeXp XP',
          color: const Color(0xFF6366F1),
          bg: const Color(0xFFE0E7FF),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String icon,
    required String label,
    required String value,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(icon, style: TextStyle(fontSize: 18.sp)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.w),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(List<Map<String, dynamic>> days) {
    final maxEntry = days.fold<int>(
      50,
      (max, e) {
        final xp = (e['xp'] as num?)?.toInt() ?? 0;
        return xp > max ? xp : max;
      },
    );

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: GameVisualTokens.imperialGold.withValues(alpha: 0.3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
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
                'HOẠT ĐỘNG 7 NGÀY GẦN NHẤT',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF475569),
                  letterSpacing: 0.8,
                ),
              ),
              const Icon(Icons.show_chart_rounded,
                  color: GameVisualTokens.imperialGold, size: 20),
            ],
          ),
          SizedBox(height: 16.w),
          SizedBox(
            height: 110.w,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((day) {
                final xp = (day['xp'] as num?)?.toInt() ?? 0;
                final label = '${day['dayLabel'] ?? ''}';
                final isToday = day['isToday'] == true;
                final heightFactor =
                    maxEntry > 0 ? (xp / maxEntry).clamp(0.06, 1.0) : 0.06;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (xp > 0)
                      Text(
                        '$xp',
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.bold,
                          color: isToday
                              ? GameVisualTokens.crimson
                              : const Color(0xFF64748B),
                        ),
                      ),
                    SizedBox(height: 4.w),
                    Container(
                      width: 24.w,
                      height: 70.w * heightFactor,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: isToday
                              ? [
                                  GameVisualTokens.crimson,
                                  GameVisualTokens.imperialGold
                                ]
                              : [
                                  GameVisualTokens.jade.withValues(alpha: 0.7),
                                  GameVisualTokens.jade,
                                ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    SizedBox(height: 6.w),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                        color: isToday
                            ? GameVisualTokens.crimson
                            : const Color(0xFF475569),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillMasterySection(dynamic mastery) {
    final vocabPct = mastery?.vocabularyPercent ?? 0;
    final listenPct = mastery?.listeningPercent ?? 0;
    final speakPct = mastery?.speakingPercent ?? 0;
    final hanziPct = mastery?.hanziPercent ?? 0;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: GameVisualTokens.jade.withValues(alpha: 0.3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KỸ NĂNG & ĐỘ THÀNH THẠO',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF475569),
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 12.w),
          _skillRow('Từ vựng (Vocabulary)', '📖', vocabPct,
              GameVisualTokens.imperialGold),
          _skillRow('Luyện nghe (Listening)', '🎧', listenPct,
              const Color(0xFF0284C7)),
          _skillRow(
              'Luyện nói (Speaking)', '🎙️', speakPct, GameVisualTokens.jade),
          _skillRow(
              'Chữ Hán (Hanzi)', '✍️', hanziPct, GameVisualTokens.crimson),
        ],
      ),
    );
  }

  Widget _skillRow(String name, String icon, int percent, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.w),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(icon, style: TextStyle(fontSize: 15.sp)),
                  SizedBox(width: 8.w),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 5.w),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8.w,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTimelineSection(List<Map<String, dynamic>> items) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
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
                'LỊCH SỬ HỌC TẬP GẦN ĐÂY',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF475569),
                  letterSpacing: 0.8,
                ),
              ),
              TextButton(
                onPressed: () => Get.to(() => const XpHistoryScreen()),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Xem tất cả',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: GameVisualTokens.jade,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.w),
          if (items.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.w),
              child: Center(
                child: Text(
                  'Chưa có lượt học nào gần đây. Hãy bắt đầu ngay!',
                  style: TextStyle(fontSize: 13.sp, color: const Color(0xFF94A3B8)),
                ),
              ),
            )
          else
            ...items.take(4).map((item) {
              final title = '${item['title'] ?? 'Bài học'}';
              final icon = '${item['icon'] ?? '⭐'}';
              final xp = (item['xpEarned'] as num?)?.toInt() ?? 0;
              final score = (item['score'] as num?)?.toInt() ?? 0;

              return Padding(
                padding: EdgeInsets.symmetric(vertical: 6.w),
                child: Row(
                  children: [
                    Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      alignment: Alignment.center,
                      child: Text(icon, style: TextStyle(fontSize: 16.sp)),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'Điểm: $score%',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (xp > 0)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 3.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: GameVisualTokens.imperialGold,
                          ),
                        ),
                        child: Text(
                          '+$xp XP',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        _actionTile(
          title: 'Sổ Lịch Sử Kinh Nghiệm (XP)',
          subtitle: 'Xem toàn bộ giao dịch XP đã ghi nhận vào hệ thống',
          icon: Icons.receipt_long_rounded,
          color: GameVisualTokens.imperialGold,
          onTap: () => Get.to(() => const XpHistoryScreen()),
        ),
        SizedBox(height: 10.w),
        _actionTile(
          title: 'Lịch Sử Dịch & Hội Thoại',
          subtitle: 'Tra cứu các bản dịch và bài hội thoại đã thực hiện',
          icon: Icons.history_edu_rounded,
          color: const Color(0xFF0284C7),
          onTap: onHistory,
        ),
        SizedBox(height: 10.w),
        _actionTile(
          title: 'Thi Thử HSK Với Giáo Viên AI',
          subtitle: 'Làm đề kiểm tra năng lực HSK 1-6 chuẩn hóa',
          icon: Icons.psychology_rounded,
          color: GameVisualTokens.jade,
          onTap: onExam,
        ),
      ],
    );
  }

  Widget _actionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.25)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22.sp),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2.w),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: const Color(0xFF94A3B8), size: 22.sp),
            ],
          ),
        ),
      ),
    );
  }
}
