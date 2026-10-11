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
import '../../../core/learning/model/learning_navigation_outcome.dart';
import '../../../core/learning/model/learning_source_context.dart';
import '../../../core/learning/model/learning_stage_models.dart';
import '../../../core/widgets/segmented_progress_node.dart';
import '../../hanzi_writing/screens/hanzi_writing_home_screen.dart';
import '../../hanzi_writing/screens/hanzi_writing_screen.dart';
import '../../speaking/speaking_screen.dart';
import '../../hsk/hsk_screen.dart';
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
                          backgroundColor: GameVisualTokens.jade),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
    final hasStages = controller.stages.isNotEmpty;
    final completed =
        hasStages ? controller.completedStageCount : chapter.completedMissions;
    final total =
        hasStages ? controller.totalStageCount : chapter.missions.length;
    final masteryPct = (chapter.overallMastery * 100).round();
    final bossStatus = chapter.bossUnlocked ? 'Sẵn sàng' : 'Chưa mở';

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: hasStages ? 'Ải bài học' : 'Nhiệm vụ',
            value: '$completed / $total',
            icon:
                hasStages ? Icons.flag_circle_rounded : Icons.task_alt_rounded,
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
            color:
                chapter.bossUnlocked ? GameVisualTokens.crimson : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildUnitCompleteCard(ChapterAdventure chapter) {
    final next = controller.nextUnit.value;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF064E3B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GameVisualTokens.imperialGold, width: 2),
        boxShadow: [
          BoxShadow(
            color: GameVisualTokens.jade.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 4),
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
                    color: GameVisualTokens.goldLight,
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
                    color: Color(0xFFD1FAE5),
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
        color = GameVisualTokens.jade;
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
      color = GameVisualTokens.jade;
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
      color = GameVisualTokens.jade;
      onPressed = () {
        if (next != null) {
          _openMission(chapter, next);
        } else {
          _openAdventureMap();
        }
      };
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
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
    final hasStages = controller.stages.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                hasStages ? 'DANH SÁCH ẢI (STAGES)' : 'LỘ TRÌNH KỸ NĂNG',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
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
              icon: const Icon(Icons.explore_rounded,
                  size: 16, color: GameVisualTokens.jade),
              label: const Text(
                'Bản đồ',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: GameVisualTokens.jade),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (hasStages) ...[
          ...controller.stages.asMap().entries.map((entry) {
            final idx = entry.key;
            final stage = entry.value;
            final isTarget = stage.id == controller.nextPlayableStage?.id &&
                !stage.isCompleted &&
                stage.isAvailable;
            return _StageListTile(
              index: idx + 1,
              stage: stage,
              isNextPlayable: isTarget,
              onTap: () => _openStage(chapter, stage),
            );
          }),
        ] else ...[
          ...chapter.missions.asMap().entries.map((entry) {
            final idx = entry.key;
            final mission = entry.value;
            return _MissionListTile(
              index: idx + 1,
              mission: mission,
              onTap: () => _openMission(chapter, mission),
            );
          }),
        ],
        if (chapter.boss != null &&
            (!hasStages ||
                !controller.stages.any((s) =>
                    s.activityType == LearningStageActivityType.boss))) ...[
          const SizedBox(height: 12),
          _BossListTile(
            boss: chapter.boss!,
            isUnlocked: chapter.bossUnlocked,
            onTap: () => _openBossGateModal(chapter),
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
              backgroundColor: GameVisualTokens.jade,
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
        final firstCharId = stage.items.isNotEmpty
            ? int.tryParse(stage.items.first.sourceId)
            : null;
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
        requiredTitle: uncompleted != null
            ? 'Cần hoàn thành: ${uncompleted.title}'
            : null,
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
              backgroundColor: GameVisualTokens.jade,
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
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1035),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: GameVisualTokens.crimson, width: 2),
        ),
        title: Row(
          children: const [
            Text('🔥', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'CỔNG KHIÊU CHIẾN BOSS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: GameVisualTokens.goldLight,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GameVisualTokens.crimson.withValues(alpha: 0.2),
                  border: Border.all(color: GameVisualTokens.crimson, width: 2),
                ),
                alignment: Alignment.center,
                child: const Text('🐲', style: TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                boss.bossName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Thủ Lĩnh Canh Giữ Cổng Bài Học',
                style: TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Máu người chơi (HP):',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                      Text('${boss.playerHp} ❤️',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Máu Boss (HP):',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                      Text('${boss.bossHp} 🛡️',
                          style: const TextStyle(
                              color: Color(0xFFFF8A80),
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Thử thách:',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                      Text('${boss.questionCount} câu hỏi',
                          style: const TextStyle(
                              color: GameVisualTokens.goldLight,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Đánh bại Boss để hoàn thành toàn bộ bài học và mở khóa bài tiếp theo!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('CHUẨN BỊ THÊM',
                style: TextStyle(color: Colors.white70)),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _openBoss(chapter);
            },
            icon: const Icon(Icons.local_fire_department_rounded, size: 18),
            label: const Text('VÀO CHIẾN ĐẤU'),
            style: FilledButton.styleFrom(
              backgroundColor: GameVisualTokens.crimson,
            ),
          ),
        ],
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
                            : GameVisualTokens.imperialGold
                                .withValues(alpha: 0.15),
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
                          color: isLocked
                              ? Colors.grey.shade600
                              : GameVisualTokens.templeWood,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mission.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
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
    return const Icon(Icons.arrow_forward_ios_rounded,
        size: 14, color: GameVisualTokens.jade);
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
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white70),
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

  IconData _iconForActivityType(LearningStageActivityType type) {
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
    final inProgress = stage.state == AdventureNodeState.inProgress;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNextPlayable
              ? GameVisualTokens.imperialGold
              : isCompleted
                  ? GameVisualTokens.jade.withValues(alpha: 0.5)
                  : inProgress
                      ? GameVisualTokens.imperialGold
                      : const Color(0xFFE2E8F0),
          width: isNextPlayable || inProgress ? 2.0 : 1.0,
        ),
        boxShadow: [
          if (isNextPlayable)
            BoxShadow(
              color: GameVisualTokens.imperialGold.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Material(
        color: isLocked ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                SegmentedProgressNode(
                  totalSegments: stage.totalItems,
                  completedSegments: stage.completedItems,
                  state: stage.state,
                  progress: stage.progress,
                  stars: stage.stars,
                  icon: _iconForActivityType(stage.activityType),
                  size: 60,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isLocked
                                  ? Colors.grey.shade200
                                  : isNextPlayable
                                      ? GameVisualTokens.imperialGold
                                      : GameVisualTokens.jade
                                          .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ẢI $index',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: isLocked
                                    ? Colors.grey.shade600
                                    : isNextPlayable
                                        ? const Color(0xFF451A03)
                                        : GameVisualTokens.jade,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (isNextPlayable) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: GameVisualTokens.imperialGold
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'MỤC TIÊU',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: GameVisualTokens.gold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              stage.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isLocked
                                    ? Colors.grey.shade600
                                    : GameVisualTokens.templeWood,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        stage.subtitle.isNotEmpty
                            ? stage.subtitle
                            : stage.learningObjective,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          Text(
                            '${stage.completedItems}/${stage.totalItems} nội dung',
                            style: const TextStyle(
                                fontSize: 11, color: LearningColors.muted),
                          ),
                          Text(
                            '•  ~${stage.estimatedMinutes} phút',
                            style: const TextStyle(
                                fontSize: 11, color: LearningColors.muted),
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
                                  size: 13,
                                  color: GameVisualTokens.imperialGold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildTrailingAction(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrailingAction() {
    if (stage.isLocked) {
      return const Icon(Icons.lock_rounded, size: 20, color: Colors.grey);
    }
    if (stage.isCompleted) {
      return const Icon(Icons.check_circle_rounded,
          size: 22, color: GameVisualTokens.jade);
    }
    if (isNextPlayable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: GameVisualTokens.imperialGold,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'VÀO HỌC',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Color(0xFF451A03),
          ),
        ),
      );
    }
    if (stage.state == AdventureNodeState.inProgress) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    return const Icon(Icons.arrow_forward_ios_rounded,
        size: 14, color: GameVisualTokens.jade);
  }
}
