import 'package:flutter/material.dart';

import '../../../core/widgets/panda_companion.dart';
import '../models/hanzi_path_models.dart';
import 'hanzi_panda_companion_overlay.dart';
import 'hanzi_path_connector.dart';
import 'hanzi_path_node_widget.dart';

/// Một hàng trên con đường zigzag, bao gồm đường nối, node chữ Hán và Panda linh vật nếu có.
class HanziPathRowItem extends StatelessWidget {
  final HanziPathNode node;
  final HanziPathNode? nextNode;
  final VoidCallback onTap;

  static const List<double> cycleOffsets = [
    0.0,
    54.0,
    70.0,
    28.0,
    -28.0,
    -70.0,
    -50.0,
  ];

  static const List<String> pandaQuotes = [
    'Nét chuẩn, nhớ lâu!',
    'Viết thật nắn nót nha!',
    'Thư pháp đỉnh cao!',
    'Panda luôn đồng hành!',
    'Mỗi ngày thêm chữ mới!',
    'Tập trung luyện nét nào!',
  ];

  static const List<PandaMood> pandaMoods = [
    PandaMood.happy,
    PandaMood.thinking,
    PandaMood.ninja,
    PandaMood.chef,
    PandaMood.archer,
    PandaMood.happy,
  ];

  const HanziPathRowItem({
    super.key,
    required this.node,
    this.nextNode,
    required this.onTap,
  });

  static double getOffsetForIndex(int index) {
    return cycleOffsets[index % cycleOffsets.length];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final currentOffset = getOffsetForIndex(node.indexInSection);
    const rowHeight = 126.0;
    const centerY = rowHeight / 2;

    final startX = (screenWidth / 2) + currentOffset;
    final startY = centerY;

    // Xác định vị trí tiếp theo để vẽ đường nối uốn lượn
    final hasNext = nextNode != null;
    final nextOffset =
        hasNext ? getOffsetForIndex(nextNode!.indexInSection) : 0.0;
    final endX = (screenWidth / 2) + nextOffset;
    final endY = centerY + rowHeight;

    // Kiểm tra xem hàng này có xuất hiện Panda linh vật không
    final showPanda = (node.indexInSection % 5 == 2 ||
        node.indexInSection % 5 == 4);
    final pandaIsLeft = currentOffset > 10; // Nếu nút lệch phải thì Panda đứng bên trái và ngược lại
    final quoteIndex = node.globalIndex % pandaQuotes.length;
    final moodIndex = node.globalIndex % pandaMoods.length;

    return SizedBox(
      height: rowHeight,
      width: screenWidth,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. Đường nối uốn lượn xuống node tiếp theo
          if (hasNext)
            Positioned.fill(
              child: CustomPaint(
                painter: HanziPathConnectorPainter(
                  startX: startX,
                  startY: startY,
                  endX: endX,
                  endY: endY,
                  isCompleted: node.state == WritingNodeState.completed,
                  isDashed: node.state == WritingNodeState.locked,
                ),
              ),
            ),

          // 2. Panda linh vật khích lệ
          if (showPanda)
            HanziPathPandaWidget(
              isLeft: pandaIsLeft,
              speechText: pandaQuotes[quoteIndex],
              mood: pandaMoods[moodIndex],
            ),

          // 3. Nút chữ Hán uốn lượn 3D
          Transform.translate(
            offset: Offset(currentOffset, 0),
            child: HanziZigzagNodeWidget(
              node: node,
              onTap: onTap,
            ),
          ),
        ],
      ),
    );
  }
}
