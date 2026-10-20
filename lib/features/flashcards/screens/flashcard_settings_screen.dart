import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/game_visual_tokens.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Cài đặt ôn tập FSRS',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: GameVisualTokens.primaryGreen,
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Nhóm cấu hình nhanh (Presets)
            _buildSectionCard(
              title: 'CHẾ ĐỘ HỌC ĐỀ XUẤT',
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
                  const SizedBox(height: 10),
                  const Text(
                    'Chế độ "Cân bằng" được tối ưu theo nghiên cứu FSRS: 90% tỷ lệ nhớ mục tiêu, khoảng 20 thẻ mới mỗi ngày.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Tỷ lệ nhớ mong muốn (Desired Retention)
            _buildSectionCard(
              title: 'MỨC ĐỘ GHI NHỚ MỤC TIÊU (DESIRED RETENTION)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tỷ lệ nhớ mong muốn:',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${(controller.desiredRetention.value * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: GameVisualTokens.primaryGreenDark,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: controller.desiredRetention.value,
                    min: 0.75,
                    max: 0.97,
                    divisions: 22,
                    activeColor: GameVisualTokens.primaryGreen,
                    onChanged: (val) {
                      controller.desiredRetention.value = val;
                      controller.saveSettings();
                    },
                  ),
                  const Text(
                    'Mức ghi nhớ càng cao thì chu kỳ ôn tập càng dày đặc hơn.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Giới hạn số lượng thẻ
            _buildSectionCard(
              title: 'GIỚI HẠN THẺ MỖI NGÀY',
              child: Column(
                children: [
                  _buildDropdownRow(
                    label: 'Số thẻ mới tối đa mỗi ngày:',
                    value: controller.newCardsPerDay.value,
                    items: const [5, 10, 20, 30, 50],
                    onChanged: (val) {
                      if (val != null) {
                        controller.newCardsPerDay.value = val;
                        controller.saveSettings();
                      }
                    },
                  ),
                  const Divider(height: 24),
                  _buildDropdownRow(
                    label: 'Lượt ôn tối đa mỗi ngày:',
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
              title: 'HƯỚNG HỌC MẶC ĐỊNH',
              child: Column(
                children: [
                  RadioListTile<FlashcardDirection>(
                    title: const Text('Trung → Việt (Mặt trước chữ Hán)'),
                    value: FlashcardDirection.zhToVi,
                    groupValue: controller.cardDirection.value,
                    activeColor: GameVisualTokens.primaryGreen,
                    onChanged: (val) {
                      if (val != null) {
                        controller.cardDirection.value = val;
                        controller.saveSettings();
                      }
                    },
                  ),
                  RadioListTile<FlashcardDirection>(
                    title: const Text('Việt → Trung (Mặt trước nghĩa tiếng Việt)'),
                    value: FlashcardDirection.viToZh,
                    groupValue: controller.cardDirection.value,
                    activeColor: GameVisualTokens.primaryGreen,
                    onChanged: (val) {
                      if (val != null) {
                        controller.cardDirection.value = val;
                        controller.saveSettings();
                      }
                    },
                  ),
                  RadioListTile<FlashcardDirection>(
                    title: const Text('Nghe → Đoán (Mặt trước nghe âm thanh)'),
                    value: FlashcardDirection.listenToMeaning,
                    groupValue: controller.cardDirection.value,
                    activeColor: GameVisualTokens.primaryGreen,
                    onChanged: (val) {
                      if (val != null) {
                        controller.cardDirection.value = val;
                        controller.saveSettings();
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. Tùy chọn âm thanh
            _buildSectionCard(
              title: 'TÙY CHỌN ÂM THANH',
              child: SwitchListTile(
                title: const Text(
                  'Tự động phát âm thanh khi lật thẻ',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                value: controller.autoPlayAudio.value,
                activeTrackColor: GameVisualTokens.primaryGreenLight,
                activeThumbColor: GameVisualTokens.primaryGreen,
                onChanged: (val) {
                  controller.autoPlayAudio.value = val;
                  controller.saveSettings();
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildPresetChip(String preset) {
    final isSelected = controller.currentPreset.value == preset;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.applyPreset(preset),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? GameVisualTokens.primaryGreen
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? GameVisualTokens.primaryGreenDark
                  : const Color(0xFFCBD5E1),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            preset,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : const Color(0xFF334155),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        DropdownButton<int>(
          value: value,
          underline: const SizedBox(),
          items: items.map((i) {
            return DropdownMenuItem<int>(
              value: i,
              child: Text(
                '$i thẻ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
