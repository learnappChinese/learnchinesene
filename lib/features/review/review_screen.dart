import 'package:flutter/material.dart';
import '../../core/widgets/app_shimmer.dart';
import 'package:get/get.dart';

import '../../core/responsive/responsive_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/game_visual_tokens.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/app_green_button.dart';
import '../../core/widgets/learning_scene_background.dart';
import '../home/widgets/home_decorations.dart';
import '../../core/widgets/panda_companion.dart';
import '../../core/widgets/learning_scaffold.dart';
import '../../core/widgets/adventure_quest_banner.dart';
import 'controller/review_controller.dart';
import 'model/review_item.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key, this.controller});

  final ReviewController? controller;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final ReviewController controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      controller = widget.controller!;
    } else if (Get.isRegistered<ReviewController>()) {
      controller = Get.find<ReviewController>();
    } else {
      controller = Get.put(ReviewController());
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController && Get.isRegistered<ReviewController>()) {
      Get.delete<ReviewController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: 'Trung tâm Ôn luyện',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: AppHudIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Làm mới',
            size: 40,
            onPressed: controller.loadInitialData,
          ),
        ),
      ],
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
                    if (controller.isLoading.value &&
                        controller.summary.value == null) {
                      return const _ReviewSkeleton();
                    }

                    if (controller.errorMessage.value.isNotEmpty &&
                        controller.summary.value == null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.cloud_off_rounded,
                                size: 56,
                                color: GameVisualTokens.crimson,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                controller.errorMessage.value,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: GameVisualTokens.ink,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              AppGreenButton(
                                label: 'Thử lại',
                                icon: Icons.refresh_rounded,
                                onPressed: controller.loadInitialData,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final summary =
                        controller.summary.value ?? const ReviewSummary();
                    final selectedCat = controller.selectedCategory.value;
                    final items = controller.items;

                    return Column(
                      children: [
                        // Scrollable Main Content
                        Expanded(
                          child: RefreshIndicator(
                            color: GameVisualTokens.primaryGreen,
                            backgroundColor: GameVisualTokens.cream,
                            onRefresh: controller.loadInitialData,
                            child: ListView(
                              padding: EdgeInsets.fromLTRB(
                                constraints.maxWidth < 360 ? 12 : 16,
                                8,
                                constraints.maxWidth < 360 ? 12 : 16,
                                16,
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
                                  const AppShimmer(child: _ReviewItemsSkeleton(count: 6))
                                else if (items.isEmpty)
                                  _EmptyCategoryCard(
                                    category: selectedCat,
                                    onSwitch: () {
                                      // Switch to next category that has items
                                      if (summary.wordsDue > 0 &&
                                          selectedCat != ReviewCategory.words) {
                                        controller.selectCategory(
                                          ReviewCategory.words,
                                        );
                                      } else if (summary.listeningDue > 0 &&
                                          selectedCat !=
                                              ReviewCategory.listening) {
                                        controller.selectCategory(
                                          ReviewCategory.listening,
                                        );
                                      } else if (summary.speakingDue > 0 &&
                                          selectedCat !=
                                              ReviewCategory.speaking) {
                                        controller.selectCategory(
                                          ReviewCategory.speaking,
                                        );
                                      } else {
                                        controller.selectCategory(
                                          ReviewCategory.hanzi,
                                        );
                                      }
                                    },
                                  )
                                else ...[
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      2,
                                      6,
                                      2,
                                      12,
                                    ),
                                    child: Row(
                                      children: [
                                        const HomePandaFace(size: 26),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Cần ôn (${items.length})',
                                            style: const TextStyle(
                                              color: AppColors.homeInk,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 18,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Mục yếu xếp trước',
                                          style: TextStyle(
                                            color: GameVisualTokens.muted,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  for (final item in items)
                                    _ReviewItemCard(
                                      key: ValueKey(item.id),
                                      item: item,
                                      onTap: () =>
                                          controller.openItemPractice(item),
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
                          onPressed: () =>
                              controller.startCategoryReview(context),
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
    return AdventureQuestBanner(
      eyebrow: totalDue > 0 ? 'Ôn tập hôm nay' : 'Đã hoàn tất',
      title: totalDue > 0 ? '$totalDue mục đang chờ' : 'Trí nhớ đã sẵn sàng',
      description:
          'Ôn đúng lúc sắp quên để nhớ lâu hơn. Mục bạn hay sai sẽ được ưu tiên trước.',
      statusLabel: totalDue > 0 ? 'SRS ưu tiên' : 'Không còn mục đến hạn',
      mood: totalDue > 0 ? PandaMood.encourage : PandaMood.celebrate,
      accent: totalDue > 0
          ? GameVisualTokens.crimson
          : GameVisualTokens.primaryGreen,
      compact: isCompact,
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
      (
        ReviewCategory.words,
        'Từ vựng',
        summary.wordsDue,
        Icons.menu_book_rounded,
      ),
      (
        ReviewCategory.listening,
        'Nghe',
        summary.listeningDue,
        Icons.headphones_rounded,
      ),
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
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 4,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? GameVisualTokens.primaryGreenSoft
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? GameVisualTokens.primaryGreen
                        : _kTileLine,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.$4,
                      size: 22,
                      color: isSelected
                          ? GameVisualTokens.primaryGreenDark
                          : const Color(0xFF8C8577),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        tab.$2,
                        style: TextStyle(
                          color: isSelected
                              ? GameVisualTokens.primaryGreenDark
                              : const Color(0xFF5D5C54),
                          fontWeight: isSelected
                              ? FontWeight.w900
                              : FontWeight.w700,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 22),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: tab.$3 > 0
                              ? GameVisualTokens.crimson
                              : const Color(0xFFF3EEE4),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '${tab.$3}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: tab.$3 > 0
                                ? Colors.white
                                : const Color(0xFFB8B0A0),
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
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

/// Viền kem của các ô và thẻ trong màn ôn tập.
const _kTileLine = Color(0xFFE8E1D6);

class _ReviewItemCard extends StatelessWidget {
  const _ReviewItemCard({super.key, required this.item, required this.onTap});

  final ReviewItem item;
  final VoidCallback onTap;

  IconData get _categoryIcon {
    switch (item.category) {
      case ReviewCategory.words:
        return Icons.menu_book_rounded;
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
    // Từ ngắn hiện thẳng trong ô bên trái; câu dài thì ô hiện icon kỹ năng
    // và câu nằm ở cột nội dung, tránh lặp chữ hai lần.
    final showTitleInTile = item.title.characters.length <= 3;
    final weak = item.isWeak && item.wrongCount > 0;
    final line = weak
        ? GameVisualTokens.crimson.withValues(alpha: .35)
        : _kTileLine;
    final radius = BorderRadius.circular(18);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radius,
          border: Border.all(color: line, width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x14635D3B), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: RoundedRectangleBorder(borderRadius: radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    padding: const EdgeInsets.all(6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFFFDF6), Color(0xFFFFF4DE)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFF5C979),
                        width: 1.5,
                      ),
                    ),
                    child: showTitleInTile
                        ? FittedBox(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                color: GameVisualTokens.ink,
                                fontWeight: FontWeight.w900,
                                fontSize: 26,
                              ),
                            ),
                          )
                        : Icon(
                            _categoryIcon,
                            color: AppColors.amberDark,
                            size: 26,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!showTitleInTile) ...[
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: AppColors.homeTitle,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                        ],
                        if (item.subtitle.isNotEmpty)
                          Text(
                            item.subtitle,
                            style: TextStyle(
                              color: showTitleInTile
                                  ? GameVisualTokens.crimsonDark
                                  : GameVisualTokens.muted,
                              fontWeight: FontWeight.w800,
                              fontSize: showTitleInTile ? 17 : 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (item.translation.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.translation,
                            style: const TextStyle(
                              color: GameVisualTokens.primaryGreenDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (weak) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: GameVisualTokens.crimson.withValues(
                                alpha: .1,
                              ),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 12,
                                  color: GameVisualTokens.crimson,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${item.wrongCount} lần sai',
                                  style: const TextStyle(
                                    color: GameVisualTokens.crimson,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: _kTileLine, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.homeGreen,
                      size: 24,
                    ),
                  ),
                ],
              ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1E6CF), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A635D3B),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const PandaCompanion(mood: PandaMood.celebrate, size: 72),
          const SizedBox(height: 14),
          const Text(
            'Thần công hoàn tất!',
            style: TextStyle(
              color: Color(0xFF342E10),
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bạn không còn mục nào cần củng cố trong phần này. Hãy giữ vững phong độ nhé!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF5D5C54),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          AppGreenButton.light(
            label: 'Xem kỹ năng khác',
            icon: Icons.explore_rounded,
            height: 44,
            fontSize: 14,
            onPressed: onSwitch,
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
        return 'Bắt đầu ôn từ vựng';
      case ReviewCategory.listening:
        return 'Bắt đầu luyện nghe';
      case ReviewCategory.speaking:
        return 'Bắt đầu luyện nói';
      case ReviewCategory.hanzi:
        return 'Bắt đầu luyện chữ Hán';
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
    // Không có nền riêng: nút nổi thẳng trên phong cảnh để nền liền mạch
    // tới tận mép dưới màn hình.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: AppGreenButton(
        label: _buttonLabel,
        icon: _buttonIcon,
        height: 52,
        fontSize: 16,
        expand: true,
        onPressed: hasItems ? onPressed : null,
      ),
    );
  }
}

/// Khung đang tải khớp bố cục màn: hero, 4 tab kỹ năng, danh sách cần ôn và
/// nút bắt đầu ở đáy.
class _ReviewSkeleton extends StatelessWidget {
  const _ReviewSkeleton();

  @override
  Widget build(BuildContext context) => AppShimmer(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  const SkeletonQuestBanner(showProgress: false),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (var i = 0; i < 4; i++)
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 3),
                            child: SkeletonCard(
                              radius: 16,
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Column(
                                children: [
                                  ShimmerBox.circle(size: 22),
                                  SizedBox(height: 6),
                                  ShimmerBox(width: 44, height: 12),
                                  SizedBox(height: 6),
                                  SkeletonPill(width: 22, height: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const SkeletonSectionTitle(width: 100, showTrailing: true),
                  const SizedBox(height: 12),
                  const _ReviewItemsSkeleton(),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: ShimmerBox(height: 56, radius: 20),
            ),
          ],
        ),
      );
}

/// Các thẻ mục cần ôn giữ chỗ: ô chữ kem bên trái, pinyin, nghĩa, nút tròn.
class _ReviewItemsSkeleton extends StatelessWidget {
  const _ReviewItemsSkeleton({this.count = 8});

  final int count;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (var i = 0; i < count; i++) ...[
            const SkeletonCard(
              padding: EdgeInsets.fromLTRB(12, 12, 10, 12),
              child: Row(
                children: [
                  ShimmerBox(width: 58, height: 58, radius: 16),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerLine(widthFactor: .4, height: 17),
                        SizedBox(height: 8),
                        ShimmerLine(widthFactor: .55, height: 12),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  ShimmerBox.circle(size: 34),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
        ],
      );
}
