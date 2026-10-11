import 'package:flutter/material.dart';
import 'widget/hsk_level_card.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
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
          'Chọn cấp độ HSK',
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
              arguments: {'hskLevelId': level.id, 'hskTitle': level.title},
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
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.hasError.value) {
        return const EmptyStateWidget(
          icon: Icons.cloud_off_rounded,
          title: 'Không thể tải cấp độ',
          message: 'Không thể mở dữ liệu bài học ngoại tuyến.',
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
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Text(
                      'Học theo lộ trình HSK với tốc độ của riêng bạn. Mọi bài học đều dùng được ngoại tuyến.',
                      style: TextStyle(color: AppColors.muted, height: 1.5),
                    ),
                  ),
                ),
                SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 450,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    mainAxisExtent: 125,
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
