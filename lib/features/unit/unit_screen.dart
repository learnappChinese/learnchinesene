import 'package:flutter/material.dart';
import '../../core/widgets/app_shimmer.dart';
import 'widget/unit_progress_tile.dart';
import 'package:get/get.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/responsive/responsive_layout.dart';
import '../unit_overview/binding/unit_overview_binding.dart';
import '../unit_overview/page/unit_overview_screen.dart';
import 'controller/unit_controller.dart';
import '../../core/models/unit_model.dart';
import '../../core/widgets/learning_scene_background.dart';
import '../../core/widgets/learning_scaffold.dart';
import '../../core/widgets/locked_mission_sheet.dart';
import '../../core/widgets/adventure_quest_banner.dart';
import '../../core/widgets/panda_companion.dart';
import '../../core/theme/game_visual_tokens.dart';

class UnitScreen extends StatefulWidget {
  const UnitScreen({super.key, this.controller});

  final UnitController? controller;

  @override
  State<UnitScreen> createState() => _UnitScreenState();
}

class _UnitScreenState extends State<UnitScreen> {
  late final UnitController controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      controller = widget.controller!;
    } else if (Get.isRegistered<UnitController>()) {
      controller = Get.find<UnitController>();
    } else {
      controller = Get.put(UnitController());
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController && Get.isRegistered<UnitController>()) {
      Get.delete<UnitController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: controller.title,
      body: LearningSceneBackground(
        theme: LearningSceneTheme.bambooVillage,
        child: _buildUnitCatalog(context),
      ),
    );
  }

  Widget _buildUnitMetrics(UnitModel unit, int fallbackNumber) {
    final unitNumber = unit.order > 0 ? unit.order : fallbackNumber;
    return FutureBuilder<Map<String, int>>(
      key: ValueKey(unit.id),
      future: controller.metricsFor(unit.id),
      builder: (context, snapshot) => UnitProgressTile(
        unit: unit,
        number: unitNumber,
        words: snapshot.data?['words'] ?? 0,
        learned: snapshot.data?['learned'] ?? 0,
        onTap: () => _openJourneyUnit(unitNumber),
      ),
    );
  }

  Future<void> _openJourneyUnit(int unitNumber) async {
    final unit = await controller.journeyUnitFor(unitNumber);
    if (!mounted) return;
    if (unit == null) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Chưa thể mở bài học'),
          content: const Text(
            'Bài từ vựng này chưa được liên kết với một ải trong hành trình.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ĐÓNG'),
            ),
          ],
        ),
      );
      return;
    }
    if (!unit.isUnlocked) {
      showLockedMissionSheet(
        context,
        title: 'Bài học chưa mở',
        message: unit.lockReason ?? 'Hoàn thành bài học trước để mở khóa.',
      );
      return;
    }
    await Get.to(
      () => const UnitOverviewScreen(),
      binding: UnitOverviewBinding(
        unitId: unit.id,
        unitTitle: unit.title,
        sectionNumber: unit.sectionNumber,
        unitNumber: unit.unitNumber,
      ),
    );
  }

  Widget _buildUnitCatalog(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const _UnitCatalogSkeleton();
      }
      if (controller.hasError.value) {
        return const EmptyStateWidget(
          icon: Icons.error_outline_rounded,
          title: 'Không thể tải bài học',
          message: 'Không thể đọc các bài học từ dữ liệu ngoại tuyến.',
        );
      }
      final units = controller.units.toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      if (units.isEmpty) {
        return const EmptyStateWidget(
          icon: Icons.route_rounded,
          title: 'Chưa có bài học',
          message: 'Cấp độ này chưa có nội dung bài học.',
        );
      }
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: ResponsiveHelper.contentMaxWidth(context)),
          child: CustomScrollView(
            key: const PageStorageKey('unit-adventure-path'),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  ResponsiveHelper.horizontalPadding(context),
                  20,
                  ResponsiveHelper.horizontalPadding(context),
                  12,
                ),
                sliver: SliverToBoxAdapter(
                  child: AdventureQuestBanner(
                    eyebrow: 'Chặng đường hiện tại',
                    title: controller.title,
                    description:
                        'Đi theo các cột mốc từ Chương 1. Panda sẽ đồng hành tới cổng Boss cuối lộ trình.',
                    statusLabel: '${units.length} chương',
                    mood: PandaMood.happy,
                    compact: true,
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  ResponsiveHelper.horizontalPadding(context),
                  8,
                  ResponsiveHelper.horizontalPadding(context),
                  40,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _UnitPathItem(
                      index: index,
                      isLast: index == units.length - 1,
                      child: _buildUnitMetrics(units[index], index + 1),
                    ),
                    childCount: units.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _UnitPathItem extends StatelessWidget {
  const _UnitPathItem({
    required this.index,
    required this.isLast,
    required this.child,
  });

  final int index;
  final bool isLast;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final left = index.isEven ? 0.0 : 24.0;
    final right = index.isEven ? 24.0 : 0.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(left, 10, right, 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (!isLast)
            Positioned(
              left: index.isEven ? 28 : null,
              right: index.isEven ? null : 28,
              top: 88,
              bottom: -30,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: GameVisualTokens.imperialGold.withValues(alpha: .65),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

/// Khung đang tải khớp lộ trình chương: banner và các thẻ chương so le.
class _UnitCatalogSkeleton extends StatelessWidget {
  const _UnitCatalogSkeleton();

  @override
  Widget build(BuildContext context) {
    final hp = ResponsiveHelper.horizontalPadding(context);
    return AppShimmer(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: ResponsiveHelper.contentMaxWidth(context)),
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
            padding: EdgeInsets.fromLTRB(hp, 20, hp, 40),
            children: [
              const SkeletonQuestBanner(showProgress: false),
              const SizedBox(height: 20),
              for (var i = 0; i < 8; i++)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      i.isEven ? 0 : 24, 10, i.isEven ? 24 : 0, 10),
                  child: const SkeletonListTile(
                    leadingSize: 50,
                    radius: 20,
                    trailingPillWidth: 64,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

