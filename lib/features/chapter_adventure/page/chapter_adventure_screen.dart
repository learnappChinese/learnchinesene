import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/responsive/responsive_layout.dart';
import '../../../core/theme/game_visual_tokens.dart';
import '../../../core/widgets/chapter_header_banner.dart';
import '../../../core/widgets/adventure_node.dart';
import '../../../core/widgets/learning_scaffold.dart';
import '../../../core/widgets/locked_mission_sheet.dart';
import '../../boss_battle/boss_battle_screen.dart';
import '../../home/widgets/shared_tab_background.dart';
import '../../duolingo/page/duo_game_runner_screen.dart';
import '../../vocabulary_adventure/binding/vocabulary_adventure_binding.dart';
import '../../vocabulary_adventure/page/vocabulary_adventure_screen.dart';
import '../controller/chapter_adventure_controller.dart';
import '../model/chapter_adventure.dart';
import '../widget/adventure_map.dart';

class ChapterAdventureScreen extends GetView<ChapterAdventureController> {
  const ChapterAdventureScreen({super.key});

  @override
  Widget build(BuildContext context) => LearningScaffold(
        title: 'Hành trình bài học',
        body: SharedTabBackground(
          child: Obx(() => _buildState(context)),
        ),
      );

  Widget _buildState(BuildContext context) {
    if (controller.isLoading.value) return const _ChapterMapLoading();
    if (controller.errorMessage.value != null) {
      return _ChapterMapMessage(
        icon: Icons.cloud_off_rounded,
        title: controller.errorMessage.value!,
        action: 'THỬ LẠI',
        onTap: controller.loadChapter,
      );
    }
    final chapter = controller.chapter.value;
    if (chapter == null || chapter.missions.isEmpty) {
      return _ChapterMapMessage(
        icon: Icons.map_outlined,
        title: 'Bài học này chưa có nhiệm vụ khả dụng.',
        action: 'TẢI LẠI',
        onTap: controller.loadChapter,
      );
    }
    return _buildChapter(context, chapter);
  }

  Widget _buildChapter(BuildContext context, ChapterAdventure chapter) {
    return Center(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: ResponsiveHelper.contentMaxWidth(context)),
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: ChapterHeaderBanner(
              chapterNumber: chapter.chapterNumber,
              badgeLabel: 'BÀI ${chapter.chapterNumber}',
              chineseTitle: '学习冒险',
              vietnameseTitle: chapter.title,
              objectives: [chapter.objective],
              footer: _ChapterProgress(chapter: chapter),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.horizontalPadding(context),
            ),
            sliver: SliverToBoxAdapter(
              child: AdventureMap(
                missions: chapter.missions,
                bossUnlocked: chapter.bossUnlocked && chapter.boss != null,
                onMissionTap: (mission) =>
                    _openMission(context, chapter, mission),
                onBossTap: () => _openBoss(context, chapter),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ]),
      ),
    );
  }

  void _openMission(
    BuildContext context,
    ChapterAdventure chapter,
    ChapterMission mission,
  ) {
    if (mission.state == AdventureNodeState.locked) {
      _showLockedMission(context, chapter, mission);
      return;
    }
    if (mission.gameCode == 'learn_words') {
      Get.to(
        () => const VocabularyAdventureScreen(),
        binding: VocabularyAdventureBinding(
          levelId: chapter.levelId,
          gameId: mission.gameId,
          gameName: mission.title,
        ),
      )?.then((_) => controller.loadChapter());
      return;
    }
    Get.to(
      () => DuoGameRunnerScreen(
        gameId: mission.gameId,
        gameCode: mission.gameCode,
        levelId: chapter.levelId,
        gameName: mission.title,
        chapterNumber: chapter.chapterNumber,
        missionNumber: chapter.missions.indexOf(mission) + 1,
        missionCount: chapter.missions.length,
      ),
    )?.then((_) => controller.loadChapter());
  }

  void _openBoss(BuildContext context, ChapterAdventure chapter) {
    final boss = chapter.boss;
    if (boss == null) return;
    if (!chapter.bossUnlocked) {
      showLockedMissionSheet(
        context,
        title: 'Cổng Boss chưa mở',
        message: _lockMessage(
          chapter.bossLockReason,
          chapter.bossRequiredMastery,
        ),
      );
      return;
    }
    Get.to(() => BossBattleScreen(stage: boss))
        ?.then((_) => controller.loadChapter());
  }

  void _showLockedMission(
    BuildContext context,
    ChapterAdventure chapter,
    ChapterMission mission,
  ) {
    final requiredGameId =
        int.tryParse(mission.requiredNodeId?.split(':').first ?? '');
    ChapterMission? required;
    if (requiredGameId != null) {
      for (final item in chapter.missions) {
        if (item.gameId == requiredGameId) {
          required = item;
          break;
        }
      }
    }
    final requiredMission = required;
    showLockedMissionSheet(
      context,
      title: 'Nhiệm vụ này chưa mở',
      message: _lockMessage(mission.lockReason, mission.requiredMastery),
      requiredTitle: requiredMission?.title,
      onViewRequired: requiredMission == null
          ? null
          : () {
              _openMission(context, chapter, requiredMission);
            },
    );
  }

  String _lockMessage(String? reason, double? mastery) => switch (reason) {
        'mastery_too_low' =>
          'Nâng mastery lên ít nhất ${((mastery ?? .7) * 100).round()}% để mở khóa.',
        'boss_required' => 'Hãy đánh bại Boss của bài trước.',
        'chapter_locked' => 'Hãy hoàn thành bài học trước để tiếp tục.',
        _ => 'Hoàn thành nhiệm vụ trước trên bản đồ để mở khóa.',
      };
}

