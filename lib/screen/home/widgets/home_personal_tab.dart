import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'home_illustrated_card.dart';
import 'shared_tab_background.dart';
import 'tab_header.dart';

class HomePersonalTab extends StatelessWidget {
  const HomePersonalTab({
    super.key,
    required this.onProfile,
    required this.onPremium,
    required this.onDictionary,
  });

  final VoidCallback onProfile, onPremium, onDictionary;

  @override
  Widget build(BuildContext context) {
    final scale = 1.w;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: SharedTabBackground(
        child: Column(
          children: [
            const TabHeader(
              icon: Icons.person_rounded,
              title: 'Cá nhân',
              subtitle: 'Quản lý tài khoản và công cụ cá nhân của bạn',
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const PageStorageKey('home-personal-scroll'),
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w,
                    122.w + MediaQuery.viewPaddingOf(context).bottom),
                child: Column(
                  children: [
                    HomeIllustratedCard(
                      title: 'Hồ sơ người dùng',
                      subtitle: 'Xem thông tin cá nhân\nvà xếp hạng',
                      asset: 'personal_profile',
                      ink: const Color(0xFF8C0E0D),
                      accent: const Color(0xFFE30D15),
                      background: const Color(0xFFFFE5EB),
                      minHeight: 128.w,
                      textStart: .43,
                      scale: scale,
                      onTap: onProfile,
                    ),
                    SizedBox(height: 8.w),
                    HomeIllustratedCard(
                      title: 'Nâng cấp Premium',
                      subtitle: 'Mở khóa toàn bộ tính\nnăng và bài học HSK',
                      asset: 'personal_premium',
                      ink: const Color(0xFF753407),
                      accent: const Color(0xFFFF8A00),
                      background: const Color(0xFFFFF0CD),
                      minHeight: 128.w,
                      textStart: .43,
                      scale: scale,
                      onTap: onPremium,
                    ),
                    SizedBox(height: 8.w),
                    HomeIllustratedCard(
                      title: 'Từ điển Việt ↔ Trung',
                      subtitle: 'Tra cứu từ bằng AI,\nhỗ trợ giọng nói',
                      asset: 'personal_dictionary',
                      ink: const Color(0xFF78300C),
                      accent: const Color(0xFFFF8A00),
                      background: const Color(0xFFFFEBD9),
                      minHeight: 128.w,
                      textStart: .43,
                      scale: scale,
                      onTap: onDictionary,
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
