import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'home_illustrated_card.dart';
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
    final scale = 1.w;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: SharedTabBackground(
        child: Column(
          children: [
            const TabHeader(
              icon: Icons.bar_chart_rounded,
              title: 'Tiến độ &',
              accentTitle: 'Đánh giá',
              subtitle: 'Theo dõi hành trình học tập của bạn',
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const PageStorageKey('home-progress-scroll'),
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w,
                    122.w + MediaQuery.viewPaddingOf(context).bottom),
                child: Column(
                  children: [
                    HomeIllustratedCard(
                      title: 'Thống kê chi tiết',
                      subtitle:
                          'Theo dõi tiến trình và số liệu học tập của bạn',
                      asset: 'progress_stats',
                      ink: const Color(0xFF521A0B),
                      accent: const Color(0xFFFF570A),
                      background: const Color(0xFFFFF1CA),
                      minHeight: 128.w,
                      scale: scale,
                      onTap: onStats,
                    ),
                    SizedBox(height: 8.w),
                    HomeIllustratedCard(
                      title: 'Thi thử HSK với AI',
                      subtitle:
                          'Chấm điểm và nhận xét chi tiết từ giáo viên AI',
                      asset: 'progress_exam',
                      ink: const Color(0xFF034651),
                      accent: const Color(0xFF16AD00),
                      background: const Color(0xFFCCF5F7),
                      minHeight: 128.w,
                      scale: scale,
                      onTap: onExam,
                    ),
                    SizedBox(height: 8.w),
                    HomeIllustratedCard(
                      title: 'Lịch sử & Phân tích',
                      subtitle: 'Xem lại các bản dịch,\n'
                          'hội thoại và kết quả thi',
                      asset: 'progress_history',
                      ink: const Color(0xFF092A70),
                      accent: const Color(0xFF0879FF),
                      background: const Color(0xFFD9EEFF),
                      minHeight: 128.w,
                      scale: scale,
                      onTap: onHistory,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
