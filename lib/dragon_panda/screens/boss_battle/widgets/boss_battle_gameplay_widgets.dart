import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/answer_button.dart';

class BossBattleTopBar extends StatelessWidget {
  const BossBattleTopBar({
    super.key,
    required this.bossHp,
    required this.maxBossHp,
    required this.onExit,
    required this.onSpeak,
  });

  final int bossHp;
  final int maxBossHp;
  final VoidCallback onExit;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _CircleIconButton(
              icon: Icons.pause_rounded,
              onPressed: onExit,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Lv. 3',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF4A1000),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Rồng Lửa',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 4),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$bossHp/$maxBossHp',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFFCC80),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0x66FF8A65),
                          width: 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (bossHp / maxBossHp).clamp(0.0, 1.0),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFFF1744),
                                Color(0xFFFF5252),
                                Color(0xFFFF8A65),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _CircleIconButton(
              icon: Icons.volume_up_rounded,
              onPressed: onSpeak,
            ),
          ],
        ),
      ),
    );
  }
}

class BossBattleArenaHud extends StatelessWidget {
  const BossBattleArenaHud({
    super.key,
    required this.playerHp,
    required this.maxPlayerHp,
    required this.combo,
  });

  final int playerHp;
  final int maxPlayerHp;
  final int combo;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 14,
      right: 14,
      bottom: 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xB3181124),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.24),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGold,
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/characters/panda_avatar.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text('🐼', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$playerHp / $maxPlayerHp',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 80,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (playerHp / maxPlayerHp).clamp(0.0, 1.0),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF00E676),
                                Color(0xFF69F0AE),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF7A00), Color(0xFFFF3D00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF3D00).withValues(alpha: 0.55),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text(
                  'Combo x$combo',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BossBattleQuestionPanel extends StatelessWidget {
  const BossBattleQuestionPanel({
    super.key,
    required this.prompt,
    required this.hanziPrompt,
    required this.options,
    required this.correctIndex,
    required this.selectedAnswerIndex,
    required this.feedbackText,
    required this.onSpeak,
    required this.onAnswer,
  });

  final String prompt;
  final String hanziPrompt;
  final List<Map<String, dynamic>> options;
  final int correctIndex;
  final int? selectedAnswerIndex;
  final String? feedbackText;
  final ValueChanged<String> onSpeak;
  final ValueChanged<int> onAnswer;

  AnswerButtonState _answerState(int index) {
    if (selectedAnswerIndex != index) return AnswerButtonState.idle;
    return index == correctIndex
        ? AnswerButtonState.correct
        : AnswerButtonState.wrong;
  }

  Widget _answer(int index) {
    final option = options[index];
    return AnswerButton(
      text: option['hanzi'] as String,
      subtitle: option['pinyin'] as String,
      state: _answerState(index),
      onTap: () => onAnswer(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF9F6F0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (feedbackText case final feedback?)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(
                color: feedback == 'Chính xác!'
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFC62828),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                feedback,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          InkWell(
            onTap: () => onSpeak(hanziPrompt),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.volume_up_rounded,
                      color: Color(0xFF0284C7),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    prompt,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Text(
            'Hãy chọn đáp án đúng',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF757575),
            ),
          ),
          Row(
            children: [
              if (options.isNotEmpty) _answer(0),
              const SizedBox(width: 10),
              if (options.length > 1) _answer(1),
            ],
          ),
          Row(
            children: [
              if (options.length > 2) _answer(2),
              const SizedBox(width: 10),
              if (options.length > 3) _answer(3),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: onPressed,
      ),
    );
  }
}
