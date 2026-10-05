import 'package:flutter/material.dart';

class DuoStageNode extends StatelessWidget {
  final int stageNumber;
  final String nameVi;
  final String icon;
  final String status; // 'available', 'completed', 'locked'
  final int stars;
  final VoidCallback onTap;

  const DuoStageNode({
    super.key,
    required this.stageNumber,
    required this.nameVi,
    required this.icon,
    required this.status,
    required this.stars,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLocked = status == 'locked';
    final bool isCompleted = status == 'completed';

    Color nodeBgColor = isLocked
        ? Colors.grey.shade300
        : isCompleted
            ? Colors.green
            : Colors.amber.shade700;

    Color shadowColor = isLocked
        ? Colors.grey.shade500
        : isCompleted
            ? Colors.green.shade800
            : Colors.amber.shade900;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: isLocked ? null : onTap,
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: nodeBgColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  offset: const Offset(0, 6),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Center(
              child: isLocked
                  ? const Icon(Icons.lock_rounded, color: Colors.grey, size: 32)
                  : Text(
                      icon,
                      style: const TextStyle(fontSize: 34),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Màn $stageNumber: $nameVi',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isLocked ? Colors.grey : Colors.black87,
                ),
              ),
              if (isCompleted) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    return Icon(
                      index < stars
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
