import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/theme/game_visual_tokens.dart';
import '../../review/model/review_item.dart';
import '../model/home_journey.dart';
import 'home_green_button.dart';
import 'shared_tab_background.dart';
import 'tab_card_text.dart';
import 'tab_header.dart';

class HomeLearningTab extends StatelessWidget {
  const HomeLearningTab({
    super.key,
    required this.onPractice,
    required this.onVocabulary,
    required this.onLessons,
    required this.onConversation,
    this.onSections,
    this.journey,
    this.reviewSummary,
    this.onLearningPath,
    this.onReview,
    this.onHanzi,
    this.onSpeaking,
    this.onFlashcards,
    this.onHsk,
  });

  final VoidCallback onPractice, onVocabulary, onLessons, onConversation;
  final VoidCallback? onSections;
  final HomeJourney? journey;
  final ReviewSummary? reviewSummary;
  final VoidCallback? onLearningPath;
  final VoidCallback? onReview;
  final VoidCallback? onHanzi;
  final VoidCallback? onSpeaking;
  final VoidCallback? onFlashcards;
  final VoidCallback? onHsk;

  @override
  Widget build(BuildContext context) {
    final bottomSpace = 122.w + MediaQuery.viewPaddingOf(context).bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: SharedTabBackground(
        child: Column(children: [
          const TabHeader(
            icon: Icons.menu_book_rounded,
            title: 'Học tập',
            subtitle: 'Bản đồ ải và luyện kỹ năng',
          ),
          Expanded(
            child: SingleChildScrollView(
              key: const PageStorageKey('home-learning-scroll'),
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 4.w, 16.w, bottomSpace),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStageMapHero(context),
                  if (reviewSummary != null && reviewSummary!.totalDue > 0) ...[
                    SizedBox(height: 12.w),
                    _buildReviewBanner(context),
                  ],
                  SizedBox(height: 16.w),
                  _buildQuickSkillsGrid(context),
                  SizedBox(height: 16.w),
                  _buildCurriculumCards(context),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildStageMapHero(BuildContext context) {
    final j = journey;
    final worldNum = j?.worldNumber ?? 1;
    final chapterNum = j?.chapterNumber ?? 1;
    final title = j?.chapterTitle ?? 'Khởi đầu học tiếng Trung';
    final nextMission = j?.missionTitle ?? 'Ải 1: Phát âm & Chào hỏi';
    final progress = j?.chapterProgress ?? 0.0;
    final completed = j?.completedMissions ?? 0;
    final total = j?.totalMissions ?? 1;
    final actionLabel = j?.nextAction?.label.trim().isNotEmpty == true
        ? j!.nextAction!.label.trim().toUpperCase()
        : 'VÀO BẢN ĐỒ ẢI';
    const ink = Color(0xFF342E10);
    const brown = Color(0xFF57300A);
    const muted = Color(0xFF5D5C54);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFDF6), Color(0xFFFFF1D6)],
        ),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white, width: 4.w),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24635D3B),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -4.w,
            top: -30.w,
            child: Text(
              '学',
              style: TextStyle(
                fontSize: 130.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF8B5E1A).withValues(alpha: .06),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 4.w),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              GameVisualTokens.primaryGreenLight,
                              GameVisualTokens.primaryGreen,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'VÙNG $worldNum • BÀI $chapterNum',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (j != null && j.stars > 0)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 3.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: const Color(0xFFF1E6CF)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: GameVisualTokens.gold, size: 16),
                            SizedBox(width: 2.w),
                            Text(
                              '${j.stars}',
                              style: TextStyle(
                                color: brown,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 10.w),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 4.w),
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'Mục tiêu kế tiếp: '),
                    TextSpan(
                      text: nextMission,
                      style: const TextStyle(
                        color: GameVisualTokens.primaryGreenDark,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: muted,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12.w),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: (progress.isFinite ? progress : 0.0)
                              .clamp(0.0, 1.0),
                          backgroundColor: const Color(0xFFF1E6CF),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              GameVisualTokens.primaryGreen),
                          minHeight: 9.w,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      '$completed/$total ải',
                      style: TextStyle(
                        color: GameVisualTokens.primaryGreenDark,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.w),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .8),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: const Color(0xFFF1E6CF)),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/characters/home_panda_peek.png',
                        width: 36.w,
                        height: 36.w,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          j?.nextAction?.description.trim().isNotEmpty == true
                              ? j!.nextAction!.description.trim()
                              : 'Panda đã đánh dấu ải phù hợp nhất với tiến độ hiện tại của bạn.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: muted,
                            fontSize: 11.sp,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.w),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: HomeGreenButton(
                        label: actionLabel,
                        onTap: onLearningPath ?? onPractice,
                        playIcon: true,
                      ),
                    ),
                    if (onSections != null) ...[
                      SizedBox(width: 8.w),
                      Expanded(
                        flex: 2,
                        child: _OutlineGreenButton(
                          label: 'BẢN ĐỒ THẾ GIỚI',
                          icon: Icons.map_rounded,
                          onTap: onSections!,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewBanner(BuildContext context) {
    final count = reviewSummary!.totalDue;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
            color: GameVisualTokens.imperialGold.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: GameVisualTokens.crimson.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: GameVisualTokens.crimson,
              size: 22,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cần ôn tập $count mục hôm nay',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: GameVisualTokens.ink,
                  ),
                ),
                Text(
                  'Củng cố trí nhớ ngắt quãng (Spaced Repetition)',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: GameVisualTokens.muted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          HomeGreenButton(
            label: 'Ôn ngay',
            chevronIcon: true,
            color: GameVisualTokens.crimson,
            onTap: onReview ?? onPractice,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSkillsGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Luyện kỹ năng nhanh'),
        SizedBox(height: 8.w),
        Row(
          children: [
            Expanded(
              child: _SkillButton(
                icon: Icons.draw_rounded,
                title: 'Viết chữ Hán',
                subtitle: 'Bộ thủ & nét',
                color: GameVisualTokens.jade,
                bgColor: const Color(0xFFF0FDF4),
                onTap: onHanzi ?? onPractice,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _SkillButton(
                icon: Icons.record_voice_over_rounded,
                title: 'Luyện phát âm',
                subtitle: 'Thanh điệu chuẩn',
                color: GameVisualTokens.orange,
                bgColor: const Color(0xFFFFF7ED),
                onTap: onSpeaking ?? onPractice,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.w),
        Row(
          children: [
            Expanded(
              child: _SkillButton(
                icon: Icons.style_rounded,
                title: 'Flashcards',
                subtitle: 'Ghi nhớ từ vựng',
                color: GameVisualTokens.blue,
                bgColor: const Color(0xFFEFF6FF),
                onTap: onFlashcards ?? onPractice,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _SkillButton(
                icon: Icons.fitness_center_rounded,
                title: 'Luyện tập chung',
                subtitle: 'Các dạng bài tập',
                color: const Color(0xFF7C3AED),
                bgColor: const Color(0xFFF5F3FF),
                onTap: onPractice,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurriculumCards(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Chuyên đề & mở rộng'),
        SizedBox(height: 8.w),
        _LearningCard(
          title: 'Bản đồ thế giới & HSK',
          subtitle: 'Khám phá thế giới, các vùng đất và bài học HSK',
          asset: 'assets/images/backgrounds/learning_vocabulary.png',
          color: const Color(0xFF25BA81),
          background: const Color(0xFFF0FCFB),
          height: 120.w,
          onTap: onVocabulary,
        ),
        if (FeatureFlags.enableAi) ...[
          SizedBox(height: 8.w),
          _LearningCard(
            title: 'Bài học chuyên đề AI',
            subtitle: 'Tự động biên soạn bài học và ngữ pháp',
            asset: 'assets/images/backgrounds/learning_lessons.png',
            color: const Color(0xFFFF8809),
            background: const Color(0xFFFFFAEC),
            height: 120.w,
            onTap: onLessons,
          ),
          SizedBox(height: 8.w),
          _LearningCard(
            title: 'Hội thoại tình huống AI',
            subtitle: 'Luyện giao tiếp qua các chủ đề thông minh',
            asset: 'assets/images/backgrounds/learning_conversation.png',
            color: const Color(0xFF168CFF),
            background: const Color(0xFFF4F7FF),
            height: 120.w,
            onTap: onConversation,
          ),
        ],
      ],
    );
  }
}

class _SkillButton extends StatelessWidget {
  const _SkillButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14635D3B),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: const BorderSide(color: Color(0xFFF1E6CF)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.w),
            child: Row(
              children: [
                Container(
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: GameVisualTokens.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: GameVisualTokens.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LearningCard extends StatelessWidget {
  const _LearningCard({
    required this.title,
    required this.subtitle,
    required this.asset,
    required this.color,
    required this.background,
    required this.height,
    required this.onTap,
  });

  final String title, subtitle, asset;
  final Color color, background;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20.r);
    return Container(
      height: height,
      decoration: BoxDecoration(borderRadius: radius, boxShadow: [
        BoxShadow(
            color: const Color(0x226B662A),
            blurRadius: 10.r,
            offset: Offset(0, 4.w)),
      ]),
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: Colors.white, width: 3.w)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                      children: [
                        Positioned.fill(
                          child: ExcludeSemantics(
                            child: Ink.image(
                                image: AssetImage(asset), fit: BoxFit.fill),
                          ),
                        ),
                        // Làm dịu nền sau chữ để tiêu đề/mô tả rõ ràng.
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    background.withValues(alpha: 0),
                                    background.withValues(alpha: 0),
                                    background.withValues(alpha: .95),
                                    background.withValues(alpha: .92),
                                  ],
                                  stops: const [0, .27, .4, 1],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          constraints: BoxConstraints(minHeight: height),
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.fromLTRB(
                              constraints.maxWidth * .38, 12.w, 48.w, 12.w),
                          child: TabCardText(
                            title: title,
                            description: subtitle,
                            titleColor: Color.lerp(color, Colors.black, .45)!,
                            descriptionColor: const Color(0xFF3B362A),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          bottom: 0,
                          right: 14.w,
                          width: 32.w,
                          child: IgnorePointer(
                            child: ExcludeSemantics(
                              child: Center(
                                child: Container(
                                  width: 32.w,
                                  height: 32.w,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                          color: color.withValues(alpha: .15),
                                          blurRadius: 6.r,
                                          offset: Offset(0, 3.w)),
                                    ],
                                  ),
                                  child: Icon(Icons.chevron_right_rounded,
                                      color: color, size: 24.sp),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ))),
      ),
    );
  }
}

class _OutlineGreenButton extends StatelessWidget {
  const _OutlineGreenButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(19.w);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: GameVisualTokens.primaryGreen, width: 1.5.w),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 41.w,
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon,
                        size: 17.w, color: GameVisualTokens.primaryGreen),
                    SizedBox(width: 5.w),
                    Text(
                      label,
                      style: TextStyle(
                        color: GameVisualTokens.primaryGreenDark,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4.w,
          height: 16.w,
          decoration: BoxDecoration(
            color: GameVisualTokens.primaryGreen,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF342E10),
          ),
        ),
      ],
    );
  }
}
