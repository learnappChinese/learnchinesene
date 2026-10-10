import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_layout.dart';
import '../../../core/theme/learning_theme.dart';
import '../../../core/widgets/learning_scaffold.dart';
import '../../../core/widgets/learning_scene_background.dart';
import '../../review/model/review_item.dart';
import '../model/home_journey.dart';
import 'home_decorations.dart';

class HomePracticeTab extends StatelessWidget {
  const HomePracticeTab({
    super.key,
    required this.onSpeaking,
    required this.onWriting,
    required this.onFlashcards,
    required this.onLearningPath,
    required this.onQuiz,
    this.onReview,
    this.journey,
    this.reviewSummary,
    this.isLoading = false,
  });

  final VoidCallback onSpeaking;
  final VoidCallback onWriting;
  final VoidCallback onFlashcards;
  final VoidCallback onLearningPath;
  final VoidCallback onQuiz;
  final VoidCallback? onReview;
  final HomeJourney? journey;
  final ReviewSummary? reviewSummary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => LearningSceneBackground(
        theme: LearningSceneTheme.bambooVillage,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveHelper.contentMaxWidth(context),
            ),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                ResponsiveHelper.horizontalPadding(context),
                12,
                ResponsiveHelper.horizontalPadding(context),
                32,
              ),
              children: [
                _LearningHero(
                  journey: journey,
                  isLoading: isLoading,
                  onContinue: onLearningPath,
                ),
                const SizedBox(height: LearningSpacing.lg),
                const Text('LUYỆN NHANH', style: LearningTypography.label),
                const SizedBox(height: LearningSpacing.sm),
                LayoutBuilder(builder: (context, constraints) {
                  final gap = constraints.maxWidth < 350 ? 10.0 : 12.0;
                  final width = (constraints.maxWidth - gap) / 2;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      _PracticeTile(
                        width: width,
                        icon: Icons.history_edu_rounded,
                        title: 'Ôn luyện',
                        subtitle: _dueText(
                          reviewSummary?.totalDue,
                          'mục cần ôn hôm nay',
                          'Bạn đang theo kịp',
                        ),
                        color: LearningColors.red,
                        onTap: onReview ?? onQuiz,
                      ),
                      _PracticeTile(
                        width: width,
                        icon: Icons.record_voice_over_rounded,
                        title: 'Phát âm',
                        subtitle: _dueText(
                          reviewSummary?.speakingDue,
                          'câu cần cải thiện',
                          'Luyện nhanh 3 phút',
                        ),
                        color: LearningColors.orange,
                        onTap: onSpeaking,
                      ),
                      _PracticeTile(
                        width: width,
                        icon: Icons.draw_rounded,
                        title: 'Hanzi',
                        subtitle: _dueText(
                          reviewSummary?.hanziDue,
                          'chữ cần luyện',
                          'Khám phá chữ mới',
                        ),
                        color: LearningColors.jade,
                        onTap: onWriting,
                      ),
                      _PracticeTile(
                        width: width,
                        icon: Icons.style_rounded,
                        title: 'Flashcard',
                        subtitle: _dueText(
                          reviewSummary?.wordsDue,
                          'từ đến hạn',
                          'Ôn từ bài hiện tại',
                        ),
                        color: LearningColors.gold,
                        onTap: onFlashcards,
                      ),
                    ],
                  );
                }),
                const SizedBox(height: LearningSpacing.lg),
                _SecondaryAction(
                  icon: Icons.quiz_rounded,
                  title: 'Thử thách HSK',
                  subtitle: 'Quick Practice ngoài lộ trình chính',
                  onTap: onQuiz,
                ),
              ],
            ),
          ),
        ),
      );

  String _dueText(int? count, String label, String emptyLabel) => count == null
      ? 'Đang đồng bộ tiến độ'
      : count == 0
          ? emptyLabel
          : '$count $label';
}

class _LearningHero extends StatelessWidget {
  const _LearningHero({
    required this.journey,
    required this.isLoading,
    required this.onContinue,
  });

  final HomeJourney? journey;
  final bool isLoading;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 230,
        decoration: BoxDecoration(
          color: Colors.white54,
          borderRadius: BorderRadius.circular(LearningRadius.lg),
        ),
      );
    }
    final data = journey;
    return Container(
      padding: const EdgeInsets.all(LearningSpacing.lg),
      decoration: BoxDecoration(
        color: LearningColors.jadeDark,
        borderRadius: BorderRadius.circular(LearningRadius.lg),
        boxShadow: LearningShadow.raised,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const HomePandaFace(size: 58),
          const SizedBox(width: LearningSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data == null ? 'HÀNH TRÌNH MỚI' : 'BÀI ${data.chapterNumber}',
                  style: const TextStyle(
                    color: LearningColors.goldSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data?.chapterTitle ?? 'Khám phá thế giới tiếng Trung',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  data == null
                      ? 'Chọn World đầu tiên để bắt đầu'
                      : 'Tiếp theo: ${data.missionTitle}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ]),
        const SizedBox(height: LearningSpacing.lg),
        if (data != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '${data.completedMissions} / ${data.totalMissions} nhiệm vụ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                data.recommendation?.rewardPreview ??
                    '+${data.nextRewardXp} XP',
                style: const TextStyle(
                  color: LearningColors.goldSoft,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(LearningRadius.pill),
            child: LinearProgressIndicator(
              value: data.chapterProgress.clamp(0, 1),
              minHeight: 9,
              backgroundColor: Colors.black26,
              valueColor: const AlwaysStoppedAnimation(LearningColors.gold),
            ),
          ),
          const SizedBox(height: LearningSpacing.md),
        ],
        LearningPrimaryButton(
          label: data == null ? 'KHÁM PHÁ THẾ GIỚI' : 'TIẾP TỤC HÀNH TRÌNH',
          onPressed: onContinue,
        ),
      ]),
    );
  }
}

class _PracticeTile extends StatelessWidget {
  const _PracticeTile({
    required this.width,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Material(
          color: LearningColors.surface,
          borderRadius: BorderRadius.circular(LearningRadius.md),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(LearningRadius.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 142),
              child: Padding(
                padding: const EdgeInsets.all(LearningSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(LearningRadius.sm),
                      ),
                      child: Icon(icon, color: color),
                    ),
                    const SizedBox(height: LearningSpacing.sm),
                    Text(title, style: LearningTypography.sectionTitle),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: LearningTypography.body.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: LearningColors.surface,
        borderRadius: BorderRadius.circular(LearningRadius.md),
        child: ListTile(
          minTileHeight: 70,
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LearningRadius.md),
          ),
          leading: Icon(icon, color: LearningColors.red),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      );
}
