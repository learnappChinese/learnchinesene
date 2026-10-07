import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/responsive/responsive_layout.dart';
import '../../../core/theme/game_visual_tokens.dart';
import '../../../core/widgets/chapter_header_banner.dart';
import '../../../core/widgets/learning_scene_background.dart';
import '../../boss_battle/boss_battle_screen.dart';
import '../../duolingo/page/duo_game_runner_screen.dart';
import '../../vocabulary_adventure/binding/vocabulary_adventure_binding.dart';
import '../../vocabulary_adventure/page/vocabulary_adventure_screen.dart';
import '../controller/chapter_adventure_controller.dart';
import '../model/chapter_adventure.dart';
import '../widget/adventure_map.dart';

class ChapterAdventureScreen extends GetView<ChapterAdventureController> {
  const ChapterAdventureScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Chapter Adventure')),
        body: LearningSceneBackground(
          theme: LearningSceneTheme.bambooVillage,
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
        title: 'Chapter này chưa có nhiệm vụ khả dụng.',
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
              chineseTitle: '学习冒险',
              vietnameseTitle: chapter.title,
              objectives: [chapter.objective],
            ),
          ),
          SliverToBoxAdapter(child: _ChapterProgress(chapter: chapter)),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.horizontalPadding(context),
            ),
            sliver: SliverToBoxAdapter(
              child: AdventureMap(
                missions: chapter.missions,
                bossUnlocked: chapter.bossUnlocked && chapter.boss != null,
                onMissionTap: (mission) => _openMission(chapter, mission),
                onBossTap: () => _openBoss(chapter),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ]),
      ),
    );
  }

  void _openMission(ChapterAdventure chapter, ChapterMission mission) {
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
      ),
    )?.then((_) => controller.loadChapter());
  }

  void _openBoss(ChapterAdventure chapter) {
    final boss = chapter.boss;
    if (boss == null || !chapter.bossUnlocked) return;
    Get.to(() => BossBattleScreen(stage: boss))
        ?.then((_) => controller.loadChapter());
  }
}

class _ChapterProgress extends StatelessWidget {
  const _ChapterProgress({required this.chapter});
  final ChapterAdventure chapter;

  @override
  Widget build(BuildContext context) {
    final remaining = chapter.missions.length - chapter.completedMissions;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GameVisualTokens.parchment.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GameVisualTokens.goldLight),
      ),
      child: Column(children: [
        Row(children: [
          const Icon(Icons.route_rounded, color: GameVisualTokens.jade),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${chapter.completedMissions}/${chapter.missions.length} nhiệm vụ • ${chapter.totalStars} sao',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          Text('${(chapter.progress * 100).round()}%',
              style: const TextStyle(
                  color: GameVisualTokens.jadeDark,
                  fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: chapter.progress,
            minHeight: 9,
            backgroundColor: Colors.black12,
            color: GameVisualTokens.imperialGold,
          ),
        ),
        const SizedBox(height: 7),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            remaining == 0
                ? 'Cổng Boss đã mở. Panda đang chờ bạn!'
                : 'Còn $remaining nhiệm vụ để mở cổng Boss.',
            style: const TextStyle(
                color: GameVisualTokens.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700),
          ),
        ),
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
                  color: Colors.white54,
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
            Icon(icon, size: 54, color: GameVisualTokens.crimsonDark),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            FilledButton(onPressed: onTap, child: Text(action)),
          ]),
        ),
      );
}
