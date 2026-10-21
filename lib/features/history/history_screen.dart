import 'package:flutter/material.dart';
import '../../core/widgets/app_shimmer.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/config/feature_flags.dart';
import '../../core/services/history_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/game_visual_tokens.dart';
import '../../core/widgets/app_back_button.dart';
import 'controller/history_controller.dart';
import 'widget/history_content.dart';
import '../home/widgets/home_decorations.dart';

const _kHeroImage = 'assets/images/backgrounds/progress_history.png';
const _kPandaImage = 'assets/images/characters/home_panda_peek.png';

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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        // Nội dung cuộn tràn xuống đáy, khoảng đệm nằm ở cuối danh sách.
        body: Column(
          children: [
            _buildHeroWithStats(context),
            _buildTabSelector(),
            Expanded(child: _buildHistoryContent(context)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeroWithStats(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final heroHeight = topInset + 168;
    const statsOverlap = 40.0;

    return SizedBox(
      height: heroHeight + statsOverlap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: heroHeight,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _kHeroImage,
                    fit: BoxFit.cover,
                    alignment: const Alignment(.9, 0),
                    errorBuilder: (_, __, ___) => const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.red, AppColors.redDark],
                        ),
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x40000000),
                          Color(0x14000000),
                          Color(0xD91F1A0C),
                        ],
                        stops: [0, .35, 1],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 52),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppBackButton(onPressed: () => Get.back<void>()),
                            const Spacer(),
                            Obx(() {
                              // Chỉ cho xoá lịch sử công cụ AI cục bộ;
                              // lịch sử học tập chính thức luôn được giữ.
                              if (controller.selectedTab.value == 1 &&
                                  controller.aiHistoryItems.isNotEmpty) {
                                return _GlassIconButton(
                                  icon: Icons.delete_sweep_rounded,
                                  tooltip: 'Xóa lịch sử công cụ AI',
                                  onPressed: _handleClearAiHistory,
                                );
                              }
                              return const SizedBox.shrink();
                            }),
                          ],
                        ),
                        const Spacer(),
                        const Text(
                          'Lịch sử & Hoạt động',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(color: Color(0x99000000), blurRadius: 10),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Nhìn lại hành trình học tiếng Trung của bạn',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .9),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            shadows: const [
                              Shadow(color: Color(0x99000000), blurRadius: 8),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(left: 16, right: 16, bottom: 0, child: _buildStatsCard()),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8E1D6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0x24635D3B),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Obx(() {
        final learning = controller.learningItems;
        final xp = learning.fold<int>(0, (sum, item) => sum + _xpOf(item));
        return Row(
          children: [
            _HistoryStat(
              icon: Icons.menu_book_rounded,
              value: '${learning.length}',
              label: 'Lượt học',
              color: GameVisualTokens.primaryGreenDark,
            ),
            const _StatDivider(),
            _HistoryStat(
              icon: Icons.bolt_rounded,
              value: '$xp',
              label: 'XP nhận được',
              color: AppColors.orange,
            ),
            if (FeatureFlags.enableAi) ...[
              const _StatDivider(),
              _HistoryStat(
                icon: Icons.auto_awesome_rounded,
                value: '${controller.aiHistoryItems.length}',
                label: 'Công cụ AI',
                color: const Color(0xFF2E93E8),
              ),
            ],
          ],
        );
      }),
    );
  }

  static int _xpOf(Map<String, dynamic> item) =>
      (item['xpEarned'] ?? item['xp_amount'] as num?)?.toInt() ?? 0;

  // ---------------------------------------------------------------------------
  // Tabs
  // ---------------------------------------------------------------------------

  Widget _buildTabSelector() {
    if (!FeatureFlags.enableAi) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Obx(() {
        final currentTab = controller.selectedTab.value;
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFEFE7E1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildTabButton(
                  index: 0,
                  label: 'Học tập',
                  icon: Icons.school_rounded,
                  count: controller.learningItems.length,
                  isSelected: currentTab == 0,
                ),
              ),
              Expanded(
                child: _buildTabButton(
                  index: 1,
                  label: 'Công cụ AI',
                  icon: Icons.auto_awesome_rounded,
                  count: controller.aiHistoryItems.length,
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
    required int count,
    required bool isSelected,
  }) {
    final foreground = isSelected ? Colors.white : AppColors.muted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => controller.switchTab(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    GameVisualTokens.primaryGreenLight,
                    GameVisualTokens.primaryGreen,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: GameVisualTokens.primaryGreen.withValues(alpha: .3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: foreground),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                  color: foreground,
                ),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: .25)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Content
  // ---------------------------------------------------------------------------

  DateTime? _parseTime(dynamic rawTime) {
    if (rawTime == null) return null;
    return DateTime.tryParse('$rawTime')?.toLocal();
  }

  String _formatClock(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Hôm qua';
    return '${date.day}/${date.month}/${date.year}';
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
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.delete_sweep_rounded,
          color: AppColors.red,
          size: 36,
        ),
        title: const Text(
          'Xóa lịch sử công cụ AI?',
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Toàn bộ lịch sử dịch, tra từ và hội thoại AI sẽ bị xóa. Tiến độ và điểm XP học tập chính thức vẫn được giữ nguyên.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              controller.clearAiHistory();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red,
              minimumSize: const Size(110, 46),
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryContent(BuildContext context) {
    return Obx(() {
      final isOfficialTab =
          !FeatureFlags.enableAi || controller.selectedTab.value == 0;
      final isEmpty = isOfficialTab
          ? controller.learningItems.isEmpty
          : controller.aiHistoryItems.isEmpty;

      // Khi đã có dữ liệu thì giữ danh sách lúc kéo để làm mới.
      if (controller.isLoading.value && isEmpty) {
        return const _HistoryListSkeleton();
      }

      return RefreshIndicator(
        color: GameVisualTokens.primaryGreen,
        onRefresh: controller.loadHistory,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isOfficialTab
              ? _buildOfficialLearningList()
              : _buildAiUtilityList(context),
        ),
      );
    });
  }

  Widget _buildOfficialLearningList() {
    final items = controller.learningItems;

    if (items.isEmpty) {
      return const _HistoryEmptyState(
        key: ValueKey('learning-empty'),
        title: 'Chưa có lịch sử học tập',
        message:
            'Hoàn thành bài học, khiêu chiến Boss hoặc luyện tập Unit để bắt đầu ghi lại hành trình của bạn.',
        hints: ['📖 Bài học', '🐉 Boss', '🎯 Luyện tập'],
      );
    }

    // Gom các lượt học theo ngày, chèn nhãn ngày trước lượt đầu tiên mỗi ngày.
    final rows = <Widget>[];
    String? lastDay;
    for (final item in items) {
      final date = _parseTime(item['timestamp']);
      final day = date == null ? '' : _dayLabel(date);
      if (day.isNotEmpty && day != lastDay) {
        rows.add(_HistoryDayHeader(label: day, isFirst: lastDay == null));
        lastDay = day;
      }
      rows.add(
        LearningAttemptTile(
          attempt: item,
          timeLabel: date == null
              ? _formatTime(item['timestamp'])
              : _formatClock(date),
        ),
      );
    }

    return ListView(
      key: const ValueKey('learning-list'),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        24 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      children: rows,
    );
  }

  Widget _buildAiUtilityList(BuildContext context) {
    final items = controller.aiHistoryItems;

    if (items.isEmpty) {
      return const _HistoryEmptyState(
        key: ValueKey('ai-empty'),
        title: 'Chưa có lịch sử công cụ AI',
        message:
            'Lịch sử dịch thuật, tra từ điển, hội thoại tự do và thi thử HSK sẽ hiển thị ở đây.',
        hints: ['🌐 Dịch thuật', '📕 Từ điển', '💬 Hội thoại'],
      );
    }

    return ListView.builder(
      key: const ValueKey('ai-list'),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        24 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const _HistoryNote(
            icon: Icons.info_outline_rounded,
            color: AppColors.orange,
            text:
                'Lịch sử công cụ AI lưu trên máy (không tính điểm XP lộ trình).',
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

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .28),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: .45)),
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _HistoryStat extends StatelessWidget {
  const _HistoryStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.homeSubtitle,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Nhãn ngày giữa danh sách lịch sử: "Hôm nay", "Hôm qua" hoặc ngày cụ thể.
class _HistoryDayHeader extends StatelessWidget {
  const _HistoryDayHeader({required this.label, required this.isFirst});

  final String label;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(2, isFirst ? 6 : 10, 2, 10),
      child: Row(
        children: [
          const HomePandaFace(size: 24),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.homeInk,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Divider(color: Color(0xFFE8E1D6), thickness: 1.5),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: const Color(0xFFEFE7E1));
  }
}

class _HistoryNote extends StatelessWidget {
  const _HistoryNote({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.hints,
  });

  final String title;
  final String message;
  final List<String> hints;

  @override
  Widget build(BuildContext context) {
    // Cuộn được để vẫn kéo xuống làm mới khi danh sách trống.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 132,
                  height: 132,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFFFFF4E4), Color(0xFFFBE3D0)],
                    ),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB4232C).withValues(alpha: .12),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    _kPandaImage,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text('🐼', style: TextStyle(fontSize: 56)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final hint in hints)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: const Color(0xFFEFE7E1)),
                        ),
                        child: Text(
                          hint,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Khung đang tải khớp danh sách lịch sử: nhãn ngày và các thẻ lượt học.
class _HistoryListSkeleton extends StatelessWidget {
  const _HistoryListSkeleton();

  @override
  Widget build(BuildContext context) => AppShimmer(
        child: ListView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(2, 6, 2, 10),
              child: Row(
                children: [
                  ShimmerBox.circle(size: 24),
                  SizedBox(width: 8),
                  ShimmerBox(width: 72, height: 16),
                  SizedBox(width: 10),
                  Expanded(
                    child: Divider(color: Color(0xFFE8E1D6), thickness: 1.5),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < 10; i++) ...[
              const SkeletonListTile(trailingPillWidth: 58),
              const SizedBox(height: 12),
            ],
          ],
        ),
      );
}
