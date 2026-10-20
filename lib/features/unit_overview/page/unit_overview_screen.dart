import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/app_green_button.dart';
import '../../../core/presentation/learning_presentation_mapper.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/theme/game_visual_tokens.dart';
import '../../../core/theme/learning_theme.dart';
import '../../../core/widgets/adventure_node.dart';
import '../../../core/widgets/learning_scaffold.dart';
import '../../../core/widgets/locked_mission_sheet.dart';
import '../../boss_battle/boss_battle_screen.dart';
import '../../chapter_adventure/binding/chapter_adventure_binding.dart';
import '../../chapter_adventure/model/chapter_adventure.dart';
import '../../chapter_adventure/page/chapter_adventure_screen.dart';
import '../../duolingo/duo_game_visuals.dart';
import '../../duolingo/page/duo_game_runner_screen.dart';
import '../../vocabulary_adventure/binding/vocabulary_adventure_binding.dart';
import '../../vocabulary_adventure/page/vocabulary_adventure_screen.dart';
import '../../../core/learning/model/learning_navigation_outcome.dart';
import '../../../core/learning/model/learning_source_context.dart';
import '../../../core/learning/model/learning_stage_models.dart';
import '../../../core/widgets/segmented_progress_node.dart';
import '../../../core/widgets/panda_companion.dart';
import '../../hanzi_writing/screens/hanzi_writing_home_screen.dart';
import '../../hanzi_writing/screens/hanzi_writing_screen.dart';
import '../../speaking/speaking_screen.dart';
import '../../hsk/hsk_screen.dart';
import '../../home/widgets/shared_tab_background.dart';
import '../binding/unit_overview_binding.dart';
import '../controller/unit_overview_controller.dart';
import 'unit_complete_screen.dart';

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
          icon: const Icon(Icons.map_rounded,
              color: GameVisualTokens.imperialGold),
          onPressed: _openAdventureMap,
        ),
      ],
      body: SharedTabBackground(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(
                  color: GameVisualTokens.primaryGreen),
            );
          }

          if (controller.errorMessage.value != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded,
                        size: 48, color: LearningColors.muted),
                    const SizedBox(height: 16),
                    Text(
                      controller.errorMessage.value!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: LearningColors.ink, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: controller.loadUnitOverview,
                      style: FilledButton.styleFrom(
                          backgroundColor: GameVisualTokens.primaryGreen),
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
                  if (controller.isUnitCompleted) ...[
                    const SizedBox(height: 16),
                    _buildUnitCompleteCard(chapter),
                  ],
                  if (controller.isBossReady &&
                      !controller.isUnitCompleted) ...[
                    const SizedBox(height: 16),
                    _buildBossGateCard(chapter),
                  ],
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

    final total = controller.stages.isNotEmpty
        ? controller.totalStageCount
        : chapter.missions.length;
    final completed = controller.stages.isNotEmpty
        ? controller.completedStageCount
        : chapter.completedMissions;
    return _UnitHeroCard(
      eyebrow: 'Phần $secNum • $secName',
      title: 'Bài $unitNum: $unitTitle',
      plainTitle: unitTitle,
      objective: chapter.objective.isNotEmpty
          ? chapter.objective
          : 'Nắm vững từ vựng và mẫu câu giao tiếp cơ bản.',
      completed: completed,
      total: total,
      statusLabel: chapter.bossUnlocked ? 'Boss đã mở' : 'Đang phiêu lưu',
      bossUnlocked: chapter.bossUnlocked,
    );
  }

  Widget _buildMetricsRow(ChapterAdventure chapter) {
    final hasStages = controller.stages.isNotEmpty;
    final completed =
        hasStages ? controller.completedStageCount : chapter.completedMissions;
    final total =
        hasStages ? controller.totalStageCount : chapter.missions.length;
    final masteryPct = (chapter.overallMastery * 100).round();
    final bossStatus = chapter.bossUnlocked ? 'Sẵn sàng' : 'Chưa mở';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: GameVisualTokens.primaryGreenDark.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _MetricItem(
              label: hasStages ? 'Ải bài học' : 'Nhiệm vụ',
              value: '$completed / $total',
              icon: hasStages ? Icons.flag_rounded : Icons.task_alt_rounded,
              color: GameVisualTokens.primaryGreen,
            ),
            const VerticalDivider(
                width: 1, thickness: 1, color: Color(0xFFEFEAE2)),
            _MetricItem(
              label: 'Thành thạo',
              value: '$masteryPct%',
              icon: Icons.psychology_rounded,
              color: GameVisualTokens.imperialGold,
            ),
            const VerticalDivider(
                width: 1, thickness: 1, color: Color(0xFFEFEAE2)),
            _MetricItem(
              label: 'Boss',
              value: bossStatus,
              icon: chapter.bossUnlocked
                  ? Icons.local_fire_department_rounded
                  : Icons.lock_rounded,
              color: chapter.bossUnlocked
                  ? GameVisualTokens.crimson
                  : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitCompleteCard(ChapterAdventure chapter) {
    final next = controller.nextUnit.value;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBEA), Color(0xFFFFEFC2)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GameVisualTokens.imperialGold, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24635D3B),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BÀI HỌC ĐÃ HOÀN THÀNH',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF57300A),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  next != null
                      ? 'Đã mở khóa Bài học tiếp theo: ${next.title}!'
                      : 'Chúc mừng bạn đã hoàn thành trọn vẹn lộ trình!',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5D5C54),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBossGateCard(ChapterAdventure chapter) {
    final bossName = chapter.boss?.bossName ?? 'Thủ Lĩnh Rồng';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF450A0A), Color(0xFF7F1D1D)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GameVisualTokens.crimson, width: 2),
        boxShadow: [
          BoxShadow(
            color: GameVisualTokens.crimson.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GameVisualTokens.crimson.withValues(alpha: 0.3),
                  border:
                      Border.all(color: GameVisualTokens.crimson, width: 1.5),
                ),
                alignment: Alignment.center,
                child: const Text('🐲', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CỔNG BOSS ĐÃ MỞ (BOSS GATE)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: GameVisualTokens.goldLight,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Boss: $bossName',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () => _openBossGateModal(chapter),
                style: FilledButton.styleFrom(
                  backgroundColor: GameVisualTokens.crimson,
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: const Text(
                  'KHIÊU CHIẾN',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Đủ điều kiện khiêu chiến! Đánh bại Boss để hoàn tất bài học và mở khóa nội dung tiếp theo.',
            style:
                TextStyle(fontSize: 12, color: Color(0xFFFECACA), height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryCta(ChapterAdventure chapter) {
    final isCompleted = controller.isUnitCompleted;
    final isBossReady = controller.isBossReady;
    final hasStages = controller.stages.isNotEmpty;
    final isStarted = hasStages
        ? controller.completedStageCount > 0
        : chapter.completedMissions > 0;

    String label;
    IconData icon;
    Color color;
    VoidCallback onPressed;

    if (isCompleted) {
      final next = controller.nextUnit.value;
      if (next != null) {
        label = 'BÀI TIẾP THEO: ${next.title}'.toUpperCase();
        icon = Icons.arrow_forward_rounded;
        color = GameVisualTokens.primaryGreen;
        onPressed = _openNextUnit;
      } else {
        label = 'HOÀN THÀNH • VỀ BẢN ĐỒ THẾ GIỚI';
        icon = Icons.explore_rounded;
        color = GameVisualTokens.imperialGold;
        onPressed = _openWorldMap;
      }
    } else if (isBossReady) {
      label = 'KHIÊU CHIẾN BOSS';
      icon = Icons.local_fire_department_rounded;
      color = GameVisualTokens.crimson;
      onPressed = () => _openBossGateModal(chapter);
    } else if (hasStages) {
      final next = controller.nextPlayableStage;
      final num = controller.nextPlayableStageNumber;
      if (!isStarted) {
        label = next != null
            ? 'BẮT ĐẦU ẢI $num: ${next.title}'.toUpperCase()
            : 'BẮT ĐẦU BÀI HỌC';
      } else {
        label = next != null
            ? 'TIẾP TỤC ẢI $num: ${next.title}'.toUpperCase()
            : 'TIẾP TỤC BÀI HỌC';
      }
      icon = Icons.play_arrow_rounded;
      color = GameVisualTokens.primaryGreen;
      onPressed = () {
        if (next != null) {
          _openStage(chapter, next);
        } else {
          _openAdventureMap();
        }
      };
    } else {
      final next = controller.nextPlayableMission;
      label = (!isStarted ? 'BẮT ĐẦU BÀI HỌC' : 'TIẾP TỤC BÀI HỌC');
      icon = Icons.play_arrow_rounded;
      color = GameVisualTokens.primaryGreen;
      onPressed = () {
        if (next != null) {
          _openMission(chapter, next);
        } else {
          _openAdventureMap();
        }
      };
    }

    return _GameCtaButton(
      label: label,
      icon: icon,
      color: color,
      onPressed: onPressed,
    );
  }

  Widget _buildMissionList(ChapterAdventure chapter) {
    final hasStages = controller.stages.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: GameVisualTokens.imperialGold,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasStages ? 'Lộ trình ải học tập' : 'Bản đồ kỹ năng',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: GameVisualTokens.templeWood,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: GameVisualTokens.primaryGreen.withValues(alpha: 0.1),
              shape: const StadiumBorder(),
              child: InkWell(
                onTap: _openAdventureMap,
                customBorder: const StadiumBorder(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.explore_rounded,
                          size: 15, color: GameVisualTokens.primaryGreen),
                      SizedBox(width: 5),
                      Text(
                        'Bản đồ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: GameVisualTokens.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (hasStages) ...[
          ...controller.stages.asMap().entries.map((entry) {
            final idx = entry.key;
            final stage = entry.value;
            final isTarget = stage.id == controller.nextPlayableStage?.id &&
                !stage.isCompleted &&
                stage.isAvailable;
            return _StageTrailEntry(
              isFirst: idx == 0,
              isLast:
                  idx == controller.stages.length - 1 && chapter.boss == null,
              lineColor: stage.isCompleted
                  ? GameVisualTokens.primaryGreen
                  : const Color(0xFFCBD5E1),
              node: SegmentedProgressNode(
                totalSegments: stage.totalItems,
                completedSegments: stage.completedItems,
                state: stage.state,
                progress: stage.progress,
                stars: stage.stars,
                icon: _StageListTile.iconFor(stage.activityType),
                isActive: isTarget,
                size: 56,
                ringWidth: 5,
              ),
              child: _StageListTile(
                index: idx + 1,
                stage: stage,
                isNextPlayable: isTarget,
                onTap: () => _openStage(chapter, stage),
              ),
            );
          }),
        ] else ...[
          ...chapter.missions.asMap().entries.map((entry) {
            final idx = entry.key;
            final mission = entry.value;
            return _StageTrailEntry(
              isFirst: idx == 0,
              isLast:
                  idx == chapter.missions.length - 1 && chapter.boss == null,
              lineColor: mission.isCompleted
                  ? GameVisualTokens.primaryGreen
                  : const Color(0xFFCBD5E1),
              node: _MissionNode(mission: mission),
              child: _MissionListTile(
                index: idx + 1,
                mission: mission,
                onTap: () => _openMission(chapter, mission),
              ),
            );
          }),
        ],
        if (chapter.boss != null &&
            (!hasStages ||
                !controller.stages.any((s) =>
                    s.activityType == LearningStageActivityType.boss))) ...[
          _StageTrailEntry(
            isFirst: false,
            isLast: true,
            lineColor: const Color(0xFFCBD5E1),
            node: _BossNode(isUnlocked: chapter.bossUnlocked),
            child: _BossListTile(
              boss: chapter.boss!,
              isUnlocked: chapter.bossUnlocked,
              onTap: () => _openBossGateModal(chapter),
            ),
          ),
        ],
      ],
    );
  }

  void _handleStageReturn(dynamic result) {
    final wasBossReady = controller.isBossReady;
    final isSuccess = result == true ||
        (result is LearningNavigationOutcome && result.isSuccess);
    final outcome = result is LearningNavigationOutcome ? result : null;

    controller.loadUnitOverview().then((_) {
      if (!mounted) return;

      if (outcome != null && outcome.isFightBoss) {
        final chapter = controller.chapter.value;
        if (chapter != null) {
          _openBoss(chapter);
          return;
        }
      }

      if (isSuccess) {
        final chapter = controller.chapter.value;
        if (controller.isUnitCompleted && chapter != null) {
          Get.to(
            () => UnitCompleteScreen(
              unitId: chapter.unitId,
              unitTitle: chapter.title,
              sectionNumber: chapter.regionNumber,
              unitNumber: chapter.chapterNumber,
              bossName: chapter.boss?.bossName,
              xpEarned: outcome?.result?.xpEarned ?? 0,
              starsEarned: outcome?.result?.stars ?? 3,
            ),
          );
        } else if (!wasBossReady && controller.isBossReady && chapter != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔥 CỔNG BOSS ĐÃ MỞ! Sẵn sàng khiêu chiến Boss!'),
              backgroundColor: GameVisualTokens.crimson,
              duration: Duration(seconds: 3),
            ),
          );
          Future.delayed(const Duration(milliseconds: 350), () {
            if (mounted) _openBossGateModal(chapter);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '🎉 VƯỢT ẢI THÀNH CÔNG! Tiếp tục ải ${controller.nextPlayableStageNumber}.'),
              backgroundColor: GameVisualTokens.primaryGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  void _openStage(ChapterAdventure chapter, LearningStageViewModel stage) {
    if (stage.isLocked) {
      final prerequisite = _findPrerequisiteStage(stage);
      showLockedMissionSheet(
        context,
        title: 'Ải chưa mở khóa',
        message: _stageLockMessage(stage),
        requiredTitle: prerequisite != null
            ? 'Cần hoàn thành: Ải ${prerequisite.title}'
            : (stage.lockReason == 'chapter_locked'
                ? 'Yêu cầu: Đánh bại Boss bài trước'
                : (stage.lockReason == 'mastery_too_low'
                    ? 'Yêu cầu: Thành thạo ≥ ${((stage.requiredMastery ?? .70) * 100).round()}%'
                    : null)),
        actionLabel: prerequisite != null
            ? 'LÀM ẢI ${prerequisite.title.toUpperCase()}'
            : null,
        onViewRequired: prerequisite != null
            ? () => _openStage(chapter, prerequisite)
            : null,
      );
      return;
    }

    final targetLevelId = stage.sourceLevelIds.isNotEmpty
        ? stage.sourceLevelIds.first
        : chapter.levelId;

    switch (stage.activityType) {
      case LearningStageActivityType.vocabulary:
        Get.to(
          () => const VocabularyAdventureScreen(),
          binding: VocabularyAdventureBinding(
            levelId: targetLevelId,
            gameId: stage.sourceGameId ?? 0,
            gameName: stage.title,
          ),
        )?.then(_handleStageReturn);
        break;

      case LearningStageActivityType.hanzi:
        final charIds = stage.items
            .map((item) => int.tryParse(item.sourceId))
            .whereType<int>()
            .toList();
        final firstCharId = charIds.isNotEmpty ? charIds.first : null;
        final hanziContext = LearningSourceContext(
          courseId: 'duo_chinese',
          duoUnitId: 'unit_${chapter.chapterNumber}',
          lexiconUnitId: chapter.chapterNumber,
          levelId: targetLevelId,
          gameCode: 'hanzi',
          mode: LearningMode.duoMission,
        );
        Get.to(
          () => firstCharId != null
              ? HanziWritingScreen(
                  characterId: firstCharId,
                  sourceContext: hanziContext,
                  characterSequence: charIds,
                  unitId: chapter.chapterNumber,
                )
              : HanziWritingHomeScreen(
                  sourceContext: hanziContext,
                ),
        )?.then(_handleStageReturn);
        break;

      case LearningStageActivityType.speaking:
        final speakingContext = LearningSourceContext(
          courseId: 'duo_chinese',
          duoUnitId: 'unit_${chapter.chapterNumber}',
          lexiconUnitId: chapter.chapterNumber,
          levelId: targetLevelId,
          gameCode: 'speaking',
          mode: LearningMode.duoMission,
        );
        Get.to(
          () => SpeakingScreen(
            unitId: chapter.chapterNumber,
            sourceContext: speakingContext,
          ),
        )?.then(_handleStageReturn);
        break;

      case LearningStageActivityType.listening:
      case LearningStageActivityType.sentence:
      case LearningStageActivityType.dialogue:
      case LearningStageActivityType.quiz:
        Get.to(
          () => DuoGameRunnerScreen(
            gameId: stage.sourceGameId ?? 0,
            gameCode: stage.sourceGameCode ?? 'select_answer',
            levelId: targetLevelId,
            gameName: stage.title,
            unitId: stage.unitId.isNotEmpty ? stage.unitId : chapter.unitId,
            chapterNumber: chapter.chapterNumber,
            missionNumber: controller.stages.indexOf(stage) + 1,
            missionCount: controller.stages.length,
          ),
        )?.then(_handleStageReturn);
        break;

      case LearningStageActivityType.boss:
        if (stage.bossStage != null) {
          _openBossWithStage(stage.bossStage!);
        } else if (chapter.boss != null) {
          _openBossGateModal(chapter);
        }
        break;
    }
  }

  LearningStageViewModel? _findPrerequisiteStage(LearningStageViewModel stage) {
    final required = stage.requiredStageId;
    if (required != null) {
      final found = controller.stages.where((candidate) {
        final level = candidate.sourceLevelIds.firstOrNull;
        return '${candidate.sourceGameId}:$level' == required;
      }).firstOrNull;
      if (found != null) return found;
    }
    final idx = controller.stages.indexOf(stage);
    if (idx > 0) {
      for (var i = idx - 1; i >= 0; i--) {
        if (!controller.stages[i].isCompleted) {
          return controller.stages[i];
        }
      }
    }
    return null;
  }

  String _stageLockMessage(LearningStageViewModel stage) {
    if (stage.lockReason == 'mastery_too_low') {
      final required = ((stage.requiredMastery ?? .70) * 100).round();
      return 'Cần đạt ít nhất $required% thành thạo để mở ải này.';
    }
    if (stage.lockReason == 'chapter_locked') {
      return 'Hãy đánh bại Boss của bài học trước để mở khóa.';
    }
    final prerequisite = _findPrerequisiteStage(stage);
    if (prerequisite != null) {
      return 'Cần hoàn thành Ải ${prerequisite.title}.';
    }
    return 'Cần hoàn thành ải trước để mở khóa.';
  }

  void _openMission(ChapterAdventure chapter, ChapterMission mission) {
    if (mission.state == AdventureNodeState.locked) {
      final uncompleted = chapter.missions
          .where((m) => m.state != AdventureNodeState.completed && m != mission)
          .firstOrNull;
      showLockedMissionSheet(
        context,
        title: 'Nhiệm vụ chưa mở',
        message: 'Hoàn thành các nhiệm vụ trước để mở khóa nhiệm vụ này.',
        requiredTitle:
            uncompleted != null ? 'Cần hoàn thành: ${uncompleted.title}' : null,
        actionLabel: uncompleted != null ? 'LÀM NHIỆM VỤ NÀY' : null,
        onViewRequired: uncompleted != null
            ? () => _openMission(chapter, uncompleted)
            : null,
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
      )?.then(_handleStageReturn);
      return;
    }

    Get.to(
      () => DuoGameRunnerScreen(
        gameId: mission.gameId,
        gameCode: mission.gameCode,
        levelId: chapter.levelId,
        gameName: mission.title,
        unitId: chapter.unitId,
        chapterNumber: chapter.chapterNumber,
        missionNumber: chapter.missions.indexOf(mission) + 1,
        missionCount: chapter.missions.length,
      ),
    )?.then(_handleStageReturn);
  }

  void _openBossWithStage(dynamic bossStage) {
    Get.to(
      () => BossBattleScreen(stage: bossStage),
    )?.then((result) {
      final isSuccess = result == true ||
          (result is LearningNavigationOutcome && result.isSuccess);
      controller.loadUnitOverview().then((_) {
        if (isSuccess && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🏆 ĐÃ ĐÁNH BẠI BOSS! HOÀN THÀNH BÀI HỌC! ⭐⭐⭐'),
              backgroundColor: GameVisualTokens.primaryGreen,
              duration: Duration(seconds: 3),
            ),
          );
        }
      });
    });
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
    _openBossWithStage(chapter.boss!);
  }

  void _openBossGateModal(ChapterAdventure chapter) {
    if (!chapter.bossUnlocked || chapter.boss == null) {
      showLockedMissionSheet(
        context,
        title: 'Cổng Boss chưa mở',
        message: 'Hãy hoàn thành các ải bài học để mở khóa Cổng Boss.',
      );
      return;
    }

    final boss = chapter.boss!;
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFDF6), Color(0xFFFFF1D6)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), GameVisualTokens.crimson],
                  ),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  'CỔNG KHIÊU CHIẾN BOSS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: 84,
                height: 84,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: GameVisualTokens.crimson.withValues(alpha: .45),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: GameVisualTokens.crimson.withValues(alpha: .25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Text('🐲', style: TextStyle(fontSize: 44)),
              ),
              const SizedBox(height: 12),
              Text(
                boss.bossName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF342E10),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Thủ Lĩnh Canh Giữ Cổng Bài Học',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF5D5C54),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _BossStat(
                    value: '${boss.playerHp} ❤️',
                    label: 'HP của bạn',
                  ),
                  const SizedBox(width: 8),
                  _BossStat(
                    value: '${boss.bossHp} 🛡️',
                    label: 'HP Boss',
                  ),
                  const SizedBox(width: 8),
                  _BossStat(
                    value: '${boss.questionCount} câu hỏi',
                    label: 'Thử thách',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Đánh bại Boss để hoàn thành toàn bộ bài học và mở khóa bài tiếp theo!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: Color(0xFF5D5C54),
                ),
              ),
              const SizedBox(height: 18),
              AppGreenButton(
                label: 'VÀO CHIẾN ĐẤU',
                icon: Icons.local_fire_department_rounded,
                height: 50,
                expand: true,
                onPressed: () {
                  Navigator.of(dialogCtx).pop();
                  _openBoss(chapter);
                },
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('CHUẨN BỊ THÊM'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openNextUnit() {
    final next = controller.nextUnit.value;
    if (next != null) {
      Get.off(
        () => const UnitOverviewScreen(),
        binding: UnitOverviewBinding(
          unitId: next.id,
          unitTitle: next.title,
          sectionNumber: next.sectionNumber,
          unitNumber: next.unitNumber,
        ),
      );
    } else {
      _openWorldMap();
    }
  }

  void _openWorldMap() {
    Get.to(() => const HskScreen());
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

class _UnitHeroCard extends StatelessWidget {
  const _UnitHeroCard({
    required this.eyebrow,
    required this.title,
    required this.plainTitle,
    required this.objective,
    required this.completed,
    required this.total,
    required this.statusLabel,
    required this.bossUnlocked,
  });

  final String eyebrow;
  final String title;
  final String plainTitle;
  final String objective;
  final int completed;
  final int total;
  final String statusLabel;
  final bool bossUnlocked;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.25;
    final progress = total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);
    final accent =
        bossUnlocked ? GameVisualTokens.crimson : GameVisualTokens.primaryGreen;
    // Dữ liệu cũ hay để mục tiêu trùng tên bài, khi đó ẩn đi cho gọn.
    final showObjective =
        objective.trim().toLowerCase() != plainTitle.trim().toLowerCase();

    return Semantics(
      container: true,
      label: '$eyebrow. $title. $completed trên $total ải',
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFDF6), Color(0xFFFFF1D6)],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white, width: 4),
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
              right: -6,
              top: -40,
              child: Text(
                '学',
                style: TextStyle(
                  fontSize: 150,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF8B5E1A).withValues(alpha: 0.06),
                ),
              ),
            ),
            if (!largeText)
              Positioned(
                right: -2,
                bottom: -14,
                child: ExcludeSemantics(
                  child: PandaCompanion(
                    mood: bossUnlocked ? PandaMood.archer : PandaMood.happy,
                    size: 112,
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 18, largeText ? 20 : 108, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    eyebrow.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF57300A),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _HeroChip(
                        label: statusLabel,
                        background: accent.withValues(alpha: 0.14),
                        foreground: bossUnlocked
                            ? GameVisualTokens.crimson
                            : GameVisualTokens.primaryGreenDark,
                        icon: bossUnlocked
                            ? Icons.local_fire_department_rounded
                            : Icons.explore_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF342E10),
                      fontSize: 22,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (showObjective) ...[
                    const SizedBox(height: 6),
                    Text(
                      '🎯 $objective',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF5D5C54),
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: const Color(0xFFF1E6CF),
                            color: accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$completed/$total ải',
                        style: TextStyle(
                          color: bossUnlocked
                              ? GameVisualTokens.crimson
                              : GameVisualTokens.primaryGreenDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: .3,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
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
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: LearningColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCtaButton extends StatefulWidget {
  const _GameCtaButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  State<_GameCtaButton> createState() => _GameCtaButtonState();
}

class _GameCtaButtonState extends State<_GameCtaButton> {
  static const double _faceHeight = 56;
  static const double _depth = 5;
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final radius = BorderRadius.circular(18);

    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onPressed,
        child: SizedBox(
          height: _faceHeight + _depth,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _faceHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color.lerp(color, Colors.black, .32),
                    borderRadius: radius,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 80),
                left: 0,
                right: 0,
                top: _pressed ? _depth - 1 : 0,
                height: _faceHeight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color.lerp(color, Colors.white, .14)!, color],
                    ),
                    borderRadius: radius,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.icon, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Một chặng trên lộ trình: node bên trái nối với nhau bằng một đường dọc,
/// thẻ nội dung bên phải.
class _StageTrailEntry extends StatelessWidget {
  const _StageTrailEntry({
    required this.isFirst,
    required this.isLast,
    required this.lineColor,
    required this.node,
    required this.child,
  });

  static const double _railWidth = 64;
  static const double _nodeTop = 10;
  static const double _nodeCenter = _nodeTop + 28;

  final bool isFirst;
  final bool isLast;
  final Color lineColor;
  final Widget node;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final showLine = !(isFirst && isLast);
    return Stack(
      children: [
        if (showLine)
          Positioned(
            left: _railWidth / 2 - 2,
            top: isFirst ? _nodeCenter : 0,
            bottom: isLast ? null : 0,
            height: isLast ? _nodeCenter : null,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: lineColor,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _railWidth,
                child: Padding(
                  padding: const EdgeInsets.only(top: _nodeTop),
                  child: Center(child: node),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(child: child),
            ],
          ),
        ),
      ],
    );
  }
}

/// Vỏ thẻ dùng chung cho các ải/nhiệm vụ trên lộ trình.
class _TrailCard extends StatelessWidget {
  const _TrailCard({
    required this.onTap,
    required this.child,
    this.highlight = false,
    this.completed = false,
    this.locked = false,
  });

  final VoidCallback onTap;
  final Widget child;
  final bool highlight;
  final bool completed;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    final borderColor = highlight
        ? GameVisualTokens.primaryGreen
        : completed
            ? GameVisualTokens.primaryGreen.withValues(alpha: 0.35)
            : const Color(0xFFE9E4DA);

    return Opacity(
      opacity: locked ? 0.7 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: locked ? const Color(0xFFF8F7F4) : Colors.white,
          borderRadius: radius,
          border: Border.all(color: borderColor, width: highlight ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: highlight
                  ? GameVisualTokens.primaryGreen.withValues(alpha: 0.22)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: highlight ? 16 : 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: RoundedRectangleBorder(borderRadius: radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _TrailTag extends StatelessWidget {
  const _TrailTag({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: foreground,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _TrailMeta extends StatelessWidget {
  const _TrailMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: LearningColors.muted),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: LearningColors.muted,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: GameVisualTokens.imperialGold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: _kAmberDark,
        ),
      ),
    );
  }
}

class _StartPill extends StatelessWidget {
  const _StartPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            GameVisualTokens.primaryGreenLight,
            GameVisualTokens.primaryGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(99),
        boxShadow: [
          BoxShadow(
            color: GameVisualTokens.primaryGreen.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
          SizedBox(width: 2),
          Text(
            'VÀO HỌC',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionNode extends StatelessWidget {
  const _MissionNode({required this.mission});

  final ChapterMission mission;

  @override
  Widget build(BuildContext context) {
    final isLocked = mission.state == AdventureNodeState.locked;
    final isCompleted = mission.isCompleted;
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isLocked
            ? const Color(0xFFE2E8F0)
            : isCompleted
                ? GameVisualTokens.primaryGreenSoft
                : const Color(0xFFFFF1D6),
        border: Border.all(
          color: isLocked
              ? Colors.white
              : isCompleted
                  ? GameVisualTokens.primaryGreen
                  : GameVisualTokens.imperialGold,
          width: 3,
        ),
      ),
      child: isLocked
          ? const Icon(Icons.lock_rounded, color: Color(0xFF94A3B8), size: 22)
          : Text(
              DuoGameVisuals.emoji(mission.gameCode),
              style: const TextStyle(fontSize: 24),
            ),
    );
  }
}

class _BossNode extends StatelessWidget {
  const _BossNode({required this.isUnlocked});

  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isUnlocked
              ? const [Color(0xFFEF4444), Color(0xFF7F1D1D)]
              : const [Color(0xFF94A3B8), Color(0xFF475569)],
        ),
        border: Border.all(color: GameVisualTokens.goldLight, width: 3),
        boxShadow: [
          if (isUnlocked)
            BoxShadow(
              color: GameVisualTokens.crimson.withValues(alpha: 0.45),
              blurRadius: 14,
            ),
        ],
      ),
      child: const Text('🐉', style: TextStyle(fontSize: 26)),
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

    return _TrailCard(
      onTap: onTap,
      highlight: inProgress,
      completed: isCompleted,
      locked: isLocked,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TrailTag(
                label: 'NHIỆM VỤ $index',
                background: isLocked
                    ? const Color(0xFFE2E8F0)
                    : GameVisualTokens.primaryGreen.withValues(alpha: 0.12),
                foreground: isLocked
                    ? const Color(0xFF64748B)
                    : GameVisualTokens.primaryGreen,
              ),
              const Spacer(),
              _buildStatusWidget(),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            mission.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              height: 1.25,
              color: isLocked
                  ? const Color(0xFF64748B)
                  : GameVisualTokens.templeWood,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            mission.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              color: LearningColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusWidget() {
    if (mission.state == AdventureNodeState.locked) {
      return const SizedBox.shrink();
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
      return const _StatusBadge(label: 'Đang học');
    }
    return const Icon(Icons.arrow_forward_ios_rounded,
        size: 14, color: GameVisualTokens.primaryGreen);
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
    final radius = BorderRadius.circular(18);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isUnlocked
              ? const [Color(0xFF991B1B), Color(0xFF7F1D1D)]
              : const [Color(0xFF64748B), Color(0xFF475569)],
        ),
        borderRadius: radius,
        boxShadow: [
          if (isUnlocked)
            BoxShadow(
              color: GameVisualTokens.crimson.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        shape: RoundedRectangleBorder(borderRadius: radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _TrailTag(
                        label: 'BOSS',
                        background: Color(0x33FFFFFF),
                        foreground: GameVisualTokens.goldLight,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${boss.bossName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isUnlocked
                            ? 'Thử thách checkpoint để hoàn thành bài học!'
                            : 'Hoàn thành các ải phía trên để mở khóa Boss',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, height: 1.35, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isUnlocked
                      ? Icons.local_fire_department_rounded
                      : Icons.lock_rounded,
                  color: isUnlocked
                      ? GameVisualTokens.imperialGold
                      : Colors.white54,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StageListTile extends StatelessWidget {
  const _StageListTile({
    required this.index,
    required this.stage,
    required this.onTap,
    this.isNextPlayable = false,
  });

  final int index;
  final LearningStageViewModel stage;
  final VoidCallback onTap;
  final bool isNextPlayable;

  static IconData iconFor(LearningStageActivityType type) {
    switch (type) {
      case LearningStageActivityType.vocabulary:
        return Icons.menu_book_rounded;
      case LearningStageActivityType.hanzi:
        return Icons.edit_note_rounded;
      case LearningStageActivityType.listening:
        return Icons.headphones_rounded;
      case LearningStageActivityType.sentence:
        return Icons.translate_rounded;
      case LearningStageActivityType.speaking:
        return Icons.mic_rounded;
      case LearningStageActivityType.dialogue:
        return Icons.chat_bubble_rounded;
      case LearningStageActivityType.quiz:
        return Icons.quiz_rounded;
      case LearningStageActivityType.boss:
        return Icons.local_fire_department_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = stage.isLocked;
    final isCompleted = stage.isCompleted;
    final description =
        stage.subtitle.isNotEmpty ? stage.subtitle : stage.learningObjective;

    return _TrailCard(
      onTap: onTap,
      highlight: isNextPlayable,
      completed: isCompleted,
      locked: isLocked,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TrailTag(
                label: 'ẢI $index',
                background: isLocked
                    ? const Color(0xFFE2E8F0)
                    : isNextPlayable
                        ? GameVisualTokens.primaryGreen
                        : GameVisualTokens.primaryGreen.withValues(alpha: 0.12),
                foreground: isLocked
                    ? const Color(0xFF64748B)
                    : isNextPlayable
                        ? Colors.white
                        : GameVisualTokens.primaryGreenDark,
              ),
              if (isNextPlayable) ...[
                const SizedBox(width: 6),
                _TrailTag(
                  label: 'MỤC TIÊU',
                  background: GameVisualTokens.primaryGreenSoft,
                  foreground: GameVisualTokens.primaryGreenDark,
                ),
              ],
              const Spacer(),
              _buildStatus(),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            stage.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              height: 1.25,
              color: isLocked
                  ? const Color(0xFF64748B)
                  : GameVisualTokens.templeWood,
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                color: LearningColors.muted,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _TrailMeta(
                      icon: Icons.layers_rounded,
                      text: '${stage.completedItems}/${stage.totalItems}',
                    ),
                    _TrailMeta(
                      icon: Icons.schedule_rounded,
                      text: '~${stage.estimatedMinutes} phút',
                    ),
                    if (stage.stars > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          3,
                          (i) => Icon(
                            i < stage.stars
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 14,
                            color: GameVisualTokens.imperialGold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (isNextPlayable) const _StartPill(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatus() {
    if (stage.isLocked) {
      return const Icon(Icons.lock_rounded, size: 16, color: Color(0xFF94A3B8));
    }
    if (stage.isCompleted) {
      return const Icon(Icons.check_circle_rounded,
          size: 20, color: GameVisualTokens.primaryGreen);
    }
    if (!isNextPlayable && stage.state == AdventureNodeState.inProgress) {
      return const _StatusBadge(label: 'Đang học');
    }
    return const SizedBox.shrink();
  }
}

const _kAmberDark = Color(0xFFB45309);

class _BossStat extends StatelessWidget {
  const _BossStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF1E6CF)),
          ),
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF342E10),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF5D5C54),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
}
