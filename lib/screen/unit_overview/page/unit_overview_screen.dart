import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/presentation/learning_presentation_mapper.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/theme/game_visual_tokens.dart';
import '../../../core/theme/learning_theme.dart';
import '../../../core/widgets/adventure_node.dart';
import '../../../core/widgets/learning_scaffold.dart';
import '../../../core/widgets/learning_scene_background.dart';
import '../../../core/widgets/locked_mission_sheet.dart';
import '../../boss_battle/boss_battle_screen.dart';
import '../../chapter_adventure/binding/chapter_adventure_binding.dart';
import '../../chapter_adventure/model/chapter_adventure.dart';
import '../../chapter_adventure/page/chapter_adventure_screen.dart';
import '../../duolingo/duo_game_visuals.dart';
import '../../duolingo/page/duo_game_runner_screen.dart';
import '../../vocabulary_adventure/binding/vocabulary_adventure_binding.dart';
import '../../vocabulary_adventure/page/vocabulary_adventure_screen.dart';
import '../controller/unit_overview_controller.dart';

class UnitOverviewScreen extends StatefulWidget {
  const UnitOverviewScreen({super.key});

  @override
  State<UnitOverviewScreen> createState() => _UnitOverviewScreenState();
}

class _UnitOverviewScreenState extends State<UnitOverviewScreen> {
  late final UnitOverviewController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<UnitOverviewController>()
        ? Get.find<UnitOverviewController>()
        : Get.put(UnitOverviewController());
  }

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: 'Tổng quan bài học',
      actions: [
        IconButton(
          tooltip: 'Bản đồ phiêu lưu',
          icon: const Icon(Icons.map_rounded, color: GameVisualTokens.imperialGold),
          onPressed: _openAdventureMap,
        ),
      ],
      body: LearningSceneBackground(
        theme: LearningSceneTheme.bambooVillage,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: GameVisualTokens.jade),
            );
          }

          if (controller.errorMessage.value != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 48, color: LearningColors.muted),
                    const SizedBox(height: 16),
                    Text(
                      controller.errorMessage.value!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: LearningColors.ink, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: controller.loadUnitOverview,
                      style: FilledButton.styleFrom(backgroundColor: GameVisualTokens.jade),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final chapter = controller.chapter.value;
          if (chapter == null) {
            return const Center(child: Text('Không có dữ liệu bài học.'));
          }

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ResponsiveHelper.contentMaxWidth(context),
              ),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  ResponsiveHelper.horizontalPadding(context),
                  16,
                  ResponsiveHelper.horizontalPadding(context),
                  40,
                ),
                children: [
                  _buildHeader(context, chapter),
                  const SizedBox(height: 16),
                  _buildMetricsRow(chapter),
                  const SizedBox(height: 20),
                  _buildPrimaryCta(chapter),
                  const SizedBox(height: 24),
                  _buildMissionList(chapter),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ChapterAdventure chapter) {
    final secNum = chapter.regionNumber;
    final secName = LearningPresentationMapper.sectionName(secNum);
    final unitNum = chapter.chapterNumber;
    final unitTitle = chapter.title;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: GameVisualTokens.imperialGold, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: GameVisualTokens.imperialGold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'PHẦN $secNum • $secName'.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF451A03),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('🏮 🐉', style: TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'BÀI $unitNum: $unitTitle',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mục tiêu bài học: ${chapter.objective.isNotEmpty ? chapter.objective : 'Nắm vững từ vựng và mẫu câu giao tiếp cơ bản.'}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFCBD5E1),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(ChapterAdventure chapter) {
    final completed = chapter.completedMissions;
    final total = chapter.missions.length;
    final masteryPct = (chapter.overallMastery * 100).round();
    final bossStatus = chapter.bossUnlocked
        ? 'Sẵn sàng'
        : 'Chưa mở';

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: 'Nhiệm vụ',
            value: '$completed / $total',
            icon: Icons.task_alt_rounded,
            color: GameVisualTokens.jade,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCard(
            label: 'Thành thạo',
            value: '$masteryPct%',
            icon: Icons.psychology_rounded,
            color: GameVisualTokens.imperialGold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCard(
            label: 'Boss',
            value: bossStatus,
            icon: Icons.shield_rounded,
            color: chapter.bossUnlocked ? GameVisualTokens.crimson : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryCta(ChapterAdventure chapter) {
    final isBossReady = chapter.bossUnlocked && chapter.boss != null;
    final label = isBossReady
        ? 'KHIÊU CHIẾN BOSS'
        : (chapter.completedMissions == 0 ? 'BẮT ĐẦU BÀI HỌC' : 'TIẾP TỤC BÀI HỌC');

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: () {
          if (isBossReady) {
            _openBoss(chapter);
          } else {
            final next = controller.nextPlayableMission;
            if (next != null) {
              _openMission(chapter, next);
            } else {
              _openAdventureMap();
            }
          }
        },
        style: FilledButton.styleFrom(
          backgroundColor: isBossReady ? GameVisualTokens.crimson : GameVisualTokens.jade,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isBossReady ? Icons.local_fire_department_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionList(ChapterAdventure chapter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'LỘ TRÌNH KỸ NĂNG',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: GameVisualTokens.templeWood,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _openAdventureMap,
              icon: const Icon(Icons.explore_rounded, size: 16, color: GameVisualTokens.jade),
              label: const Text(
                'Bản đồ',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GameVisualTokens.jade),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...chapter.missions.asMap().entries.map((entry) {
          final idx = entry.key;
          final mission = entry.value;
          return _MissionListTile(
            index: idx + 1,
            mission: mission,
            onTap: () => _openMission(chapter, mission),
          );
        }),
        if (chapter.boss != null) ...[
          const SizedBox(height: 12),
          _BossListTile(
            boss: chapter.boss!,
            isUnlocked: chapter.bossUnlocked,
            onTap: () => _openBoss(chapter),
          ),
        ],
      ],
    );
  }

  void _openMission(ChapterAdventure chapter, ChapterMission mission) {
    if (mission.state == AdventureNodeState.locked) {
      showLockedMissionSheet(
        context,
        title: 'Nhiệm vụ chưa mở',
        message: 'Hoàn thành các nhiệm vụ trước để mở khóa nhiệm vụ này.',
      );
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
      )?.then((_) => controller.loadUnitOverview());
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
    )?.then((_) => controller.loadUnitOverview());
  }

  void _openBoss(ChapterAdventure chapter) {
    if (!chapter.bossUnlocked || chapter.boss == null) {
      showLockedMissionSheet(
        context,
        title: 'Boss chưa thức tỉnh',
        message: 'Hãy hoàn thành các nhiệm vụ trong bài để đối đầu với Boss.',
      );
      return;
    }

    Get.to(
      () => BossBattleScreen(stage: chapter.boss!),
    )?.then((_) => controller.loadUnitOverview());
  }

  void _openAdventureMap() {
    final chapter = controller.chapter.value;
    if (chapter == null) return;
    Get.to(
      () => const ChapterAdventureScreen(),
      binding: ChapterAdventureBinding(levelId: chapter.levelId),
    )?.then((_) => controller.loadUnitOverview());
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: LearningColors.muted),
          ),
        ],
      ),
    );
  }
}

