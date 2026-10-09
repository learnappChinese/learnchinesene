import 'package:flutter/material.dart';
import 'widget/duo_game_card.dart';
import 'duo_game_visuals.dart';
import 'package:get/get.dart';
import '../../core/widgets/learning_scaffold.dart';
import '../../core/widgets/learning_scene_background.dart';
import 'controller/duo_game_center_controller.dart';
import 'page/duo_game_path_screen.dart';

class DuoGameCenterScreen extends StatefulWidget {
  const DuoGameCenterScreen({super.key});

  @override
  State<DuoGameCenterScreen> createState() => _DuoGameCenterScreenState();
}

class _DuoGameCenterScreenState extends State<DuoGameCenterScreen> {
  late final DuoGameCenterController controller;

  @override
  void initState() {
    super.initState();
    // GetX retains the existing route ownership and cleanup.
    controller = Get.isRegistered<DuoGameCenterController>()
        ? Get.find<DuoGameCenterController>()
        : Get.put(DuoGameCenterController());
  }

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: 'Game Center',
      body: LearningSceneBackground(
        theme: LearningSceneTheme.lanternTown,
        child: _buildGameCatalog(context),
      ),
    );
  }

  Widget _buildGameCatalog(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.games.isEmpty) {
        return const Center(child: Text('Không tìm thấy dữ liệu trò chơi.'));
      }

      return ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: controller.games.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, idx) {
          final game = controller.games[idx];
          final gameId = game['id'] as int;
          final gameCode = game['game_code'] as String;
          final nameVi = game['name_vi'] as String;
          final descVi = game['description_vi'] as String;
          final totalLevels = game['total_levels'] as int;
          final completedLevels = game['completed_levels'] as int;
          final bestStars = game['best_stars'] as int? ?? 0;
          final chapterNumber = game['chapter_number'] as int? ?? 1;
          final chapterTitle = '${game['chapter_title'] ?? ''}';
          final state = '${game['state'] ?? 'quick_practice'}';
          final currentIndex = game['current_index'] as int? ?? 0;
          final currentTotal = game['current_total'] as int? ?? 0;

          final IconData iconData = DuoGameVisuals.icon(gameCode);
          final Color gameColor = DuoGameVisuals.color(gameCode);

          return DuoGameCard(
              key: ValueKey(gameId),
              nameVi: nameVi,
              descVi: descVi,
              totalLevels: totalLevels,
              completedLevels: completedLevels,
              bestStars: bestStars,
              chapterNumber: chapterNumber,
              chapterTitle: chapterTitle,
              state: state,
              currentIndex: currentIndex,
              currentTotal: currentTotal,
              iconData: iconData,
              gameColor: gameColor,
              onTap: () {
                Get.to(() => DuoGamePathScreen(
                    gameId: gameId,
                    gameCode: gameCode,
                    gameName: nameVi,
                    description: descVi))?.then((_) => controller.loadGames());
              });
        },
      );
    });
  }
}
