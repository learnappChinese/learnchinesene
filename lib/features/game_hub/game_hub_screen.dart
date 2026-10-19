import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/learning/data/learning_journey_repository.dart';
import '../../core/learning/model/learning_stage_models.dart';
import '../boss_battle/boss_battle_screen.dart';
import '../boss_battle/boss_stage_map_screen.dart';
import '../dragon_panda/screens/boss_battle/boss_battle_defeat_screen.dart';
import '../dragon_panda/screens/boss_battle/boss_battle_gameplay_screen.dart';
import '../dragon_panda/screens/boss_battle/boss_battle_intro_screen.dart';
import '../dragon_panda/screens/boss_battle/boss_battle_victory_screen.dart';
import '../dragon_panda/screens/chinese_restaurant/chinese_restaurant_screen.dart';
import '../dragon_panda/screens/quick_answer/quick_answer_screen.dart';
import '../dragon_panda/screens/radical_builder/radical_builder_screen.dart';
import '../dragon_panda/screens/tone_ninja/tone_ninja_screen.dart'
    show ToneNinjaScreen;
import '../duolingo/page/duo_game_runner_screen.dart';
import '../hanzi_writing/screens/hanzi_writing_home_screen.dart';
import '../home/controller/home_controller.dart';
import '../home/widgets/home_decorations.dart';
import '../home/widgets/home_tab_scaffold.dart';
import '../speaking/speaking_screen.dart';
import 'view/game_hub_view.dart';

class GameHubScreen extends StatelessWidget {
  const GameHubScreen({
    super.key,
    this.embedded = false,
    this.journeyRepository,
  });

  final bool embedded;
  final LearningJourneyRepository? journeyRepository;

  LearningJourneyRepository get _journeyRepo {
    if (journeyRepository != null) return journeyRepository!;
    if (Get.isRegistered<LearningJourneyRepository>()) {
      return Get.find<LearningJourneyRepository>();
    }
    return SupabaseLearningJourneyRepository();
  }

  static int currentBossStageLevel = 1;

  static String getBossName(int level) {
    switch (level) {
      case 1:
        return 'Hỏa Long';
      case 2:
        return 'Băng Long';
      case 3:
        return 'Lôi Long';
      case 4:
        return 'Phong Long';
      case 5:
        return 'Thần Long';
      default:
        return 'Long Vương (Lv. $level)';
    }
  }

  void _back() => Get.back();

  void _openBossBattle() {
    Get.to(() => BossBattleIntroScreen(
          onBack: _back,
          onStartGame: () => _openBossGameplay(currentBossStageLevel),
        ));
  }

  void _openBossGameplay(int level) {
    Get.off(() => BossBattleGameplayScreen(
          stageLevel: level,
          stageTitle: 'Cấp độ $level',
          bossName: getBossName(level),
          onExit: _back,
          onVictory: () => _openVictory(level),
          onDefeat: () => _openDefeat(level),
        ));
  }

  void _openVictory(int level) {
    Get.off(() => BossBattleVictoryScreen(
          onContinue: () {
            currentBossStageLevel = level + 1;
            _openBossGameplay(currentBossStageLevel);
          },
          onBackToHub: _back,
        ));
  }

  void _openDefeat(int level) {
    Get.off(() => BossBattleDefeatScreen(
          onRetry: () => _openBossGameplay(level),
          onBackToHub: _back,
        ));
  }

