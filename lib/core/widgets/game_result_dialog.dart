import 'package:flutter/material.dart';

import '../theme/game_visual_tokens.dart';
import 'app_green_button.dart';

/// Popup kết thúc mini-game dùng chung (theme kem + xanh lá).
class GameResultDialog extends StatelessWidget {
  const GameResultDialog({
    super.key,
    required this.title,
    required this.message,
    required this.score,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
    this.xp,
    this.isVictory = true,
  });

  /// Tiêu đề, có thể kèm emoji ở đầu (ví dụ '🎉 Hoàn thành!').
  final String title;
  final String message;
  final int score;
  final int? xp;
  final bool isVictory;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  static const _ink = Color(0xFF342E10);
  static const _muted = Color(0xFF5D5C54);
  static const _line = Color(0xFFF1E6CF);

  @override
  Widget build(BuildContext context) {
    // Tách emoji đầu tiêu đề để hiển thị thành huy hiệu lớn.
    final parts = title.split(' ');
    final hasEmoji =
        parts.length > 1 && !RegExp(r'[A-Za-zÀ-ỹ0-9]').hasMatch(parts.first);
    final emoji = hasEmoji ? parts.first : (isVictory ? '🎉' : '💔');
    final heading = hasEmoji ? parts.skip(1).join(' ') : title;
    final accent =
        isVictory ? GameVisualTokens.primaryGreen : GameVisualTokens.crimson;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFDF6), Color(0xFFFFF1D6)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                    color: accent.withValues(alpha: .45), width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: .25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 38)),
            ),
            const SizedBox(height: 14),
            Text(
              heading,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _muted,
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    label: 'Điểm số',
                    value: '$score',
                    icon: Icons.star_rounded,
                    color: GameVisualTokens.gold,
                  ),
                ),
                if (xp != null && xp! > 0) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatBox(
                      label: 'Kinh nghiệm',
                      value: '+$xp XP',
                      icon: Icons.bolt_rounded,
                      color: GameVisualTokens.primaryGreen,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            AppGreenButton(
              label: primaryLabel,
              icon: Icons.replay_rounded,
              onPressed: onPrimary,
              height: 50,
              expand: true,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                onPressed: onSecondary,
                style: OutlinedButton.styleFrom(
                  foregroundColor: GameVisualTokens.primaryGreenDark,
                  backgroundColor: Colors.white,
                  side: const BorderSide(
                      color: GameVisualTokens.primaryGreen, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                child: Text(secondaryLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
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
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GameResultDialog._line),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  color: GameResultDialog._ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: GameResultDialog._muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}
