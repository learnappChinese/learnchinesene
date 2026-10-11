import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/responsive/responsive_layout.dart';
import '../../core/theme/game_visual_tokens.dart';
import '../../core/widgets/learning_scene_background.dart';
import '../../core/widgets/panda_companion.dart';
import 'controller/review_controller.dart';
import 'model/review_item.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final ReviewController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<ReviewController>()
        ? Get.find<ReviewController>()
        : Get.put(ReviewController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameVisualTokens.night,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Trung Tâm Ôn Luyện',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: GameVisualTokens.imperialGold),
            tooltip: 'Làm mới',
            onPressed: controller.loadInitialData,
          ),
        ],
      ),
      body: LearningSceneBackground(
        theme: LearningSceneTheme.bambooVillage,
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: ResponsiveHelper.contentMaxWidth(context),
                  ),
                  child: Obx(() {
                    if (controller.isLoading.value && controller.summary.value == null) {
                      return const Center(
                        child: CircularProgressIndicator(color: GameVisualTokens.jade),
                      );
                    }

                    final summary = controller.summary.value ?? const ReviewSummary();
                    final selectedCat = controller.selectedCategory.value;
                    final items = controller.items;

                    return Column(
                      children: [
                        // Scrollable Main Content
                        Expanded(
                          child: RefreshIndicator(
                            color: GameVisualTokens.jade,
                            backgroundColor: GameVisualTokens.night,
                            onRefresh: controller.loadInitialData,
                            child: ListView(
                              padding: EdgeInsets.fromLTRB(
                                constraints.maxWidth < 360 ? 12 : 16,
                                8,
                                constraints.maxWidth < 360 ? 12 : 16,
                                100,
                              ),
                              children: [
                                _ReviewHeroCard(
                                  totalDue: summary.totalDue,
                                  isCompact: constraints.maxWidth < 360,
                                ),
                                const SizedBox(height: 16),
                                _CategorySelectorBar(
                                  selectedCategory: selectedCat,
                                  summary: summary,
                                  onSelect: controller.selectCategory,
                                ),
                                const SizedBox(height: 16),
                                if (controller.isLoading.value)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 40),
                                    child: Center(
                                      child: CircularProgressIndicator(color: GameVisualTokens.jade),
                                    ),
                                  )
                                else if (items.isEmpty)
                                  _EmptyCategoryCard(
                                    category: selectedCat,
                                    onSwitch: () {
                                      // Switch to next category that has items
                                      if (summary.wordsDue > 0 && selectedCat != ReviewCategory.words) {
                                        controller.selectCategory(ReviewCategory.words);
                                      } else if (summary.listeningDue > 0 && selectedCat != ReviewCategory.listening) {
                                        controller.selectCategory(ReviewCategory.listening);
                                      } else if (summary.speakingDue > 0 && selectedCat != ReviewCategory.speaking) {
                                        controller.selectCategory(ReviewCategory.speaking);
                                      } else {
                                        controller.selectCategory(ReviewCategory.hanzi);
                                      }
                                    },
                                  )
                                else ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                    child: Row(
                                      children: [
                                        const Text(
                                          'DANH SÁCH CẦN ÔN',
                                          style: TextStyle(
                                            color: GameVisualTokens.imperialGold,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        Text(
                                          ' (${items.length})',
                                          style: const TextStyle(
                                            color: GameVisualTokens.imperialGold,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const Spacer(),
                                        const Text(
                                          'Ưu tiên mục yếu',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  for (final item in items)
                                    _ReviewItemCard(
                                      key: ValueKey(item.id),
                                      item: item,
                                      onTap: () => controller.openItemPractice(item),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // Bottom Sticky CTA
                        _ReviewBottomAction(
                          category: selectedCat,
                          hasItems: items.isNotEmpty,
                          onPressed: () => controller.startCategoryReview(context),
                        ),
                      ],
                    );
                  }),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ReviewHeroCard extends StatelessWidget {
  const _ReviewHeroCard({required this.totalDue, this.isCompact = false});

  final int totalDue;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: GameVisualTokens.night.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: GameVisualTokens.imperialGold.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          PandaCompanion(
            mood: totalDue > 0 ? PandaMood.encourage : PandaMood.celebrate,
            size: isCompact ? 56 : 68,
          ),
          SizedBox(width: isCompact ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: GameVisualTokens.crimson.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: GameVisualTokens.crimson.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    totalDue > 0 ? '$totalDue MỤC CẦN ÔN HÔM NAY' : 'ĐÃ HOÀN TẤT ÔN TẬP',
                    style: const TextStyle(
                      color: GameVisualTokens.crimson,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Luyện Trí Nhớ Sắc Bén',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Hệ thống tự động ưu tiên các từ bạn hay sai hoặc lâu chưa luyện.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySelectorBar extends StatelessWidget {
  const _CategorySelectorBar({
    required this.selectedCategory,
    required this.summary,
    required this.onSelect,
  });

  final ReviewCategory selectedCategory;
  final ReviewSummary summary;
  final ValueChanged<ReviewCategory> onSelect;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (ReviewCategory.words, 'Từ vựng', summary.wordsDue, Icons.menu_book_rounded),
      (ReviewCategory.listening, 'Nghe', summary.listeningDue, Icons.headphones_rounded),
      (ReviewCategory.speaking, 'Nói', summary.speakingDue, Icons.mic_rounded),
      (ReviewCategory.hanzi, 'Hán tự', summary.hanziDue, Icons.draw_rounded),
    ];

    return Row(
      children: tabs.map((tab) {
        final isSelected = selectedCategory == tab.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              onTap: () => onSelect(tab.$1),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? GameVisualTokens.jade.withValues(alpha: 0.25)
                      : GameVisualTokens.night.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? GameVisualTokens.jade
                        : Colors.white.withValues(alpha: 0.12),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.$4,
                      size: 18,
                      color: isSelected ? GameVisualTokens.jade : Colors.white60,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab.$2,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white60,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: tab.$3 > 0
                            ? (isSelected
                                ? GameVisualTokens.imperialGold
                                : GameVisualTokens.night)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${tab.$3}',
                        style: TextStyle(
                          color: tab.$3 > 0
                              ? (isSelected ? Colors.black87 : GameVisualTokens.imperialGold)
                              : Colors.white30,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ReviewItemCard extends StatelessWidget {
  const _ReviewItemCard({super.key, required this.item, required this.onTap});

  final ReviewItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isHanzi = item.category == ReviewCategory.hanzi;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: GameVisualTokens.night.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isWeak
              ? GameVisualTokens.crimson.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Hanzi / Leading badge
                Container(
                  width: isHanzi ? 52 : 46,
                  height: isHanzi ? 52 : 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: GameVisualTokens.parchment.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: GameVisualTokens.imperialGold.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    item.title.length > 2 && !isHanzi
                        ? item.title.substring(0, 2)
                        : item.title,
                    style: TextStyle(
                      color: GameVisualTokens.imperialGold,
                      fontWeight: FontWeight.w900,
                      fontSize: isHanzi ? 26 : 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.isWeak && item.wrongCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: GameVisualTokens.crimson.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.warning_amber_rounded,
                                      size: 12, color: GameVisualTokens.crimson),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${item.wrongCount} lần sai',
                                    style: const TextStyle(
                                      color: GameVisualTokens.crimson,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          color: GameVisualTokens.jade,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.translation,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white30,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCategoryCard extends StatelessWidget {
  const _EmptyCategoryCard({required this.category, required this.onSwitch});

  final ReviewCategory category;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: GameVisualTokens.night.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: GameVisualTokens.jade.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const PandaCompanion(
            mood: PandaMood.celebrate,
            size: 72,
          ),
          const SizedBox(height: 14),
          const Text(
            'Thần Công Hoàn Tất!',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bạn không còn mục nào cần củng cố trong phần này. Hãy giữ vững phong độ nhé!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onSwitch,
            icon: const Icon(Icons.explore_rounded, color: GameVisualTokens.imperialGold, size: 16),
            label: const Text(
              'Xem Kỹ Năng Khác',
              style: TextStyle(color: GameVisualTokens.imperialGold, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: GameVisualTokens.imperialGold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewBottomAction extends StatelessWidget {
  const _ReviewBottomAction({
    required this.category,
    required this.hasItems,
    required this.onPressed,
  });

  final ReviewCategory category;
  final bool hasItems;
  final VoidCallback onPressed;

  String get _buttonLabel {
    switch (category) {
      case ReviewCategory.words:
        return 'Bắt Đầu Ôn Từ Vựng';
      case ReviewCategory.listening:
        return 'Bắt Đầu Luyện Nghe';
      case ReviewCategory.speaking:
        return 'Bắt Đầu Luyện Nói';
      case ReviewCategory.hanzi:
        return 'Bắt Đầu Luyện Chữ Hán';
    }
  }

  IconData get _buttonIcon {
    switch (category) {
      case ReviewCategory.words:
        return Icons.quiz_rounded;
      case ReviewCategory.listening:
        return Icons.headphones_rounded;
      case ReviewCategory.speaking:
        return Icons.mic_rounded;
      case ReviewCategory.hanzi:
        return Icons.draw_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: GameVisualTokens.night,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: hasItems ? onPressed : null,
          icon: Icon(_buttonIcon, color: Colors.black87, size: 20),
          label: Text(
            _buttonLabel,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w900,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: GameVisualTokens.imperialGold,
            disabledBackgroundColor: Colors.white24,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 4,
          ),
        ),
      ),
    );
  }
}