class _MissionListTile extends StatelessWidget {
  const _MissionListTile({
    required this.index,
    required this.mission,
    required this.onTap,
  });

  final int index;
  final ChapterMission mission;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLocked = mission.state == AdventureNodeState.locked;
    final isCompleted = mission.isCompleted;
    final inProgress = mission.state == AdventureNodeState.inProgress;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? GameVisualTokens.jade.withValues(alpha: 0.5)
              : inProgress
                  ? GameVisualTokens.imperialGold
                  : const Color(0xFFE2E8F0),
          width: inProgress ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: isLocked ? const Color(0xFFF1F5F9) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isLocked
                        ? Colors.grey.shade200
                        : isCompleted
                            ? GameVisualTokens.jade.withValues(alpha: 0.15)
                            : GameVisualTokens.imperialGold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    DuoGameVisuals.emoji(mission.gameCode),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Mission $index: ${mission.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isLocked ? Colors.grey.shade600 : GameVisualTokens.templeWood,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mission.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusWidget() {
    if (mission.state == AdventureNodeState.locked) {
      return const Icon(Icons.lock_rounded, size: 20, color: Colors.grey);
    }
    if (mission.isCompleted) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          3,
          (i) => Icon(
            i < mission.stars ? Icons.star_rounded : Icons.star_border_rounded,
            size: 16,
            color: GameVisualTokens.imperialGold,
          ),
        ),
      );
    }
    if (mission.state == AdventureNodeState.inProgress) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: GameVisualTokens.imperialGold.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Đang học',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: GameVisualTokens.gold,
          ),
        ),
      );
    }
    return const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: GameVisualTokens.jade);
  }
}

class _BossListTile extends StatelessWidget {
  const _BossListTile({
    required this.boss,
    required this.isUnlocked,
    required this.onTap,
  });

  final dynamic boss;
  final bool isUnlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isUnlocked
                ? [const Color(0xFF7F1D1D), const Color(0xFF991B1B)]
                : [Colors.grey.shade700, Colors.grey.shade800],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (isUnlocked)
              BoxShadow(
                color: GameVisualTokens.crimson.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                const Text('🐉', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Unit Boss: ${boss.bossName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isUnlocked
                            ? 'Thử thách checkpoint để hoàn thành bài học!'
                            : 'Hoàn thành các nhiệm vụ trên để mở khóa Boss',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isUnlocked ? Icons.local_fire_department_rounded : Icons.lock_rounded,
                  color: isUnlocked ? GameVisualTokens.imperialGold : Colors.white54,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
