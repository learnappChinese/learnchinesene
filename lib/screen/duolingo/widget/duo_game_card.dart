import 'package:flutter/material.dart';

class DuoGameCard extends StatelessWidget {
  const DuoGameCard(
      {super.key,
      required this.nameVi,
      required this.descVi,
      required this.totalLevels,
      required this.completedLevels,
      required this.bestStars,
      required this.iconData,
      required this.gameColor,
      required this.onTap});
  final String nameVi;
  final String descVi;
  final int totalLevels;
  final int completedLevels;
  final int bestStars;
  final IconData iconData;
  final Color gameColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: gameColor.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: gameColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, color: gameColor, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nameVi.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          descVi,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      color: Colors.grey, size: 18),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tiến trình: $completedLevels / $totalLevels Cấp độ',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  if (bestStars > 0)
                    Row(
                      children: List.generate(3, (starIdx) {
                        return Icon(
                          starIdx < bestStars
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 18,
                        );
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: totalLevels > 0 ? (completedLevels / totalLevels) : 0,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  color: gameColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
