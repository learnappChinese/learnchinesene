import 'package:flutter/material.dart';

import '../../../../../core/widgets/app_back_button.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/answer_button.dart';

class BossBattleTopBar extends StatelessWidget {
  const BossBattleTopBar({
    super.key,
    required this.bossHp,
    required this.maxBossHp,
    this.level = 3,
    this.bossName = 'Rồng Lửa',
    required this.onExit,
  });

  final int bossHp;
  final int maxBossHp;
  final int level;
  final String bossName;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            AppBackButton(onPressed: onExit),
            _buildBossStatus(),
            // Giữ thanh máu boss nằm giữa, cân với nút back bên trái.
            const SizedBox(width: kAppBackButtonSize),
          ],
        ),
      ),
    );
  }

  Widget _buildBossStatus() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          children: [
            _buildBossLabel(),
            const SizedBox(height: 4),
            _buildBossHealthBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBossLabel() {
    return Row(
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
          child: Text(
            'Lv. $level',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Color(0xFF4A1000),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          bossName,
          style: const TextStyle(
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
    );
  }

  Widget _buildBossHealthBar() {
    return Container(
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
          _buildPlayerStatus(),
          _buildCombo(),
        ],
      ),
    );
  }

  Widget _buildPlayerStatus() {
    return Container(
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
    );
  }

  Widget _buildCombo() {
    return Container(
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

  static const _labels = ['A', 'B', 'C', 'D'];

  AnswerButtonState _answerState(int index) {
    final selected = selectedAnswerIndex;
    if (selected == null) return AnswerButtonState.idle;
    // Luôn chỉ ra đáp án đúng sau khi người chơi đã chọn.
    if (index == correctIndex) return AnswerButtonState.correct;
    if (index == selected) return AnswerButtonState.wrong;
    return AnswerButtonState.selected;
  }

  Widget _answer(int index) {
    if (index >= options.length) return const Expanded(child: SizedBox());
    final option = options[index];
    return Expanded(
      child: _BossAnswerCard(
        label: _labels[index % _labels.length],
        hanzi: option['hanzi'] as String,
        pinyin: option['pinyin'] as String?,
        state: _answerState(index),
        onTap: () => onAnswer(index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2DDD5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 10),
              _buildPromptCard(),
              const SizedBox(height: 12),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _answer(0),
                          const SizedBox(width: 12),
                          _answer(1),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _answer(2),
                          const SizedBox(width: 12),
                          _answer(3),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromptCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardCreamBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB45309).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 22,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: feedbackText == null
                        ? const Align(
                            key: ValueKey('hint'),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'CHỌN TỪ TIẾNG TRUNG ĐÚNG NGHĨA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: AppColors.amberDark,
                              ),
                            ),
                          )
                        : Align(
                            key: const ValueKey('feedback'),
                            alignment: Alignment.centerLeft,
                            child: _buildFeedbackChip(feedbackText!),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  prompt,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _HudIconButton(
            icon: Icons.volume_up_rounded,
            tooltip: 'Nghe phát âm',
            onPressed: () => onSpeak(hanziPrompt),
            size: 46,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackChip(String feedback) {
    final isCorrect = feedback == 'Chính xác!';
    final color = isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCorrect ? Icons.check_rounded : Icons.close_rounded,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            feedback,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _BossAnswerCard extends StatelessWidget {
  const _BossAnswerCard({
    required this.label,
    required this.hanzi,
    required this.pinyin,
    required this.state,
    required this.onTap,
  });

  final String label;
  final String hanzi;
  final String? pinyin;
  final AnswerButtonState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    var bgColor = Colors.white;
    var borderColor = const Color(0xFFE8E1D6);
    var depthColor = const Color(0xFFE8E1D6);
    var textColor = AppColors.textDark;
    var badgeBg = AppColors.cardCream;
    var badgeFg = AppColors.amberDark;

    switch (state) {
      case AnswerButtonState.correct:
        bgColor = const Color(0xFFE8F5E9);
        borderColor = const Color(0xFF2E7D32);
        depthColor = const Color(0xFF2E7D32);
        textColor = const Color(0xFF1B5E20);
        badgeBg = const Color(0xFF2E7D32);
        badgeFg = Colors.white;
      case AnswerButtonState.wrong:
        bgColor = const Color(0xFFFFEBEE);
        borderColor = const Color(0xFFC62828);
        depthColor = const Color(0xFFC62828);
        textColor = const Color(0xFFB71C1C);
        badgeBg = const Color(0xFFC62828);
        badgeFg = Colors.white;
      case AnswerButtonState.selected:
      case AnswerButtonState.idle:
        break;
    }

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
          width: state == AnswerButtonState.idle ? 1.5 : 2,
        ),
        boxShadow: [
          BoxShadow(color: depthColor, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: state == AnswerButtonState.idle ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: badgeBg,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: badgeFg,
                    ),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hanzi,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        if (pinyin case final pinyin? when pinyin.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              pinyin,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: state == AnswerButtonState.selected ? 0.5 : 1,
        child: card,
      ),
    );
  }
}

class _HudIconButton extends StatelessWidget {
  const _HudIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 42,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3A2130), Color(0xFF1C1020)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(size / 3),
          border: Border.all(
            color: AppColors.primaryGold.withValues(alpha: 0.55),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(size / 3 - 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Icon(icon, color: const Color(0xFFFFE7B0), size: size * .5),
          ),
        ),
      ),
    );
  }
}

/// Hộp thoại xác nhận rời trận đấu boss.
class BossBattleExitDialog extends StatelessWidget {
  const BossBattleExitDialog({super.key, required this.bossName});

  final String bossName;

  static Future<bool> show(BuildContext context, {required String bossName}) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => BossBattleExitDialog(bossName: bossName),
    ).then((value) => value ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2C1A2A), Color(0xFF170D19)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primaryGold.withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF3D00).withValues(alpha: 0.25),
              blurRadius: 24,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                border: Border.all(
                  color: const Color(0xFFFF5252).withValues(alpha: 0.5),
                ),
              ),
              child: const Icon(
                Icons.flag_rounded,
                color: Color(0xFFFF8A65),
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Rời trận đấu?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$bossName vẫn đang chờ bạn. Nếu thoát bây giờ, '
              'tiến độ trận đấu này sẽ không được lưu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9F1C), Color(0xFFFF5722)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Tiếp tục chiến đấu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withValues(alpha: 0.7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: const Text(
                  'Thoát trận',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
