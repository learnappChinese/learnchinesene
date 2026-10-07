import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/game_visual_tokens.dart';
import '../../../core/widgets/game_progress_hud.dart';
import '../../../core/widgets/learning_scene_background.dart';
import '../../../core/widgets/mission_intro.dart';
import '../../../core/widgets/panda_companion.dart';
import '../controller/vocabulary_adventure_controller.dart';
import '../model/vocabulary_adventure.dart';
import '../widget/vocabulary_feedback_panel.dart';
import '../widget/vocabulary_gameplay_card.dart';

class VocabularyAdventureScreen extends GetView<VocabularyAdventureController> {
  const VocabularyAdventureScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(controller.gameName),
          backgroundColor: GameVisualTokens.parchment,
          foregroundColor: GameVisualTokens.ink,
        ),
        body: LearningSceneBackground(
          theme: LearningSceneTheme.bambooVillage,
          child: Obx(() => _buildState(context)),
        ),
      );

  Widget _buildState(BuildContext context) {
    if (controller.isLoading.value) return const _VocabularyLoading();
    if (controller.errorMessage.value != null) {
      return _VocabularyMessage(
        icon: Icons.cloud_off_rounded,
        title: controller.errorMessage.value!,
        action: 'THỬ LẠI',
        onTap: controller.loadMission,
      );
    }

    final mission = controller.mission.value;
    if (mission == null || mission.events.isEmpty) {
      return _VocabularyMessage(
        icon: Icons.menu_book_rounded,
        title:
            'Mission này chưa có đủ từ và ví dụ trong curriculum để bắt đầu.',
        action: 'TẢI LẠI',
        onTap: controller.loadMission,
      );
    }
    if (controller.isCompleted.value) {
      return _VocabularyMissionComplete(
        stars: controller.stars,
        xp: controller.xpEarned.value,
        accuracy: controller.accuracy,
        bestCombo: controller.bestCombo.value,
        masteredWords: controller.masteredWords.value,
        onNext: () => Get.back(result: true),
        onBack: () => Get.back(result: true),
      );
    }
    if (controller.isIntroVisible.value) {
      return MissionIntro(
        title: mission.title,
        objective: mission.objective,
        rewardText:
            '${mission.words.length} từ • tối đa ${mission.events.fold<int>(0, (sum, event) => sum + event.xpReward)} XP',
        onStart: controller.startMission,
      );
    }

    final event = controller.currentEvent;
    if (event == null) {
      return _VocabularyMessage(
        icon: Icons.route_rounded,
        title: 'Không thể xác định thử thách hiện tại.',
        action: 'THỬ LẠI',
        onTap: controller.loadMission,
      );
    }
    return _buildGameplay(event);
  }

  Widget _buildGameplay(VocabularyGameplayEvent event) => Column(
        children: [
          GameProgressHud(
            currentStep: controller.visibleStep,
            totalSteps: controller.totalSteps,
            xp: controller.xpEarned.value,
            combo: controller.combo.value,
            stageLabel: event.stageLabel,
          ),
          if (controller.syncWarning.value case final warning?)
            Material(
              color: GameVisualTokens.goldLight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_sync_rounded, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        warning,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: controller.clearSyncWarning,
                      tooltip: 'Đóng',
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
              child: Center(
                child: VocabularyGameplayCard(
                  key: ValueKey(event.id),
                  event: event,
                  selectedAnswer: controller.selectedAnswer.value,
                  feedback: controller.feedback.value,
                  onAnswer: controller.submitAnswer,
                  onSpeak: controller.speakCurrent,
                  onSpeakSlow: () => controller.speakCurrent(slow: true),
                  onCompleteDiscovery: controller.completeDiscovery,
                ),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: controller.feedback.value == null
                ? const SizedBox.shrink()
                : VocabularyFeedbackPanel(
                    key: ValueKey(
                      '${event.id}-${controller.feedback.value}',
                    ),
                    feedback: controller.feedback.value!,
                    event: event,
                    combo: controller.combo.value,
                    isBusy: controller.isFinishing.value,
                    onContinue: controller.continueAfterFeedback,
                    onRetry: controller.retryCurrent,
                  ),
          ),
        ],
      );
}

class _VocabularyMissionComplete extends StatelessWidget {
  const _VocabularyMissionComplete({
    required this.stars,
    required this.xp,
    required this.accuracy,
    required this.bestCombo,
    required this.masteredWords,
    required this.onNext,
    required this.onBack,
  });

  final int stars;
  final int xp;
  final int accuracy;
  final int bestCombo;
  final int masteredWords;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: GameVisualTokens.night,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: GameVisualTokens.imperialGold,
                  width: 2,
                ),
                boxShadow: GameVisualTokens.gameShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'MISSION COMPLETE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: GameVisualTokens.goldLight,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => Icon(
                        index < stars
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: GameVisualTokens.imperialGold,
                        size: 40,
                      ),
                    ),
                  ),
                  const PandaCompanion(
                    mood: PandaMood.victory,
                    size: 118,
                    speechText: 'Bạn đã biến từ mới thành kỹ năng rồi!',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _RewardMetric(label: 'XP', value: '+$xp'),
                      _RewardMetric(label: 'CHÍNH XÁC', value: '$accuracy%'),
                      _RewardMetric(label: 'COMBO', value: 'x$bestCombo'),
                      _RewardMetric(
                        label: 'TỪ MASTERED',
                        value: '$masteredWords',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onNext,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('NEXT MISSION'),
                      style: FilledButton.styleFrom(
                        backgroundColor: GameVisualTokens.jade,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onBack,
                    child: const Text(
                      'BACK TO MAP',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _RewardMetric extends StatelessWidget {
  const _RewardMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        width: 112,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: GameVisualTokens.goldLight,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}

class _VocabularyLoading extends StatelessWidget {
  const _VocabularyLoading();

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                const PandaCompanion(
                  mood: PandaMood.thinking,
                  size: 110,
                  speechText: 'Panda đang chuẩn bị cuộn từ vựng…',
                ),
                const SizedBox(height: 18),
                Container(
                  height: 260,
                  decoration: BoxDecoration(
                    color: Colors.white60,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: GameVisualTokens.goldLight),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _VocabularyMessage extends StatelessWidget {
  const _VocabularyMessage({
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 58, color: GameVisualTokens.crimsonDark),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: GameVisualTokens.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: onTap, child: Text(action)),
            ],
          ),
        ),
      );
}
