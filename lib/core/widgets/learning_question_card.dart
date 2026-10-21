import 'package:flutter/material.dart';

import '../theme/game_visual_tokens.dart';

/// Thẻ câu hỏi dùng chung của các màn học: nền kem, viền trắng, đầu thẻ có
/// pill tên màn chơi, câu hướng dẫn và một phần tử góc phải (thường là panda).
class LearningQuestionCard extends StatelessWidget {
  const LearningQuestionCard({
    super.key,
    required this.child,
    this.stageLabel,
    this.instruction,
    this.trailing,
  });

  final Widget child;
  final String? stageLabel;
  final String? instruction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final hasHeader =
        stageLabel != null || instruction != null || trailing != null;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFDF6), Color(0xFFFFF4DE)],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2E635D3B),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasHeader) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: LearningStageHeader(
                      stageLabel: stageLabel,
                      instruction: instruction,
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),
              const SizedBox(height: 10),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// Pill tên màn chơi màu xanh + câu hướng dẫn đậm bên dưới.
class LearningStageHeader extends StatelessWidget {
  const LearningStageHeader({super.key, this.stageLabel, this.instruction});

  final String? stageLabel;
  final String? instruction;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stageLabel != null)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    GameVisualTokens.primaryGreenLight,
                    GameVisualTokens.primaryGreen,
                  ],
                ),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                child: Text(
                  stageLabel!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          if (stageLabel != null && instruction != null)
            const SizedBox(height: 8),
          if (instruction != null)
            Text(
              instruction!,
              style: const TextStyle(
                color: Color(0xFF342E10),
                fontSize: 19,
                height: 1.25,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      );
}
