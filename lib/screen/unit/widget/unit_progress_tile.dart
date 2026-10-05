import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/unit_model.dart';

class UnitProgressTile extends StatelessWidget {
  const UnitProgressTile(
      {super.key,
      required this.unit,
      required this.number,
      required this.words,
      required this.learned,
      required this.onTap});
  final UnitModel unit;
  final int number;
  final int words;
  final int learned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = words == 0 ? 0.0 : learned / words;
    final status = p >= 1
        ? 'Đã thành thạo'
        : p > 0
            ? 'Đang học'
            : 'Mới';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE9E5),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: AppColors.red,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unit.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$words từ  •  $status',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 9),
                    LinearProgressIndicator(
                      value: p,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(p * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.red,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
