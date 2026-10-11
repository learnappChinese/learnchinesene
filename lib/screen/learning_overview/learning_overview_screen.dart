import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/responsive/responsive_layout.dart';
import '../../core/theme/learning_theme.dart';
import '../../core/widgets/chapter_header_banner.dart';
import '../../core/widgets/learning_scaffold.dart';
import '../../core/widgets/learning_scene_background.dart';
import '../conversations/conversations_screen.dart';
import '../hanzi_writing/screens/hanzi_writing_home_screen.dart';
import '../quiz/quiz_screen.dart';
import '../speaking/speaking_screen.dart';
import '../word_list/word_list_screen.dart';
import 'controller/learning_overview_controller.dart';

/// Detail for a lexicon chapter. Server-backed progression is rendered by the
/// Chapter Adventure flow; this screen never invents stars or unlock state.
class LearningOverviewScreen extends StatefulWidget {
  const LearningOverviewScreen({super.key});

  @override
  State<LearningOverviewScreen> createState() => _LearningOverviewScreenState();
}

class _LearningOverviewScreenState extends State<LearningOverviewScreen> {
  late final LearningOverviewController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<LearningOverviewController>()
        ? Get.find<LearningOverviewController>()
        : Get.put(LearningOverviewController());
  }

  void _go(Widget screen) {
    Get.to(
      () => screen,
      arguments: {
        'unitId': controller.unitId,
        'unitTitle': controller.title,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: controller.title,
      body: LearningSceneBackground(
        theme: LearningSceneTheme.bambooVillage,
        child: Obx(() {
          if (controller.isLoading.value) return const _ChapterLoading();
          final words = controller.metrics['words'] ?? 0;
          final examples = controller.metrics['examples'] ?? 0;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ResponsiveHelper.contentMaxWidth(context),
              ),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  ResponsiveHelper.horizontalPadding(context),
                  LearningSpacing.sm,
                  ResponsiveHelper.horizontalPadding(context),
                  LearningSpacing.xxl,
                ),
                children: [
                  ChapterHeaderBanner(
                    chapterNumber: controller.unitId,
                    chineseTitle: '学习冒险',
                    vietnameseTitle: controller.title,
                    objectives: [
                      '$words từ vựng theo curriculum',
                      '$examples câu ví dụ theo ngữ cảnh',
                    ],
                  ),
                  const SizedBox(height: LearningSpacing.lg),
                  const _SectionTitle(
                    title: 'Nội dung Chapter',
                    subtitle: 'Chọn kỹ năng bạn muốn luyện ngay',
                  ),
                  const SizedBox(height: LearningSpacing.md),
                  LayoutBuilder(builder: (context, constraints) {
                    final compact = constraints.maxWidth < 350;
                    return GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: LearningSpacing.sm,
                      crossAxisSpacing: LearningSpacing.sm,
                      childAspectRatio: compact ? 1.05 : 1.25,
                      children: [
                        _LearningAction(
                          icon: Icons.menu_book_rounded,
                          title: 'Từ vựng',
                          subtitle: '$words từ trong Chapter',
                          color: LearningColors.jade,
                          onTap: () => _go(const WordListScreen()),
                        ),
                        _LearningAction(
                          icon: Icons.psychology_alt_rounded,
                          title: 'Nhận biết',
                          subtitle: 'Luyện nhớ chủ động',
                          color: LearningColors.softOrange,
                          onTap: () => _go(const QuizScreen()),
                        ),
                        _LearningAction(
                          icon: Icons.mic_rounded,
                          title: 'Phát âm',
                          subtitle: 'Nghe, nói và nhận phản hồi',
                          color: LearningColors.red,
                          onTap: () => _go(const SpeakingScreen()),
                        ),
                        _LearningAction(
                          icon: Icons.gesture_rounded,
                          title: 'Hanzi',
                          subtitle: 'Quan sát, tô và viết',
                          color: LearningColors.goldDark,
                          onTap: () => _go(const HanziWritingHomeScreen()),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: LearningSpacing.md),
                  _DialogueCard(
                    exampleCount: examples,
                    onTap: () => Get.to(() => const ConversationsScreen()),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: LearningTypography.title),
          const SizedBox(height: 3),
          Text(subtitle, style: LearningTypography.body),
        ],
      );
}

class _LearningAction extends StatelessWidget {
  const _LearningAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: LearningColors.surface.withValues(alpha: .94),
        shape: RoundedRectangleBorder(
          borderRadius: LearningRadius.card,
          side: BorderSide(color: color.withValues(alpha: .24)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(LearningSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .13),
                    borderRadius: LearningRadius.small,
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(height: LearningSpacing.sm),
                Text(title, style: LearningTypography.cardTitle),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: LearningTypography.caption,
                ),
              ],
            ),
          ),
        ),
      );
}

class _DialogueCard extends StatelessWidget {
  const _DialogueCard({required this.exampleCount, required this.onTap});
  final int exampleCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: LearningColors.jadeDark,
        borderRadius: LearningRadius.card,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(LearningSpacing.md),
            child: Row(
              children: [
                const Icon(Icons.forum_rounded,
                    color: LearningColors.gold, size: 34),
                const SizedBox(width: LearningSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hội thoại theo ngữ cảnh',
                          style: LearningTypography.cardTitle
                              .copyWith(color: Colors.white)),
                      const SizedBox(height: 3),
                      Text(
                        '$exampleCount câu ví dụ • Nghe và phản xạ',
                        style: LearningTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: .78),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded,
                    color: LearningColors.gold),
              ],
            ),
          ),
        ),
      );
}

class _ChapterLoading extends StatelessWidget {
  const _ChapterLoading();

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(LearningSpacing.md),
        children: List.generate(
          4,
          (index) => Container(
            height: index == 0 ? 170 : 92,
            margin: const EdgeInsets.only(bottom: LearningSpacing.sm),
            decoration: BoxDecoration(
              color: LearningColors.surface.withValues(alpha: .65),
              borderRadius: LearningRadius.card,
            ),
          ),
        ),
      );
}
