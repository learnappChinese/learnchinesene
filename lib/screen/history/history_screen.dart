import 'package:flutter/material.dart';
import 'widget/history_content.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/history_service.dart';
import 'controller/history_controller.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final HistoryController controller;

  @override
  void initState() {
    super.initState();
    // GetX retains the existing route ownership and cleanup.
    controller = Get.isRegistered<HistoryController>()
        ? Get.find<HistoryController>()
        : Get.put(HistoryController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Lịch sử & Phân tích',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _handleClearHistory,
            icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.red),
            tooltip: 'Xóa tất cả',
          )
        ],
      ),
      body: SafeArea(
        child: _buildHistoryContent(context),
      ),
    );
  }

  String _formatTime(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} - ${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return isoString;
    }
  }

  void _showHistoryDetail(BuildContext context, HistoryItem item) {
    final type = item.type;
    final content = item.content;

    Get.bottomSheet(
      HistoryDetailSheet(type: type, content: content),
      isScrollControlled: true,
    );
  }

  void _handleClearHistory() {
    Get.defaultDialog(
      title: 'Xóa lịch sử',
      middleText: 'Bạn có chắc chắn muốn xóa toàn bộ lịch sử học tập?',
      textConfirm: 'Xóa',
      textCancel: 'Hủy',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.red,
      onConfirm: () {
        Get.back();
        controller.clearAll();
      },
    );
  }

  Widget _buildHistoryContent(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.historyItems.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_toggle_off_rounded,
                  size: 70, color: AppColors.muted),
              SizedBox(height: 12),
              Text(
                'Chưa có lịch sử học tập',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
              SizedBox(height: 6),
              Text(
                'Lịch sử dịch thuật, hội thoại và thi thử của bạn sẽ xuất hiện ở đây.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: controller.historyItems.length,
        itemBuilder: (context, index) {
          final item = controller.historyItems[index];
          return HistoryItemTile(
              key: ValueKey(item.id),
              item: item,
              timeLabel: _formatTime(item.timestamp),
              onTap: () => _showHistoryDetail(context, item));
        },
      );
    });
  }
}
