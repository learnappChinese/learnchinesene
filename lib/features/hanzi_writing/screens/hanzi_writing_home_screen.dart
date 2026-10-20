import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/learning/model/learning_source_context.dart';
import '../../../core/theme/game_visual_tokens.dart';
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

  const HanziWritingHomeScreen({
    super.key,
    this.sourceContext,
  });

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
      backgroundColor: const Color(0xFFF8FAFC),
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
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              color: GameVisualTokens.primaryGreen,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Đang tải lộ trình học viết...',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
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
                              ElevatedButton(
                                onPressed: controller.loadLearningPath,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: GameVisualTokens.primaryGreen,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Thử lại'),
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
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 12),
                        ),

                        // Lặp qua các cấp độ HSK và các Section
                        for (final hskLevel in filteredLevels) ...[
                          for (final section in hskLevel.sections) ...[
                            // Banner cho từng Section
                            SliverToBoxAdapter(
                              child: HanziSectionBanner(section: section),
                            ),

                            // Danh sách các node chữ Hán uốn lượn liên tục
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final node = section.nodes[index];
                                  final nextNode = index < section.nodes.length - 1
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
                                },
                                childCount: section.nodes.length,
                              ),
                            ),

                            const SliverToBoxAdapter(
                              child: SizedBox(height: 16),
                            ),
                          ],

                          // Mốc hoàn thành cấp độ HSK
                          SliverToBoxAdapter(
                            child: HanziHskMilestoneCard(hskLevel: hskLevel),
                          ),

                          const SliverToBoxAdapter(
                            child: SizedBox(height: 24),
                          ),
                        ],

                        // Khoảng trống đệm cuối màn hình để không bị nút Floating che khuất
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 80),
                        ),
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
              bottom: 24,
              child: GestureDetector(
                onTap: controller.scrollToCurrentNode,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        GameVisualTokens.primaryGreen,
                        GameVisualTokens.primaryGreenDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: GameVisualTokens.primaryGreenDark
                            .withValues(alpha: 0.45),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          activeNode.character.character,
                          style: const TextStyle(
                            fontFamily: 'FZKaiTiPinyin',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: GameVisualTokens.primaryGreenDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Tiếp tục học',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_downward_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
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
