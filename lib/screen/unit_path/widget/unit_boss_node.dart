import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../model/unit_learning_node.dart';

class UnitBossNode extends StatelessWidget {
  const UnitBossNode({
    super.key,
    required this.node,
    required this.onTap,
  });

  final UnitLearningNode node;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locked = node.state == UnitLearningNodeState.locked;
    final completed = node.state == UnitLearningNodeState.completed;

    return Semantics(
      button: true,
      enabled: !locked,
      label: '${node.gameName}, ${locked ? 'đang khóa' : 'có thể chiến đấu'}',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: locked
                ? const [Color(0xFF5D5550), Color(0xFF393432)]
                : const [Color(0xFFB82419), Color(0xFF6E160F)],
          ),
          border: Border.all(
            color: locked
                ? const Color(0xFF8A827C)
                : const Color(0xFFFFCA62),
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(17, 14, 14, 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: Image.asset(
                      'assets/images/characters/dragon_fire.png',
                      fit: BoxFit.contain,
                      color: locked
                          ? Colors.grey.withValues(alpha: .72)
                          : null,
                      colorBlendMode:
                          locked ? BlendMode.saturation : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          completed ? 'BOSS ĐÃ BỊ HẠ' : 'BOSS CUỐI CHƯƠNG',
                          style: TextStyle(
                            color: locked
                                ? Colors.white60
                                : const Color(0xFFFFD374),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .7,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          node.bossName ?? node.gameName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          locked
                              ? 'Hoàn thành các nhiệm vụ để mở cổng Boss.'
                              : node.gameDescription,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            const Icon(
                              Icons.favorite_rounded,
                              size: 14,
                              color: Color(0xFFFF9187),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${node.bossHp ?? 0} HP',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (node.stars > 0)
                              Text(
                                '★' * node.stars,
                                style: const TextStyle(
                                  color: Color(0xFFFFD45A),
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    locked ? Icons.lock_rounded : Icons.swords,
                    color: locked
                        ? Colors.white54
                        : const Color(0xFFFFD374),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
