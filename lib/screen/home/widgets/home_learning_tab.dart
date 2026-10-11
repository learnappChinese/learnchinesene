import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/game_visual_tokens.dart';
import '../../review/model/review_item.dart';
import '../model/home_journey.dart';
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
            accentTitle: 'lộ trình',
            subtitle: 'Khám phá bản đồ ải và trung tâm luyện kỹ năng',
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

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GameVisualTokens.jadeDark,
            GameVisualTokens.jade,
          ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
            color: GameVisualTokens.gold.withValues(alpha: 0.6), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33064E3B),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(18.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.w),
                  decoration: BoxDecoration(
                    color: GameVisualTokens.imperialGold,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'VÙNG $worldNum • BÀI $chapterNum',
                      style: TextStyle(
                        color: Colors.black,
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        color: GameVisualTokens.gold, size: 18),
                    SizedBox(width: 2.w),
                    Text(
                      '${j.stars}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: 10.w),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          SizedBox(height: 4.w),
          Text(
            'Mục tiêu kế tiếp: $nextMission',
            style: TextStyle(
              color: GameVisualTokens.goldLight,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.w),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6.r),
                  child: LinearProgressIndicator(
                    value: (progress.isFinite ? progress : 0.0).clamp(0.0, 1.0),
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        GameVisualTokens.gold),
                    minHeight: 8.w,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                '$completed/$total ải',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.w),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onLearningPath ?? onPractice,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(0, 44.w),
                    backgroundColor: GameVisualTokens.gold,
                    foregroundColor: Colors.black,
                    elevation: 3,
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.explore_rounded,
                          color: Colors.black, size: 20),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'VÀO BẢN ĐỒ ẢI',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (onSections != null) ...[
                SizedBox(width: 8.w),
                OutlinedButton(
                  onPressed: onSections,
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(0, 44.w),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: Text(
                    'Các vùng',
                    style:
                        TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
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
          TextButton(
            onPressed: onReview ?? onPractice,
            style: TextButton.styleFrom(
              backgroundColor: GameVisualTokens.crimson,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'Ôn ngay',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSkillsGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LUYỆN KỸ NĂNG NHANH',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w900,
            color: GameVisualTokens.ink,
            letterSpacing: 0.6,
          ),
        ),
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
        Text(
          'CHUYÊN ĐỀ & MỞ RỘNG',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w900,
            color: GameVisualTokens.ink,
            letterSpacing: 0.6,
          ),
        ),
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
    return Material(
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
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
                        Container(
                          constraints: BoxConstraints(minHeight: height),
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.fromLTRB(
                              constraints.maxWidth * .38, 12.w, 48.w, 12.w),
                          child: TabCardText(
                            title: title,
                            description: subtitle,
                            titleColor: const Color(0xFF080F0C),
                            descriptionColor: const Color(0xFF24382C),
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
