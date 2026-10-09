import 'package:flutter/material.dart';
import '../widget/duo_answer_feedback.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../controller/duo_game_runner_controller.dart';
import 'package:flash_learn_chinese/core/models/duo_challenge.dart';
import '../../../core/models/duo_flashcard.dart';
import '../widget/duo_flashcard_widget.dart';
import '../widget/duo_word_connect_widget.dart';
import '../widget/duo_speaking_widget.dart';
import '../widget/duo_sentence_builder_widget.dart';
import '../widget/duo_multiple_choice_widget.dart';
import '../../../core/widgets/learning_scaffold.dart';
import '../../../core/widgets/learning_scene_background.dart';
import '../../../core/widgets/mission_progress_header.dart';
import '../../../core/widgets/mission_complete_overlay.dart';
import '../../../core/widgets/panda_companion.dart';
import '../../../core/widgets/mission_intro.dart';

class DuoGameRunnerScreen extends StatefulWidget {
  final int gameId;
  final String gameCode;
  final String levelId;
  final String gameName;
  final int chapterNumber;
  final int missionNumber;
  final int missionCount;

  const DuoGameRunnerScreen({
    super.key,
    required this.gameId,
    required this.gameCode,
    required this.levelId,
    required this.gameName,
    this.chapterNumber = 1,
    this.missionNumber = 1,
    this.missionCount = 1,
  });

  @override
  State<DuoGameRunnerScreen> createState() => _DuoGameRunnerScreenState();
}

class _DuoGameRunnerScreenState extends State<DuoGameRunnerScreen> {
  late final DuoGameRunnerController controller;

  @override
  void initState() {
    super.initState();
    final tag = '${widget.gameId}_${widget.levelId}';
    controller = Get.put(
      DuoGameRunnerController(
        gameId: widget.gameId,
        gameCode: widget.gameCode,
        levelId: widget.levelId,
      ),
      tag: tag,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: widget.gameName,
      actions: [
        Obx(() => Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text(
                  'Điểm: ${controller.score.value}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            )),
      ],
      body: LearningSceneBackground(
        theme: LearningSceneTheme.neutralCream,
        showMountains: false,
        child: Column(children: [
          MissionProgressHeader(
            chapterNumber: widget.chapterNumber,
            current: widget.missionNumber,
            total: widget.missionCount,
          ),
          Expanded(child: _buildChallengeContent(context)),
        ]),
      ),
    );
  }

  Widget _buildGameplay(dynamic challenge) {
    Widget gameplayWidget;
    if (widget.gameCode == 'learn_words') {
      gameplayWidget = DuoFlashcardWidget(
        key: ValueKey((challenge as DuoFlashcard).id),
        flashcard: challenge,
        isAnswered: controller.isAnsweredCorrectly.value != null,
        onCheck: controller.submitAnswer,
      );
    } else if (widget.gameCode == 'word_connect') {
      gameplayWidget = DuoWordConnectWidget(
        pairs: List<Map<String, String>>.from(controller.challenges),
        isAnswered: controller.isAnsweredCorrectly.value != null,
        onCheck: controller.submitAnswer,
      );
    } else if (widget.gameCode == 'speaking') {
      gameplayWidget = DuoSpeakingWidget(
        key: ValueKey((challenge as DuoChallenge).id),
        challenge: challenge,
        isAnswered: controller.isAnsweredCorrectly.value != null,
        onCheck: controller.submitSpeakingResult,
      );
    } else if (widget.gameCode == 'translate' ||
        widget.gameCode == 'listen_select' ||
        widget.gameCode == 'sentence_order') {
      gameplayWidget = DuoSentenceBuilderWidget(
        key: ValueKey((challenge as DuoChallenge).id),
        challenge: challenge,
        isAnswered: controller.isAnsweredCorrectly.value != null,
        onCheck: controller.submitAnswer,
      );
    } else {
      gameplayWidget = DuoMultipleChoiceWidget(
        key: ValueKey((challenge as DuoChallenge).id),
        challenge: challenge,
        isAnswered: controller.isAnsweredCorrectly.value != null,
        onCheck: controller.submitAnswer,
      );
    }

    return gameplayWidget;
  }

  Widget _buildChallengeContent(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.errorMessage.value != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PandaCompanion(size: 88, mood: PandaMood.encourage),
                const SizedBox(height: 12),
                Text(
                  controller.errorMessage.value!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 20),
                LearningPrimaryButton(
                  label: 'THỬ LẠI',
                  icon: Icons.refresh_rounded,
                  onPressed: controller.initSession,
                ),
              ],
            ),
          ),
        );
      }

      if (controller.showMissionIntro.value &&
          controller.challenges.isNotEmpty) {
        return MissionIntro(
          title: widget.gameName,
          objective:
              'Hoàn thành ${controller.challenges.length} thử thách • Cần 70% để qua màn',
          rewardText: 'Phần thưởng: XP + Mastery',
          onStart: controller.startMission,
        );
      }

      // 1. Khi hoàn thành -> Show Completion Screen
      if (controller.isCompleted.value) {
        final result = controller.rewardResult.value;
        if (result == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return Center(
          child: MissionCompleteOverlay(
            result: result,
            onNextMission:
                result.passed ? () => Get.back() : controller.retrySession,
            onBackToMap: () => Get.back(),
          ),
        );
      }

      if (controller.challenges.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 80, color: Colors.grey),
                const SizedBox(height: 24),
                const Text(
                  'CHƯA ĐỦ DỮ LIỆU',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Cấp độ này hiện chưa có đủ dữ liệu câu hỏi từ database. Vui lòng quay lại và thử cấp độ hoặc trò chơi khác nhé!',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(200, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('QUAY LẠI',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      }

      final challenge = controller.challenges[controller.currentIndex.value];

      final gameplayWidget = _buildGameplay(challenge);

      return Column(
        children: [
          // Progress Bar (không hiển thị cho game nối chữ vì chỉ có 1 màn chơi duy nhất)
          if (widget.gameCode != 'word_connect')
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (controller.currentIndex.value + 1) /
                      controller.challenges.length,
                  minHeight: 12,
                  backgroundColor: Colors.grey.shade200,
                  color: AppColors.success,
                ),
              ),
            ),

          Expanded(child: gameplayWidget),

          // Bottom Sheet thông báo kết quả
          if (controller.isAnsweredCorrectly.value != null)
            DuoAnswerFeedback(
                correct: controller.isAnsweredCorrectly.value!,
                solution:
                    challenge is DuoChallenge ? challenge.solutions : null,
                onContinue: controller.nextChallenge),
        ],
      );
    });
  }
}
