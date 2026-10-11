import 'package:flutter/material.dart';
import '../../../core/widgets/learning_scene_background.dart';
import '../../../core/widgets/learning_scaffold.dart';
import '../../../core/widgets/locked_mission_sheet.dart';
import '../../../core/presentation/learning_presentation_mapper.dart';
import '../widget/duo_path_content.dart';
import '../duo_game_visuals.dart';
import 'package:get/get.dart';
import '../controller/duo_game_path_controller.dart';
import '../../vocabulary_adventure/binding/vocabulary_adventure_binding.dart';
import '../../vocabulary_adventure/page/vocabulary_adventure_screen.dart';
import 'duo_game_runner_screen.dart';

class DuoGamePathScreen extends StatefulWidget {
  final int gameId;
  final String gameCode;
  final String gameName;
  final String description;

  const DuoGamePathScreen({
    super.key,
    required this.gameId,
    required this.gameCode,
    required this.gameName,
    required this.description,
  });

  @override
  State<DuoGamePathScreen> createState() => _DuoGamePathScreenState();
}

class _DuoGamePathScreenState extends State<DuoGamePathScreen> {
  late final DuoGamePathController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
        DuoGamePathController(gameId: widget.gameId, gameCode: widget.gameCode),
        tag: widget.gameId.toString());
  }

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: widget.gameName,
      body: LearningSceneBackground(
        theme: LearningSceneTheme.lanternTown,
        child: _buildLevelPath(context),
      ),
    );
  }

  Widget _buildLevelItem(BuildContext context, int idx) {
    final level = controller.levels[idx];
    final levelId = level['level_id'] as String;
    final secNum = level['section_number'] as int;
    final secTitle = LearningPresentationMapper.sectionTitle(
      level['section_title'],
      secNum,
    );
    final unitNum = level['unit_number'] as int;
    final unitTitle = LearningPresentationMapper.chapterTitle(
      level['unit_title'],
      unitNum,
    );
    final levelIndex = level['level_index'] as int;
    final cCount = level['challenge_count'] as int;
    final isUnlocked = level['is_unlocked'] as int == 1;
    final isCompleted = level['is_completed'] as int == 1;
    final stars = level['stars'] as int;
    final attempts = level['attempts'] as int? ?? 0;
    final bestScore = level['best_score'] as int? ?? 0;
    final inProgress = level['in_progress'] == true;
    final currentIndex = level['current_index'] as int? ?? 0;
    final currentTotal = level['current_total'] as int? ?? cCount;

    bool showSectionHeader = false;
    bool showUnitHeader = false;

    if (idx == 0) {
      showSectionHeader = true;
      showUnitHeader = true;
    } else {
      final prev = controller.levels[idx - 1];
      if (prev['section_number'] != secNum) {
        showSectionHeader = true;
        showUnitHeader = true;
      } else if (prev['unit_number'] != unitNum) {
        showUnitHeader = true;
      }
    }

    // Tính vị trí zigzag cho node
    double offset = 0;
    if (idx % 4 == 1) offset = -50;
    if (idx % 4 == 3) offset = 50;

    String status = 'locked';
    if (cCount == 0) {
      status = 'locked'; // Empty level
    } else if (isCompleted) {
      status = 'completed';
    } else if (inProgress) {
      status = 'in_progress';
    } else if (isUnlocked) {
      status = attempts > 0 ? 'failed' : 'available';
    }

    return DuoPathItem(
        key: ValueKey(levelId),
        index: idx,
        secNum: secNum,
        secTitle: secTitle,
        unitNum: unitNum,
        unitTitle: unitTitle,
        levelIndex: levelIndex,
        cCount: cCount,
        isUnlocked: isUnlocked,
        stars: stars,
        missionTitle: LearningPresentationMapper.missionTitle(
          widget.gameName,
          widget.gameCode,
          levelIndex + 1,
        ),
        attempts: attempts,
        bestScore: bestScore,
        currentIndex: currentIndex,
        currentTotal: currentTotal,
        showSectionHeader: showSectionHeader,
        showUnitHeader: showUnitHeader,
        offset: offset,
        status: status,
        icon: DuoGameVisuals.emoji(widget.gameCode),
        onTap: () {
          if (cCount == 0) {
            showLockedMissionSheet(
              context,
              title: 'Nhiệm vụ chưa có nội dung',
              message: 'Curriculum chưa có thử thách phù hợp cho nhiệm vụ này.',
            );
            return;
          }
          if (!isUnlocked) {
            showLockedMissionSheet(
              context,
              title: 'Nhiệm vụ chưa mở',
              message: _lockMessage(level['lock_reason'] as String?),
            );
            return;
          }
          if (widget.gameCode == 'learn_words') {
            Get.to(
              () => const VocabularyAdventureScreen(),
              binding: VocabularyAdventureBinding(
                levelId: levelId,
                gameId: widget.gameId,
                gameName: widget.gameName,
              ),
            )?.then((_) => controller.loadLevels());
            return;
          }
          Get.to(
            () => DuoGameRunnerScreen(
              gameId: widget.gameId,
              gameCode: widget.gameCode,
              levelId: levelId,
              gameName: widget.gameName,
              chapterNumber: unitNum,
              missionNumber: idx + 1,
              missionCount: controller.levels.length,
            ),
          )?.then((_) => controller.loadLevels());
        });
  }

  String _lockMessage(String? reason) => switch (reason) {
        'mastery_too_low' =>
          'Hãy nâng mastery của bài học lên mức yêu cầu để mở nhiệm vụ.',
        'boss_required' => 'Hãy đánh bại Boss của bài trước.',
        'chapter_locked' => 'Hãy hoàn thành bài học trước để tiếp tục.',
        _ => 'Hoàn thành nhiệm vụ trước trên lộ trình để mở khóa.',
      };

  Widget _buildLevelPath(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.levels.isEmpty) {
        return const Center(
            child: Text('Không tìm thấy lộ trình của game này.'));
      }

      final secNum = controller.selectedSection.value;
      final secTitle = LearningPresentationMapper.sectionName(secNum);
      final currentLevel = controller.currentLevel ?? controller.levels.first;
      final unitNum = (currentLevel['unit_number'] as num?)?.toInt() ?? 1;
      final unitTitle = LearningPresentationMapper.unitTitle(
        currentLevel['unit_title'],
        unitNum,
      );

      final completedCount =
          controller.levels.where((row) => row['is_completed'] == 1).length;

      return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Header trò chơi & Context bài học (Requirement 27)
          SliverToBoxAdapter(
            child: DuoPathHeader(
              gameName: widget.gameName,
              description: widget.description,
              icon: DuoGameVisuals.icon(widget.gameCode),
              sectionNumber: secNum,
              sectionTitle: secTitle,
              unitNumber: unitNum,
              unitTitle: unitTitle,
              missionTitle: widget.gameName,
              completedCount: completedCount,
              missionCount: controller.levels.length,
              availableSections: controller.availableSections,
              selectedSection: secNum,
              onSelectSection: controller.selectSection,
              onQuickPractice: () {
                final target = controller.currentLevel ?? controller.levels.first;
                final levelId = target['level_id'] as String;
                if (widget.gameCode == 'learn_words') {
                  Get.to(
                    () => const VocabularyAdventureScreen(),
                    binding: VocabularyAdventureBinding(
                      levelId: levelId,
                      gameId: widget.gameId,
                      gameName: widget.gameName,
                    ),
                  )?.then((_) => controller.loadLevels());
                } else {
                  Get.to(
                    () => DuoGameRunnerScreen(
                      gameId: widget.gameId,
                      gameCode: widget.gameCode,
                      levelId: levelId,
                      gameName: widget.gameName,
                      chapterNumber: unitNum,
                      missionNumber: 1,
                      missionCount: controller.levels.length,
                    ),
                  )?.then((_) => controller.loadLevels());
                }
              },
            ),
          ),

          // 2. Lộ trình cấp độ của phần được chọn
          SliverList(
            delegate: SliverChildBuilderDelegate(
              _buildLevelItem,
              childCount: controller.levels.length,
            ),
          ),

          // Padding cuối màn hình
          const SliverToBoxAdapter(
            child: SizedBox(height: 48),
          ),
        ],
      );
    });
  }
}
