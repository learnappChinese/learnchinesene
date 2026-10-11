import 'package:flutter/material.dart';
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

class UnitScreen extends StatefulWidget {
  const UnitScreen({super.key});

  @override
  State<UnitScreen> createState() => _UnitScreenState();
}

class _UnitScreenState extends State<UnitScreen> {
  late final UnitController controller;

  @override
  void initState() {
    super.initState();
    // The existing GetX route owns this registration.
    controller = Get.isRegistered<UnitController>()
        ? Get.find<UnitController>()
        : Get.put(UnitController());
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

  Widget _buildUnitMetrics(List<UnitModel> units, int i) {
    final unit = units[i];
    final numPart = RegExp(r'\d+').firstMatch(unit.id)?.group(0);
    final unitNum = numPart != null ? int.tryParse(numPart) ?? (i + 1) : (i + 1);

    return FutureBuilder<Map<String, int>>(
      key: ValueKey(unit.id),
      future: controller.metricsFor(unit.id),
      builder: (context, snapshot) => UnitProgressTile(
        unit: unit,
        number: i + 1,
        words: snapshot.data?['words'] ?? 0,
        learned: snapshot.data?['learned'] ?? 0,
        onTap: () => Get.to(
          () => const UnitOverviewScreen(),
          binding: UnitOverviewBinding(
            unitId: unit.id,
            unitTitle: unit.title,
            sectionNumber: 1,
            unitNumber: unitNum,
          ),
        ),
      ),
    );
  }

  Widget _buildUnitCatalog(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.hasError.value) {
        return const EmptyStateWidget(
          icon: Icons.error_outline_rounded,
          title: 'Không thể tải bài học',
          message: 'Không thể đọc các bài học từ dữ liệu ngoại tuyến.',
        );
      }
      final units = controller.units;
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
          child: GridView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.horizontalPadding(context),
              vertical: 24,
            ),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 450,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              mainAxisExtent: 96,
            ),
            itemCount: units.length,
            itemBuilder: (context, i) => _buildUnitMetrics(units, i),
          ),
        ),
      );
    });
  }
}
