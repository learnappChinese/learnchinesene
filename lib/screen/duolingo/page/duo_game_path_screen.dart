import 'package:flutter/material.dart';
import '../../../core/widgets/learning_scene_background.dart';
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(widget.gameName),
      ),
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
    final secTitle = level['section_title'] as String;
    final unitNum = level['unit_number'] as int;
    final unitTitle = level['unit_title'] as String;
    final levelIndex = level['level_index'] as int;
    final cCount = level['challenge_count'] as int;
    final isUnlocked = level['is_unlocked'] as int == 1;
    final isCompleted = level['is_completed'] as int == 1;
    final stars = level['stars'] as int;

    bool showSectionHeader = false;
    bool showUnitHeader = false;

    if (idx == 0) {
      showSectionHeader = true;
      showUnitHeader = true;
    } else {
      final prev = controller.levels[idx - 1];
      if (prev['section_title'] != secTitle) {
        showSectionHeader = true;
        showUnitHeader = true;
      } else if (prev['unit_title'] != unitTitle) {
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
    } else if (isUnlocked) {
      status = 'available';
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
        showSectionHeader: showSectionHeader,
        showUnitHeader: showUnitHeader,
        offset: offset,
        status: status,
        icon: DuoGameVisuals.emoji(widget.gameCode),
        onTap: () {
          if (cCount == 0) {
            Get.snackbar(
                'Trống', 'Chưa có thử thách nào cho game này ở cấp độ này.');
            return;
          }
          if (!isUnlocked) {
            Get.snackbar('Khóa', 'Bạn cần vượt qua các cấp độ trước.');
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
            ),
          )?.then((_) => controller.loadLevels());
        });
  }

  Widget _buildLevelPath(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.levels.isEmpty) {
        return const Center(
            child: Text('Không tìm thấy lộ trình của game này.'));
      }

      // Tối ưu hóa cực lớn cho danh sách lên đến 1500+ cấp độ bằng cách sử dụng CustomScrollView + SliverList
      return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Header trò chơi
          SliverToBoxAdapter(
            child: DuoPathHeader(
                gameName: widget.gameName,
                description: widget.description,
                icon: DuoGameVisuals.icon(widget.gameCode),
                levelCount: controller.levels.length),
          ),

          // 2. Lộ trình cấp độ bằng SliverList
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