  void _selectTab(int index) {
    if (index == 2) return;
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().setIndex(index);
    }
    Get.back();
  }

  void _openStageMap() {
    Get.to(() => const BossBattleStageMapScreen());
  }

  void _openRadicalBuilder() {
    Get.to(() => RadicalBuilderScreen(onBack: () => Get.back()));
  }

  void _openToneNinja() {
    Get.to(() => ToneNinjaScreen(onBack: () => Get.back()));
  }

  void _openRestaurant() {
    Get.to(() => ChineseRestaurantScreen(onBack: () => Get.back()));
  }

  void _openQuickAnswer() {
    Get.to(() => QuickAnswerScreen(onBack: () => Get.back()));
  }

  static void launchStage(
    LearningStageViewModel stage, {
    int? chapterNumber,
  }) {
    final targetLevelId =
        stage.sourceLevelIds.isNotEmpty ? stage.sourceLevelIds.first : '';

    switch (stage.activityType) {
      case LearningStageActivityType.hanzi:
        Get.to(() => const HanziWritingHomeScreen());
        break;

      case LearningStageActivityType.speaking:
        Get.to(() => SpeakingScreen(unitId: chapterNumber ?? 1));
        break;

      case LearningStageActivityType.listening:
      case LearningStageActivityType.sentence:
      case LearningStageActivityType.dialogue:
      case LearningStageActivityType.quiz:
      case LearningStageActivityType.vocabulary:
        Get.to(() => DuoGameRunnerScreen(
              gameId: stage.sourceGameId ?? 0,
              gameCode: stage.sourceGameCode ??
                  (stage.activityType == LearningStageActivityType.listening
                      ? 'listen_select'
                      : 'select_answer'),
              levelId: targetLevelId,
              gameName: stage.title,
              chapterNumber: chapterNumber ?? 1,
              missionNumber: 1,
              missionCount: 1,
            ));
        break;

      case LearningStageActivityType.boss:
        if (stage.bossStage != null) {
          Get.to(() => BossBattleScreen(stage: stage.bossStage!));
        }
        break;
    }
  }

  Future<bool> openHanziStage({int? chapterNumber, String? unitId}) async {
    final stage = await _journeyRepo.getCurrentStageForActivities(
      {LearningStageActivityType.hanzi},
      unitId: unitId,
    );
    if (stage != null && !stage.isLocked) {
      launchStage(stage, chapterNumber: chapterNumber);
      return true;
    }
    _openRadicalBuilder();
    return false;
  }

  Future<bool> openListeningStage({int? chapterNumber, String? unitId}) async {
    final stage = await _journeyRepo.getCurrentStageForActivities(
      {LearningStageActivityType.listening},
      unitId: unitId,
    );
    if (stage != null && !stage.isLocked) {
      launchStage(stage, chapterNumber: chapterNumber);
      return true;
    }
    _openToneNinja();
    return false;
  }

  Future<bool> openSentenceStage({int? chapterNumber, String? unitId}) async {
    final stage = await _journeyRepo.getCurrentStageForActivities(
      {
        LearningStageActivityType.sentence,
        LearningStageActivityType.dialogue,
      },
      unitId: unitId,
    );
    if (stage != null && !stage.isLocked) {
      launchStage(stage, chapterNumber: chapterNumber);
      return true;
    }
    _openRestaurant();
    return false;
  }

  Future<bool> openSpeakingStage({int? chapterNumber, String? unitId}) async {
    final stage = await _journeyRepo.getCurrentStageForActivities(
      {LearningStageActivityType.speaking},
      unitId: unitId,
    );
    if (stage != null && !stage.isLocked) {
      launchStage(stage, chapterNumber: chapterNumber);
      return true;
    }
    _openQuickAnswer();
    return false;
  }

  Future<bool> openQuickAnswerStage({
    int? chapterNumber,
    String? unitId,
  }) async {
    final stage = await _journeyRepo.getCurrentStageForActivities(
      {
        LearningStageActivityType.speaking,
        LearningStageActivityType.quiz,
      },
      unitId: unitId,
    );
    if (stage != null && !stage.isLocked) {
      launchStage(stage, chapterNumber: chapterNumber);
      return true;
    }
    _openQuickAnswer();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final menu = _buildGameMenu();
    if (embedded) return menu;
    return HomeTabScaffold(
      backgroundColor: homeCream,
      body: menu,
      currentIndex: 2,
      onTabSelected: _selectTab,
    );
  }

  Widget _buildGameMenu() {
    if (!Get.isRegistered<HomeController>()) {
      return _buildGameView();
    }
    return Obx(() {
      final journey = Get.find<HomeController>().journey.value;
      return _buildGameView(
        chapterNumber: journey?.chapterNumber,
        completedMissions: journey?.completedMissions,
        totalMissions: journey?.totalMissions,
        stars: journey?.stars,
      );
    });
  }

  Widget _buildGameView({
    int? chapterNumber,
    int? completedMissions,
    int? totalMissions,
    int? stars,
  }) {
    return GameHubView(
      onBossBattle: _openBossBattle,
      onRadicalBuilder: () => openHanziStage(chapterNumber: chapterNumber),
      onToneNinja: () => openListeningStage(chapterNumber: chapterNumber),
      onRestaurant: () => openSentenceStage(chapterNumber: chapterNumber),
      onQuickAnswer: () => openQuickAnswerStage(chapterNumber: chapterNumber),
      onStageMap: _openStageMap,
      chapterNumber: chapterNumber,
      completedMissions: completedMissions,
      totalMissions: totalMissions,
      stars: stars,
    );
  }
}
