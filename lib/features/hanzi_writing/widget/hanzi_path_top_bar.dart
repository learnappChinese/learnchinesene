import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/game_visual_tokens.dart';
import '../../../core/widgets/app_back_button.dart';
import '../controller/hanzi_learning_path_controller.dart';

/// Thanh trạng thái trên cùng của Lộ trình học viết chữ Hán.
/// Hiển thị thông số thực từ SQLite: XP, Streak, Số chữ đã thuộc, và bộ lọc nhanh HSK.
class HanziPathTopBar extends StatelessWidget {
  final HanziLearningPathController controller;

  const HanziPathTopBar({super.key, required this.controller});

  static const _line = Color(0xFFE8E1D6);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.homeCardLine)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Dòng thông số chính: Nút Trở về, Avatar Panda, XP, Streak, Mastered Hanzi
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  AppBackButton(
                    size: 40,
                    tooltip: 'Trở về',
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Get.back();
                      }
                    },
                  ),
                  const SizedBox(width: 8),

                  // Avatar Panda linh vật
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.homeShadow,
                          blurRadius: 8,
                          offset: Offset(0, 3),
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
                        icon: Icons.bolt_rounded,
                        value: '${controller.totalXp.value}',
                        label: 'XP',
                        color: AppColors.imperialGold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Huy hiệu Streak ngày học liên tục
                  Expanded(
                    child: Obx(
                      () => _buildStatChip(
                        icon: Icons.local_fire_department_rounded,
                        value: '${controller.currentStreak.value}',
                        label: 'ngày',
                        color: GameVisualTokens.crimson,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Huy hiệu số chữ Hán đã thành thạo
                  Expanded(
                    child: Obx(
                      () => _buildStatChip(
                        icon: Icons.draw_rounded,
                        value: '${controller.totalMasteredCount.value}',
                        label: 'chữ',
                        color: AppColors.homeGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bộ lọc chọn cấp độ HSK ngang
            SizedBox(
              height: 46,
              child: Obx(() {
                final selected = controller.selectedHskFilter.value;
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
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

  /// Ô thông số trắng phẳng, icon màu trong vòng tròn nhạt.
  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color.lerp(color, Colors.black, .15),
                      ),
                    ),
                    TextSpan(
                      text: ' $label',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.homeSubtitle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Chip lọc HSK: đang chọn nền xanh nhạt viền xanh, còn lại nền trắng.
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 6, top: 2),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          // Chip chọn: phẳng, không gờ — chỉ nút hành động mới nổi khối.
          decoration: BoxDecoration(
            color: isSelected ? AppColors.homeGreenSoft : Colors.white,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: isSelected ? AppColors.homeGreen : _line,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: isSelected
                  ? AppColors.homeGreenText
                  : AppColors.homeSubtitle,
            ),
          ),
        ),
      ),
    );
  }
}