class _ChapterProgress extends StatelessWidget {
  const _ChapterProgress({required this.chapter});
  final ChapterAdventure chapter;

  @override
  Widget build(BuildContext context) {
    final remaining = chapter.missions.length - chapter.completedMissions;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1E6CF)),
      ),
      child: Column(children: [
        Row(children: [
          const Icon(Icons.route_rounded,
              size: 18, color: GameVisualTokens.primaryGreen),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${chapter.completedMissions}/${chapter.missions.length} nhiệm vụ • ${chapter.totalStars} ⭐',
              style: const TextStyle(
                color: Color(0xFF342E10),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text('${(chapter.progress * 100).round()}%',
              style: const TextStyle(
                  color: GameVisualTokens.primaryGreenDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: chapter.progress,
            minHeight: 9,
            backgroundColor: const Color(0xFFF1E6CF),
            color: GameVisualTokens.primaryGreen,
          ),
        ),
        const SizedBox(height: 7),
        Row(children: [
          Text(remaining == 0 ? '🐉' : '🔒',
              style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              remaining == 0
                  ? 'Cổng Boss đã mở. Panda đang chờ bạn!'
                  : 'Còn $remaining nhiệm vụ để mở cổng Boss.',
              style: const TextStyle(
                  color: Color(0xFF5D5C54),
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _ChapterMapLoading extends StatelessWidget {
  const _ChapterMapLoading();
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
              height: 210,
              decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(24))),
          const SizedBox(height: 28),
          ...List.generate(
              4,
              (index) => Align(
                    alignment: index.isEven
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 32),
                      width: 82,
                      height: 82,
                      decoration: const BoxDecoration(
                          color: Colors.white60, shape: BoxShape.circle),
                    ),
                  )),
        ],
      );
}

class _ChapterMapMessage extends StatelessWidget {
  const _ChapterMapMessage({
    required this.icon,
    required this.title,
    required this.action,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 54, color: GameVisualTokens.primaryGreen),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: GameVisualTokens.primaryGreen,
              ),
              child: Text(action),
            ),
          ]),
        ),
      );
}
