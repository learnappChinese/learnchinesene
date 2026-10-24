import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/game_visual_tokens.dart';
import '../../../core/widgets/adventure_quest_banner.dart';
import 'home_illustrated_card.dart';
import 'shared_tab_background.dart';
import 'tab_card_text.dart';
import 'tab_header.dart';

class HomePersonalTab extends StatelessWidget {
  const HomePersonalTab({
    super.key,
    required this.onProfile,
    required this.onDictionary,
    required this.onPrivacyPolicy,
  });

  final VoidCallback onProfile, onDictionary, onPrivacyPolicy;

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
              subtitle: 'Tài khoản và công cụ của bạn',
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const PageStorageKey('home-personal-scroll'),
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w,
                    122.w + MediaQuery.viewPaddingOf(context).bottom),
                child: Column(
                  children: [
                    AdventureQuestBanner(
                      eyebrow: 'Hồ sơ lữ khách',
                      title: 'Dấu ấn hành trình của bạn',
                      description:
                          'Quản lý hồ sơ và công cụ học tập trong cùng một trạm nghỉ.',
                      statusLabel: 'Tài khoản',
                      actionLabel: 'Mở hồ sơ',
                      onAction: onProfile,
                      accent: GameVisualTokens.crimson,
                      compact: true,
                    ),
                    if (FeatureFlags.enableAi) ...[
                      SizedBox(height: 10.w),
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
                    SizedBox(height: 10.w),
                    _PersonalLinkCard(
                      icon: Icons.privacy_tip_rounded,
                      title: 'Chính sách quyền riêng tư',
                      subtitle: 'Cách ứng dụng thu thập và bảo vệ dữ liệu',
                      accent: GameVisualTokens.crimson,
                      onTap: onPrivacyPolicy,
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

/// Thẻ liên kết gọn (không ảnh minh hoạ), cùng khung với [HomeIllustratedCard].
class _PersonalLinkCard extends StatelessWidget {
  const _PersonalLinkCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title, subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24.r);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.homeShadow,
            blurRadius: 15.w,
            offset: Offset(0, 7.w),
          ),
        ],
      ),
      child: Material(
        color: AppColors.homePage,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: Colors.white, width: 4.w),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.w, 12.w, 16.w),
            child: Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(icon, color: accent, size: 24.w),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: TabCardText(
                    title: title,
                    description: subtitle,
                    titleColor: AppColors.homeTitle,
                    descriptionColor: AppColors.homeBody,
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  width: 37.w,
                  height: 37.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: .13),
                        blurRadius: 8.w,
                        offset: Offset(0, 3.w),
                      ),
                    ],
                  ),
                  child: Icon(Icons.chevron_right_rounded,
                      color: accent, size: 32.w),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
