import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/game_visual_tokens.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/widgets/chapter_header_banner.dart';
import '../../core/widgets/adventure_node.dart';
import '../../core/widgets/boss_gate_card.dart';
import '../../core/widgets/learning_scene_background.dart';
import '../quiz/quiz_screen.dart';
import '../speaking/speaking_screen.dart';
import '../word_list/word_list_screen.dart';
import '../conversations/conversations_screen.dart';
import '../hanzi_writing/screens/hanzi_writing_home_screen.dart';
import '../duolingo/duo_game_center_screen.dart';
import '../dragon_panda/screens/boss_battle/boss_battle_gameplay_screen.dart';
import 'controller/learning_overview_controller.dart';

class LearningOverviewScreen extends StatefulWidget {
  const LearningOverviewScreen({super.key});

  @override
  State<LearningOverviewScreen> createState() => _LearningOverviewScreenState();
}

class _LearningOverviewScreenState extends State<LearningOverviewScreen> {
  late final LearningOverviewController controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<LearningOverviewController>()
        ? Get.find<LearningOverviewController>()
        : Get.put(LearningOverviewController());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _go(Widget screen, int unitId, String title) {
    Get.to(
      () => screen,
      arguments: {'unitId': unitId, 'unitTitle': title},
    );
  }

  void _scrollToBoss() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildSteppingConnector(double fromOffset, double toOffset) {
    return SizedBox(
      height: 38,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.translate(
              offset: Offset((fromOffset + toOffset) * 0.25, 0),
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: GameVisualTokens.gold.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: Color(0x33000000), blurRadius: 4),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Transform.translate(
              offset: Offset((fromOffset + toOffset) * 0.5, 0),
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: GameVisualTokens.imperialGold,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x4D000000), blurRadius: 6),
                  ],
                ),
                child: const Center(
                  child: Text('✦',
                      style: TextStyle(
                          color: Colors.white, fontSize: 8, height: 1)),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Transform.translate(
              offset: Offset((fromOffset + toOffset) * 0.75, 0),
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: GameVisualTokens.gold.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: Color(0x33000000), blurRadius: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: LearningSceneBackground(
        theme: LearningSceneTheme.bambooVillage,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final m = controller.metrics;
      final words = m['words'] ?? 0;
      final examples = m['examples'] ?? 0;

      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: ResponsiveHelper.contentMaxWidth(context)),
          child: ListView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(
              ResponsiveHelper.horizontalPadding(context),
              12,
              ResponsiveHelper.horizontalPadding(context),
              40,
            ),
            children: [
              // Chapter Header Banner
              ChapterHeaderBanner(
                chapterNumber: controller.unitId,
                chineseTitle: controller.title,
                vietnameseTitle:
                    'Chương ${controller.unitId} • Hành Trình Tu Luyện',
                objectives: [
                  'Học $words từ vựng cốt lõi',
                  'Luyện $examples câu đàm thoại',
                  'Vượt ải phát âm',
                  'Chiến thắng Boss Rồng',
                ],
              ),
              const SizedBox(height: 20),

              // Title for Adventure Map
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: GameVisualTokens.gold.withValues(alpha: 0.6),
                        width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('🗺️', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 8),
                      Text(
                        'LỘ TRÌNH PHIÊU LƯU CHƯƠNG',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                          color: GameVisualTokens.templeWood,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Node 1: Learn words (offset -45)
              AdventureNode(
                type: AdventureNodeType.learn,
                state: AdventureNodeState.inProgress,
                title: 'Học từ vựng',
                stars: 3,
                isActive: true,
                horizontalOffset: -45.0,
                onTap: () => _go(const WordListScreen(), controller.unitId,
                    controller.title),
              ),
              _buildSteppingConnector(-45, 45),

              // Node 2: Listening (offset +45)
              AdventureNode(
                type: AdventureNodeType.listening,
                state: AdventureNodeState.available,
                title: 'Luyện nghe',
                stars: 2,
                horizontalOffset: 45.0,
                onTap: () => Get.to(() => const ConversationsScreen()),
              ),
              _buildSteppingConnector(45, -35),

              // Node 3: Select Quiz (offset -35)
              AdventureNode(
                type: AdventureNodeType.select,
                state: AdventureNodeState.available,
                title: 'Trắc nghiệm',
                stars: 1,
                horizontalOffset: -35.0,
                onTap: () =>
                    _go(const QuizScreen(), controller.unitId, controller.title),
              ),
              _buildSteppingConnector(-35, 40),

              // Node 4: Hanzi Writing (offset +40)
              AdventureNode(
                type: AdventureNodeType.hanzi,
                state: AdventureNodeState.available,
                title: 'Viết Hán tự',
                stars: 2,
                horizontalOffset: 40.0,
                onTap: () => Get.to(() => const HanziWritingHomeScreen()),
              ),
              _buildSteppingConnector(40, -30),

              // Node 5: Speaking NPC (offset -30)
              AdventureNode(
                type: AdventureNodeType.speaking,
                state: AdventureNodeState.available,
                title: 'Luyện phát âm',
                stars: 2,
                horizontalOffset: -30.0,
                onTap: () => _go(const SpeakingScreen(), controller.unitId,
                    controller.title),
              ),
              _buildSteppingConnector(-30, 35),

              // Node 6: Dialogue RPG (offset +35)
              AdventureNode(
                type: AdventureNodeType.dialogue,
                state: AdventureNodeState.available,
                title: 'Đối thoại NPC',
                stars: 1,
                horizontalOffset: 35.0,
                onTap: () => Get.to(() => const ConversationsScreen()),
              ),
              _buildSteppingConnector(35, -15),

              // Node 7: Mini game (offset -15)
              AdventureNode(
                type: AdventureNodeType.game,
                state: AdventureNodeState.available,
                title: 'Đấu trường Mini',
                stars: 3,
                horizontalOffset: -15.0,
                onTap: () => Get.to(() => const DuoGameCenterScreen()),
              ),
              _buildSteppingConnector(-15, 0),

              // Node 8: Boss Gate Node (offset 0)
              AdventureNode(
                type: AdventureNodeType.boss,
                state: AdventureNodeState.available,
                title: 'Cửa Boss',
                stars: 0,
                horizontalOffset: 0.0,
                onTap: _scrollToBoss,
              ),

              const SizedBox(height: 28),

              // Boss Gate Card
              BossGateCard(
                bossName: 'Hỏa Diệm Long • Rồng Lửa',
                bossLevel: controller.unitId > 0 ? controller.unitId : 1,
                vocabMastery: 0.85,
                listeningMastery: 0.75,
                speakingMastery: 0.70,
                isUnlocked: true,
                onFight: () => Get.to(
                  () => BossBattleGameplayScreen(
                    stageLevel: controller.unitId > 0 ? controller.unitId : 1,
                    stageTitle: controller.title,
                    bossName: 'Hỏa Diệm Long',
                    onVictory: () {
                      Get.back();
                      Get.snackbar('Chiến thắng!', 'Bạn đã hạ gục Boss!');
                    },
                    onDefeat: () => Get.back(),
                    onExit: () => Get.back(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
