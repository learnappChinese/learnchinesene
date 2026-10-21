import 'package:flutter/material.dart';
import '../../../core/widgets/app_shimmer.dart';
import 'package:get/get.dart';

import '../../../core/learning/model/learning_source_context.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_green_button.dart';
import '../../../core/widgets/learning_scene_background.dart';
import '../controller/hanzi_learning_path_controller.dart';
import '../models/hanzi_path_models.dart';
import '../widget/hanzi_node_detail_sheet.dart';
import '../widget/hanzi_path_row_item.dart';
import '../widget/hanzi_path_top_bar.dart';
import '../widget/hanzi_section_banner.dart';
import 'hanzi_writing_screen.dart';

/// Màn hình chính của tính năng Luyện viết chữ Hán được xây dựng lại hoàn toàn
/// theo lộ trình học tập liên tục (Learning Path) phong cách Duolingo uốn lượn.
class HanziWritingHomeScreen extends StatefulWidget {
  final LearningSourceContext? sourceContext;

  const HanziWritingHomeScreen({super.key, this.sourceContext});

  @override
  State<HanziWritingHomeScreen> createState() => _HanziWritingHomeScreenState();
}

class _HanziWritingHomeScreenState extends State<HanziWritingHomeScreen> {
  static int _nextControllerId = 0;
  late final String _controllerTag;
  late final HanziLearningPathController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'hanzi-path-${_nextControllerId++}';
    controller = Get.put(HanziLearningPathController(), tag: _controllerTag);
  }

  @override
  void dispose() {
    Get.delete<HanziLearningPathController>(tag: _controllerTag);
    super.dispose();
  }

  Future<void> _startWritingNode(
    HanziPathNode node,
    HanziPathSection section,
  ) async {
    final sequence = section.nodes.map((n) => n.character.id).toList();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HanziWritingScreen(
          characterId: node.character.id,
          sourceContext: widget.sourceContext,
          characterSequence: sequence,
          hskLevel: node.hskLevel,
          unitId: node.sectionId,
        ),
      ),
    );

    // Sau khi quay lại từ màn hình luyện viết, cập nhật ngay tiến độ và mở khóa node tiếp theo
    await controller.refreshProgress();
  }

  void _onNodeTapped(HanziPathNode node, HanziPathSection section) {
    HanziNodeDetailSheet.show(
      context,
      node: node,
      onStartWriting: () => _startWritingNode(node, section),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Nền tranh phong cảnh làng trúc nhẹ nhàng
          Positioned.fill(
            child: LearningSceneBackground(
              theme: LearningSceneTheme.bambooVillage,
              child: const SizedBox.expand(),
            ),
          ),

          // Lộ trình học cuộn dọc liên tục
          SafeArea(
            child: Column(
              children: [
                // 1. Thanh trạng thái trên cùng: Panda, XP, Streak, Chữ đã thuộc, Bộ lọc HSK
                HanziPathTopBar(controller: controller),

                // 2. Nội dung lộ trình cuộn mượt mà
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const _HanziPathSkeleton();
                    }

                    if (controller.errorMessage.value != null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🐼', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              Text(
                                controller.errorMessage.value!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              AppGreenButton(
                                label: 'Thử lại',
                                icon: Icons.refresh_rounded,
                                onPressed: controller.loadLearningPath,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final filteredLevels = controller.filteredHskLevels;
                    if (filteredLevels.isEmpty) {
                      return const Center(
                        child: Text(
                          'Không có bài học chữ Hán nào.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      );
                    }

                    return CustomScrollView(
                      controller: controller.scrollController,
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        const SliverToBoxAdapter(child: SizedBox(height: 12)),

                        // Lặp qua các cấp độ HSK và các Section
                        for (final hskLevel in filteredLevels) ...[
                          for (final section in hskLevel.sections) ...[
                            // Banner cho từng Section
                            SliverToBoxAdapter(
                              child: HanziSectionBanner(section: section),
                            ),

                            // Danh sách các node chữ Hán uốn lượn liên tục
                            SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final node = section.nodes[index];
                                final nextNode =
                                    index < section.nodes.length - 1
                                    ? section.nodes[index + 1]
                                    : null;
                                return HanziPathRowItem(
                                  key: ValueKey(
                                    'hanzi_row_${node.hskLevel}_${node.sectionId}_${node.character.id}_${node.indexInSection}',
                                  ),
                                  node: node,
                                  nextNode: nextNode,
                                  onTap: () => _onNodeTapped(node, section),
                                );
                              }, childCount: section.nodes.length),
                            ),

                            const SliverToBoxAdapter(
                              child: SizedBox(height: 16),
                            ),
                          ],

                          // Mốc hoàn thành cấp độ HSK
                          SliverToBoxAdapter(
                            child: HanziHskMilestoneCard(hskLevel: hskLevel),
                          ),

                          const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        ],

                        // Khoảng trống đệm cuối màn hình để không bị nút Floating che khuất
                        const SliverToBoxAdapter(child: SizedBox(height: 80)),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),

          // Nút bấm nổi CTA "Tiếp tục học" cuộn mượt đến node hiện tại
          Obx(() {
            final activeNode = controller.currentNode.value;
            if (activeNode == null || controller.isLoading.value) {
              return const SizedBox.shrink();
            }

            return Positioned(
              right: 20,
              // Nút nổi đặt ngoài SafeArea nên tự cộng phần inset đáy.
              bottom: 24 + MediaQuery.paddingOf(context).bottom,
              child: GestureDetector(
                onTap: controller.scrollToCurrentNode,
                // Nút xanh nổi khối như nút ở màn Home: gờ đáy sậm + viền sáng.
                child: Container(
                  padding: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: Color.lerp(AppColors.homeGreen, Colors.black, .24),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.homeGreen.withValues(alpha: .35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0, .55, 1],
                        colors: [
                          Color.lerp(AppColors.homeGreen, Colors.white, .12)!,
                          AppColors.homeGreen,
                          Color.lerp(AppColors.homeGreen, Colors.black, .06)!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Color.lerp(
                          AppColors.homeGreen,
                          Colors.white,
                          .32,
                        )!,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            activeNode.character.character,
                            style: const TextStyle(
                              fontFamily: 'FZKaiTiPinyin',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.homeGreenText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Tiếp tục học',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                color: Color(0x33000000),
                                blurRadius: 1,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_downward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Khung đang tải khớp lộ trình: banner bài và các node chữ uốn lượn theo
/// đúng độ lệch của [HanziPathRowItem].
class _HanziPathSkeleton extends StatelessWidget {
  const _HanziPathSkeleton();

  @override
  Widget build(BuildContext context) => AppShimmer(
        child: ListView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.only(top: 12),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SkeletonCard(
                style: SkeletonCardStyle.cream,
                radius: 26,
                padding: EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonPill(width: 112, height: 22),
                    SizedBox(height: 12),
                    ShimmerLine(widthFactor: .5, height: 20),
                    SizedBox(height: 8),
                    ShimmerLine(widthFactor: .7, height: 13),
                    SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: ShimmerBox(height: 9, radius: 99)),
                        SizedBox(width: 10),
                        ShimmerBox(width: 52, height: 13),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            for (var i = 0; i < 10; i++)
              SizedBox(
                height: 126,
                child: Center(
                  child: Transform.translate(
                    offset: Offset(HanziPathRowItem.getOffsetForIndex(i), 0),
                    child: ShimmerBox.circle(size: i == 0 ? 82 : 74),
                  ),
                ),
              ),
          ],
        ),
      );
}
