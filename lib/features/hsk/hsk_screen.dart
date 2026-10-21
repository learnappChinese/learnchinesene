import 'package:flutter/material.dart';
import '../../core/widgets/app_shimmer.dart';
import 'widget/hsk_level_card.dart';
import 'package:get/get.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/responsive/responsive_layout.dart';
import '../unit/unit_screen.dart';
import '../sections/learning_sections_screen.dart';
import 'controller/hsk_controller.dart';
import '../../core/models/hsk_level.dart';
import '../../core/widgets/learning_scene_background.dart';
import '../../core/widgets/adventure_quest_banner.dart';
import '../../core/widgets/panda_companion.dart';
import '../../core/theme/game_visual_tokens.dart';

class HskScreen extends StatefulWidget {
  const HskScreen({super.key, this.controller});

  final HskController? controller;

  @override
  State<HskScreen> createState() => _HskScreenState();
}

class _HskScreenState extends State<HskScreen> {
  late final HskController controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      controller = widget.controller!;
    } else if (Get.isRegistered<HskController>()) {
      controller = Get.find<HskController>();
    } else {
      controller = Get.put(HskController());
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController && Get.isRegistered<HskController>()) {
      Get.delete<HskController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bản đồ thế giới',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              onPressed: () => Get.to(() => const LearningSectionsScreen()),
              icon: const Icon(Icons.route_rounded, size: 18),
              label: const Text(
                'Phần học',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SafeBottomArea(child: LearningSceneBackground(
        theme: LearningSceneTheme.bambooVillage,
        child: _buildLevelCatalog(context),
      )),
    );
  }

  Widget _buildLevelMetrics(BuildContext context, HskLevel level, int index) {
    final isUnlockedLevel = level.order <= 4;
    return FutureBuilder<List<Object>>(
      key: ValueKey(level.id),
      future: controller.metricsFor(level.id),
      builder: (context, snapshot) => HskLevelCard(
        level: level,
        index: index,
        count: snapshot.hasData ? snapshot.data![0] as int : 0,
        progress: snapshot.hasData ? snapshot.data![1] as double : 0,
        isUnlocked: isUnlockedLevel,
        onTap: () {
          if (!isUnlockedLevel) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Giáo trình HSK 5 & 6 đang được biên soạn. Bạn hãy hoàn thành HSK 1–4 trước nhé!',
                ),
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }
          Get.to(
            () => const UnitScreen(),
            arguments: {
              'hskLevelId': level.id,
              'hskTitle': level.title,
              'hskOrder': level.order,
            },
          );
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
      final levels = controller.levels.toList()
        ..sort((a, b) => a.order.compareTo(b.order));
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
                    padding: const EdgeInsets.only(bottom: 24),
                    child: AdventureQuestBanner(
                      eyebrow: 'Hành trình HSK',
                      title: 'Theo Panda đi từ Làng Trúc đến Long Giới',
                      description:
                          'Bắt đầu ở World 1. Mỗi thế giới mở thêm từ vựng, kỹ năng và một cột mốc mới.',
                      statusLabel: '${levels.length} thế giới',
                      mood: PandaMood.archer,
                      compact: true,
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final isUnlocked = levels[index].order <= 4;
                      return _WorldPathItem(
                        index: index,
                        isLast: index == levels.length - 1,
                        isUnlocked: isUnlocked,
                        child: _buildLevelMetrics(context, levels[index], index),
                      );
                    },
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

class _WorldPathItem extends StatelessWidget {
  const _WorldPathItem({
    required this.index,
    required this.isLast,
    required this.isUnlocked,
    required this.child,
  });

  final int index;
  final bool isLast;
  final bool isUnlocked;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shift = index.isEven ? 0.0 : 28.0;
    return Padding(
      padding: EdgeInsets.only(left: shift, right: 28 - shift, bottom: 18),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (!isLast)
            Positioned(
              left: index.isEven ? 34 : null,
              right: index.isEven ? null : 34,
              top: 198,
              bottom: -28,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? GameVisualTokens.imperialGold
                      : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          SizedBox(height: 218, child: child),
          Positioned(
            left: index.isEven ? -7 : null,
            right: index.isEven ? null : -7,
            top: 82,
            child: Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked
                    ? GameVisualTokens.imperialGold
                    : const Color(0xFF94A3B8),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: GameVisualTokens.softShadow,
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldLoadingState extends StatelessWidget {
  const _WorldLoadingState();

  @override
  Widget build(BuildContext context) => AppShimmer(
        child: ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (_, __) => const ShimmerBox(height: 218, radius: 26),
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
