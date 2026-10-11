import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/history_service.dart';
import '../../core/theme/app_colors.dart';
import 'controller/history_controller.dart';
import 'widget/history_content.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.controller});

  final HistoryController? controller;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final HistoryController controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      controller = widget.controller!;
    } else if (Get.isRegistered<HistoryController>()) {
      controller = Get.find<HistoryController>();
    } else {
      controller = Get.put(HistoryController());
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController && Get.isRegistered<HistoryController>()) {
      Get.delete<HistoryController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Lịch sử & Hoạt động',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          Obx(() {
            // Only allow clearing local AI utility logs; official learning ledger is preserved
            if (controller.selectedTab.value == 1 &&
                controller.aiHistoryItems.isNotEmpty) {
              return IconButton(
                onPressed: _handleClearAiHistory,
                icon: const Icon(Icons.delete_sweep_rounded,
                    color: AppColors.red),
                tooltip: 'Xóa lịch sử công cụ AI',
              );
            }
            return const SizedBox();
          }),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildTabSelector(),
            Expanded(child: _buildHistoryContent(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Obx(() {
        final currentTab = controller.selectedTab.value;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: _buildTabButton(
                  index: 0,
                  label: 'Lịch sử học tập',
                  icon: Icons.school_rounded,
                  isSelected: currentTab == 0,
                ),
              ),
              Expanded(
                child: _buildTabButton(
                  index: 1,
                  label: 'Lịch sử công cụ AI',
                  icon: Icons.auto_awesome_rounded,
                  isSelected: currentTab == 1,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => controller.switchTab(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.red : AppColors.muted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppColors.ink : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(dynamic rawTime) {
    if (rawTime == null) return '';
    try {
      final date = DateTime.parse('$rawTime').toLocal();
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} • ${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '$rawTime';
    }
  }

  void _showHistoryDetail(BuildContext context, HistoryItem item) {
    Get.bottomSheet(
      HistoryDetailSheet(type: item.type, content: item.content),
      isScrollControlled: true,
    );
  }

  void _handleClearAiHistory() {
    Get.defaultDialog(
      title: 'Xóa lịch sử công cụ AI',
      middleText:
          'Bạn có chắc chắn muốn xóa toàn bộ lịch sử công cụ AI? Tiến độ và điểm XP học tập chính thức sẽ được bảo lưu an toàn.',
      textConfirm: 'Xóa',
      textCancel: 'Hủy',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.red,
      onConfirm: () {
        Get.back();
        controller.clearAiHistory();
      },
    );
  }

  Widget _buildHistoryContent(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final isOfficialTab = controller.selectedTab.value == 0;

      if (isOfficialTab) {
        return _buildOfficialLearningList();
      } else {
        return _buildAiUtilityList(context);
      }
    });
  }

  Widget _buildOfficialLearningList() {
    final items = controller.learningItems;

    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_edu_rounded, size: 70, color: AppColors.muted),
              SizedBox(height: 12),
              Text(
                'Chưa có lịch sử học tập chính thức',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                    fontSize: 16),
              ),
              SizedBox(height: 6),
              Text(
                'Các lượt hoàn thành bài học, khiêu chiến Boss và luyện tập Unit sẽ xuất hiện tại đây.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_rounded,
                    size: 16, color: AppColors.success),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tiến độ và điểm kinh nghiệm chính thức từ server.',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        }
        final item = items[index - 1];
        return LearningAttemptTile(
          attempt: item,
          timeLabel: _formatTime(item['timestamp']),
        );
      },
    );
  }

  Widget _buildAiUtilityList(BuildContext context) {
    final items = controller.aiHistoryItems;

    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome_outlined,
                  size: 70, color: AppColors.muted),
              SizedBox(height: 12),
              Text(
                'Chưa có lịch sử công cụ AI',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                    fontSize: 16),
              ),
              SizedBox(height: 6),
              Text(
                'Lịch sử dịch thuật, tra từ điển, hội thoại tự do và thi thử HSK sẽ hiển thị ở đây.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: AppColors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lịch sử tiện ích công cụ AI cục bộ (không tính điểm XP lộ trình).',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.orange,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        }
        final item = items[index - 1];
        return HistoryItemTile(
          key: ValueKey(item.id),
          item: item,
          timeLabel: _formatTime(item.timestamp),
          onTap: () => _showHistoryDetail(context, item),
        );
      },
    );
  }
}
