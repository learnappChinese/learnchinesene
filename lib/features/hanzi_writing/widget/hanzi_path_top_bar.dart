import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/game_visual_tokens.dart';
import '../controller/hanzi_learning_path_controller.dart';

/// Thanh trạng thái trên cùng của Lộ trình học viết chữ Hán.
/// Hiển thị thông số thực từ SQLite: XP, Streak, Số chữ đã thuộc, và bộ lọc nhanh HSK.
class HanziPathTopBar extends StatelessWidget {
  final HanziLearningPathController controller;

  const HanziPathTopBar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Dòng thông số chính: Nút Trở về, Avatar Panda, XP, Streak, Mastered Hanzi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Nút Trở về
                  IconButton(
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Get.back();
                      }
                    },
                    icon: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: Color(0xFF334155),
                      ),
                    ),
                    tooltip: 'Trở về',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),

                  // Avatar Panda linh vật
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: GameVisualTokens.primaryGreenLight,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: GameVisualTokens.primaryGreen
                              .withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/characters/panda_avatar.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Text('🐼', style: TextStyle(fontSize: 20)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Huy hiệu XP
                  Expanded(
                    child: Obx(
                      () => _buildStatChip(
                        icon: '⚡',
                        value: '${controller.totalXp.value}',
                        label: 'XP',
                        color: const Color(0xFFF59E0B),
                        bgColor: const Color(0xFFFEF3C7),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Huy hiệu Streak ngày học liên tục
                  Expanded(
                    child: Obx(
                      () => _buildStatChip(
                        icon: '🔥',
                        value: '${controller.currentStreak.value}',
                        label: 'ngày',
                        color: const Color(0xFFEF4444),
                        bgColor: const Color(0xFFFEE2E2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Huy hiệu số chữ Hán đã thành thạo
                  Expanded(
                    child: Obx(
                      () => _buildStatChip(
                        icon: '✍️',
                        value: '${controller.totalMasteredCount.value}',
                        label: 'chữ',
                        color: GameVisualTokens.primaryGreenDark,
                        bgColor: GameVisualTokens.primaryGreenSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bộ lọc chọn cấp độ HSK ngang
            SizedBox(
              height: 44,
              child: Obx(() {
                final selected = controller.selectedHskFilter.value;
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFilterChip(
                      label: 'Tất cả',
                      isSelected: selected == 0,
                      onTap: () => controller.setHskFilter(0),
                    ),
                    for (int i = 1; i <= 6; i++)
                      _buildFilterChip(
                        label: 'HSK $i',
                        isSelected: selected == i,
                        onTap: () => controller.setHskFilter(i),
                      ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required String icon,
    required String value,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 4),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? GameVisualTokens.primaryGreen
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? GameVisualTokens.primaryGreenDark
                  : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: GameVisualTokens.primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }
}
