import 'package:flutter/material.dart';
import '../../../core/widgets/app_shimmer.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/game_visual_tokens.dart';
import '../../../core/widgets/learning_scaffold.dart';
import '../../../core/widgets/learning_scene_background.dart';
import '../controller/flashcards_settings_controller.dart';
import '../models/flashcard_models.dart';

/// Màn hình Cài đặt thuật toán FSRS và tùy chọn học Flashcard.
class FlashcardSettingsScreen extends StatefulWidget {
  const FlashcardSettingsScreen({super.key});

  @override
  State<FlashcardSettingsScreen> createState() => _FlashcardSettingsScreenState();
}

class _FlashcardSettingsScreenState extends State<FlashcardSettingsScreen> {
  late final FlashcardsSettingsController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(FlashcardsSettingsController());
  }

  @override
  void dispose() {
    Get.delete<FlashcardsSettingsController>();
    super.dispose();
  }

  static const _line = Color(0xFFE8E1D6);

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: 'Cài đặt ôn tập',
      body: LearningSceneBackground(
        theme: LearningSceneTheme.bambooVillage,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const _FlashcardSettingsSkeleton();
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // 1. Nhóm cấu hình nhanh (Presets)
              _buildSectionCard(
                icon: Icons.tune_rounded,
                color: AppColors.homeGreen,
                title: 'Chế độ học đề xuất',
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildPresetChip('Nhẹ nhàng'),
                        const SizedBox(width: 8),
                        _buildPresetChip('Cân bằng'),
                        const SizedBox(width: 8),
                        _buildPresetChip('Chuyên sâu'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildNote(
                      'Chế độ "Cân bằng" được tối ưu theo nghiên cứu FSRS: '
                      '90% tỷ lệ nhớ mục tiêu, khoảng 20 thẻ mới mỗi ngày.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Tỷ lệ nhớ mong muốn (Desired Retention)
              _buildSectionCard(
                icon: Icons.psychology_rounded,
                color: GameVisualTokens.blue,
                title: 'Mức ghi nhớ mục tiêu',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Tỷ lệ nhớ mong muốn',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.homeTitle,
                            ),
                          ),
                        ),
                        _buildValuePill(
                          '${(controller.desiredRetention.value * 100).toInt()}%',
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.homeGreen,
                        inactiveTrackColor: const Color(0xFFEDE5D6),
                        thumbColor: AppColors.homeGreen,
                        overlayColor:
                            AppColors.homeGreen.withValues(alpha: .14),
                        activeTickMarkColor: Colors.white70,
                        inactiveTickMarkColor: const Color(0xFFD8CFBF),
                        trackHeight: 6,
                      ),
                      child: Slider(
                        value: controller.desiredRetention.value,
                        min: 0.75,
                        max: 0.97,
                        divisions: 22,
                        onChanged: (val) {
                          controller.desiredRetention.value = val;
                          controller.saveSettings();
                        },
                      ),
                    ),
                    _buildNote(
                      'Mức ghi nhớ càng cao thì chu kỳ ôn tập càng dày đặc hơn.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Giới hạn số lượng thẻ
              _buildSectionCard(
                icon: Icons.style_rounded,
                color: AppColors.imperialGold,
                title: 'Giới hạn thẻ mỗi ngày',
                child: Column(
                  children: [
                    _buildDropdownRow(
                      label: 'Thẻ mới tối đa',
                      value: controller.newCardsPerDay.value,
                      items: const [5, 10, 20, 30, 50],
                      onChanged: (val) {
                        if (val != null) {
                          controller.newCardsPerDay.value = val;
                          controller.saveSettings();
                        }
                      },
                    ),
                    const Divider(height: 24, color: AppColors.homeCardLine),
                    _buildDropdownRow(
                      label: 'Lượt ôn tối đa',
                      value: controller.maxReviewsPerDay.value,
                      items: const [50, 100, 150, 200, 500],
                      onChanged: (val) {
                        if (val != null) {
                          controller.maxReviewsPerDay.value = val;
                          controller.saveSettings();
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Hướng học mặc định
              _buildSectionCard(
                icon: Icons.swap_horiz_rounded,
                color: GameVisualTokens.orange,
                title: 'Hướng học mặc định',
                child: Column(
                  children: [
                    _buildDirectionOption(
                      FlashcardDirection.zhToVi,
                      'Trung → Việt',
                      'Mặt trước là chữ Hán',
                    ),
                    const SizedBox(height: 8),
                    _buildDirectionOption(
                      FlashcardDirection.viToZh,
                      'Việt → Trung',
                      'Mặt trước là nghĩa tiếng Việt',
                    ),
                    const SizedBox(height: 8),
                    _buildDirectionOption(
                      FlashcardDirection.listenToMeaning,
                      'Nghe → Đoán',
                      'Mặt trước là âm thanh',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5. Tùy chọn âm thanh
              _buildSectionCard(
                icon: Icons.volume_up_rounded,
                color: GameVisualTokens.crimson,
                title: 'Âm thanh',
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Tự động phát âm khi lật thẻ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.homeTitle,
                        ),
                      ),
                    ),
                    Switch(
                      value: controller.autoPlayAudio.value,
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.homeGreen,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: const Color(0xFFDDD5C6),
                      trackOutlineColor:
                          const WidgetStatePropertyAll(Colors.transparent),
                      onChanged: (val) {
                        controller.autoPlayAudio.value = val;
                        controller.saveSettings();
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  /// Thẻ nhóm: tiêu đề có icon tròn màu, nội dung bên dưới.
  Widget _buildSectionCard({
    required IconData icon,
    required Color color,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14635D3B),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.homeInk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  /// Ghi chú nhỏ trên nền kem.
  Widget _buildNote(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F2E8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12.5,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: AppColors.homeBody,
          ),
        ),
      );

  Widget _buildValuePill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.homeGreenSoft,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: AppColors.homeGreenText,
          ),
        ),
      );

  /// Chip chọn chế độ: phẳng, chọn thì nền xanh nhạt viền xanh.
  Widget _buildPresetChip(String preset) {
    final isSelected = controller.currentPreset.value == preset;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.applyPreset(preset),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.homeGreenSoft : Colors.white,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: isSelected ? AppColors.homeGreen : _line,
              width: 1.5,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                preset,
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
        ),
      ),
    );
  }

  Widget _buildDropdownRow({
    required String label,
    required int value,
    required List<int> items,
    required ValueChanged<int?> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.homeTitle,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(left: 12, right: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _line, width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isDense: true,
              borderRadius: BorderRadius.circular(14),
              dropdownColor: Colors.white,
              icon: const Icon(Icons.expand_more_rounded,
                  color: AppColors.homeGreen),
              padding: const EdgeInsets.symmetric(vertical: 8),
              items: items.map((i) {
                return DropdownMenuItem<int>(
                  value: i,
                  child: Text(
                    '$i thẻ',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.homeTitle,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  /// Ô lựa chọn hướng học: phẳng, chọn thì nền xanh nhạt viền xanh.
  Widget _buildDirectionOption(
    FlashcardDirection direction,
    String title,
    String subtitle,
  ) {
    final isSelected = controller.cardDirection.value == direction;
    return Material(
      color: isSelected ? AppColors.homeGreenSoft : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected ? AppColors.homeGreen : _line,
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          controller.cardDirection.value = direction;
          controller.saveSettings();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: isSelected
                            ? AppColors.homeGreenText
                            : AppColors.homeTitle,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.homeSubtitle,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected ? AppColors.homeGreen : _line,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Khung đang tải khớp màn cài đặt: các thẻ nhóm có tiêu đề kèm icon.
class _FlashcardSettingsSkeleton extends StatelessWidget {
  const _FlashcardSettingsSkeleton();

  @override
  Widget build(BuildContext context) => AppShimmer(
        child: ListView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: const [
            _SettingsCardSkeleton(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: SkeletonPill(height: 42)),
                      SizedBox(width: 8),
                      Expanded(child: SkeletonPill(height: 42)),
                      SizedBox(width: 8),
                      Expanded(child: SkeletonPill(height: 42)),
                    ],
                  ),
                  SizedBox(height: 12),
                  ShimmerBox(height: 52, radius: 12),
                ],
              ),
            ),
            SizedBox(height: 16),
            _SettingsCardSkeleton(
              child: Column(
                children: [
                  Row(
                    children: [
                      ShimmerBox(width: 140, height: 14),
                      Spacer(),
                      SkeletonPill(width: 52, height: 26),
                    ],
                  ),
                  SizedBox(height: 20),
                  ShimmerBox(height: 6, radius: 99),
                  SizedBox(height: 20),
                  ShimmerBox(height: 38, radius: 12),
                ],
              ),
            ),
            SizedBox(height: 16),
            _SettingsCardSkeleton(
              child: Column(
                children: [
                  _RowSkeleton(),
                  SizedBox(height: 24),
                  _RowSkeleton(),
                ],
              ),
            ),
            SizedBox(height: 16),
            _SettingsCardSkeleton(
              child: Column(
                children: [
                  ShimmerBox(height: 56, radius: 14),
                  SizedBox(height: 8),
                  ShimmerBox(height: 56, radius: 14),
                  SizedBox(height: 8),
                  ShimmerBox(height: 56, radius: 14),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SettingsCardSkeleton extends StatelessWidget {
  const _SettingsCardSkeleton({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SkeletonCard(
        radius: 20,
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Row(
              children: [
                ShimmerBox.circle(size: 28),
                SizedBox(width: 10),
                ShimmerBox(width: 150, height: 16),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );
}

class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();

  @override
  Widget build(BuildContext context) => const Row(
        children: [
          ShimmerBox(width: 110, height: 14),
          Spacer(),
          ShimmerBox(width: 88, height: 36, radius: 12),
        ],
      );
}
