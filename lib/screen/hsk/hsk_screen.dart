import 'package:flutter/material.dart';
import 'widget/hsk_level_card.dart';
import 'package:get/get.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/responsive/responsive_layout.dart';
import '../unit/unit_screen.dart';
import 'controller/hsk_controller.dart';
import '../../core/models/hsk_level.dart';
import '../../core/widgets/learning_scene_background.dart';
import '../subscription/controller/subscription_controller.dart';
import '../../core/helper/upgrade_dialog_helper.dart';

class HskScreen extends StatefulWidget {
  const HskScreen({super.key});

  @override
  State<HskScreen> createState() => _HskScreenState();
}

class _HskScreenState extends State<HskScreen> {
  late final HskController controller;

  @override
  void initState() {
    super.initState();
    // The existing GetX route owns this registration.
    controller = Get.isRegistered<HskController>()
        ? Get.find<HskController>()
        : Get.put(HskController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bản đồ thế giới',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: LearningSceneBackground(
        theme: LearningSceneTheme.bambooVillage,
        child: _buildLevelCatalog(context),
      ),
    );
  }

  Widget _buildLevelMetrics(
      BuildContext context, HskLevel level, int index, bool isUnlocked) {
    return FutureBuilder<List<Object>>(
      key: ValueKey(level.id),
      future: controller.metricsFor(level.id),
      builder: (context, snapshot) => HskLevelCard(
        level: level,
        index: index,
        count: snapshot.hasData ? snapshot.data![0] as int : 0,
        progress: snapshot.hasData ? snapshot.data![1] as double : 0,
        isUnlocked: isUnlocked,
        onTap: () {
          if (isUnlocked) {
            Get.to(
              () => const UnitScreen(),
              arguments: {
                'hskLevelId': level.id,
                'hskTitle': level.title,
                'hskOrder': level.order,
              },
            );
          } else {
            UpgradeDialogHelper.showUpgradeDialog(
              context: context,
              title: 'Mở khóa HSK ${level.order}',
              message:
                  'Tính năng này yêu cầu nâng cấp gói cước để học toàn bộ từ vựng cấp độ HSK ${level.order}.',
              benefits: level.order <= 3
                  ? ['Học toàn bộ từ vựng HSK 1-3', 'Lưu tiến độ trên đám mây']
                  : [
                      'Mở khóa toàn bộ HSK 1-6',
                      'Hội thoại AI không giới hạn',
                      'Thi thử HSK với AI'
                    ],
            );
          }
        },
      ),
    );
  }

  Widget _buildLevelCatalog(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const _WorldLoadingState();
      }
      if (controller.hasError.value) {
        return _WorldErrorState(
          onRetry: controller.loadLevels,
        );
      }
      final levels = controller.levels;
      if (levels.isEmpty) {
        return const EmptyStateWidget(
          icon: Icons.layers_outlined,
          title: 'Chưa có cấp độ',
          message: 'Không tìm thấy cấp độ HSK trong cơ sở dữ liệu.',
        );
      }
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: ResponsiveHelper.contentMaxWidth(context)),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.horizontalPadding(context),
              vertical: 24,
            ),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: _WorldHeader(worldCount: levels.length),
                  ),
                ),
                SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 450,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    mainAxisExtent: 218,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Obx(() {
                      final level = levels[index];
                      final subController = Get.find<SubscriptionController>();
                      final isUnlocked =
                          subController.isLevelUnlocked(level.order);
                      return _buildLevelMetrics(
                          context, level, index, isUnlocked);
                    }),
                    childCount: levels.length,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _WorldHeader extends StatelessWidget {
  const _WorldHeader({required this.worldCount});

  final int worldCount;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .82),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFFD98B)),
        ),
        child: Row(children: [
          const Icon(Icons.map_rounded, size: 42, color: Color(0xFF0F766E)),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CHỌN ĐIỂM ĐẾN',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        letterSpacing: .4)),
                const SizedBox(height: 3),
                Text(
                  '$worldCount thế giới đang chờ Panda và bạn khám phá.',
                  style: const TextStyle(color: Color(0xFF776A67), height: 1.3),
                ),
              ],
            ),
          ),
        ]),
      );
}

class _WorldLoadingState extends StatelessWidget {
  const _WorldLoadingState();

  @override
  Widget build(BuildContext context) => ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, __) => Container(
          height: 218,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .55),
            borderRadius: BorderRadius.circular(26),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF0F766E)),
          ),
        ),
      );
}

class _WorldErrorState extends StatelessWidget {
  const _WorldErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded,
                size: 54, color: Color(0xFF991B1B)),
            const SizedBox(height: 12),
            const Text('Không thể mở bản đồ thế giới',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text('Kiểm tra kết nối rồi thử lại.',
                style: TextStyle(color: Color(0xFF776A67))),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('THỬ LẠI'),
            ),
          ]),
        ),
      );
}
