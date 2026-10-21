import 'package:flutter/material.dart';
import '../../../core/widgets/app_shimmer.dart';
import 'package:get/get.dart';

import '../../../core/presentation/learning_presentation_mapper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/game_visual_tokens.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_green_button.dart';
import '../../../core/widgets/learning_question_card.dart';
import '../../../core/widgets/learning_scaffold.dart';
import '../../../core/widgets/learning_scene_background.dart';
import '../../../core/widgets/panda_companion.dart';
import '../../home/widgets/home_decorations.dart';
import '../controller/flashcards_deck_controller.dart';
import '../models/flashcard_models.dart';
import 'flashcard_settings_screen.dart';
import 'flashcard_stats_screen.dart';
import 'flashcard_study_screen.dart';

/// Trang chủ Flashcard với Dashboard Spaced Repetition thông minh,
/// danh sách bộ thẻ theo HSK/Section và các lối tắt ôn tập FSRS.
class FlashcardsHomeScreen extends StatefulWidget {
  final int initialLevel;

  const FlashcardsHomeScreen({super.key, this.initialLevel = 1});

  @override
  State<FlashcardsHomeScreen> createState() => _FlashcardsHomeScreenState();
}

class _FlashcardsHomeScreenState extends State<FlashcardsHomeScreen> {
  static int _nextId = 0;
  late final String _tag;
  late final FlashcardsDeckController controller;

  @override
  void initState() {
    super.initState();
    _tag = 'fc-deck-${_nextId++}';
    controller = Get.put(FlashcardsDeckController(), tag: _tag);
    controller.selectHsk(widget.initialLevel);
  }

  @override
  void dispose() {
    Get.delete<FlashcardsDeckController>(tag: _tag);
    super.dispose();
  }

  void _openStudySession({
    int? hskLevel,
    int? unitId,
    bool onlyDue = false,
    bool onlyNew = false,
    int cardLimit = 20,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardStudyScreen(
          hskLevel: hskLevel,
          unitId: unitId,
          onlyDue: onlyDue,
          onlyNew: onlyNew,
          cardLimit: cardLimit,
          direction: controller.cardDirection.value,
        ),
      ),
    );
    // Cập nhật lại số liệu dashboard khi hoàn thành session
    controller.loadDashboardAndDecks();
  }

  void _showCardCountPicker({int? hskLevel, int? unitId, String? title}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          // Chừa thanh home indicator / thanh điều hướng ở đáy.
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.viewPaddingOf(sheetContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title ?? 'Bắt đầu học bộ thẻ',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: GameVisualTokens.ink,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Chọn số lượng thẻ cho phiên học này:',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildLimitOption(5, hskLevel, unitId),
                  const SizedBox(width: 8),
                  _buildLimitOption(10, hskLevel, unitId),
                  const SizedBox(width: 8),
                  _buildLimitOption(20, hskLevel, unitId),
                  const SizedBox(width: 8),
                  _buildLimitOption(50, hskLevel, unitId),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _openStudySession(
                    hskLevel: hskLevel,
                    unitId: unitId,
                    cardLimit: 100,
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: GameVisualTokens.primaryGreenDark,
                  side: const BorderSide(color: GameVisualTokens.primaryGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Học tất cả thẻ có sẵn',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLimitOption(int limit, int? hskLevel, int? unitId) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          _openStudySession(
            hskLevel: hskLevel,
            unitId: unitId,
            cardLimit: limit,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: GameVisualTokens.primaryGreenSoft,
          foregroundColor: GameVisualTokens.primaryGreenDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: GameVisualTokens.primaryGreenLight),
          ),
        ),
        child: Text(
          '$limit thẻ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  static const _line = Color(0xFFE8E1D6);

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: 'Học Flashcard',
      actions: [
        AppHudIconButton(
          icon: Icons.bar_chart_rounded,
          tooltip: 'Thống kê',
          size: 40,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FlashcardStatsScreen()),
            );
          },
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: AppHudIconButton(
            icon: Icons.settings_rounded,
            tooltip: 'Cài đặt',
            size: 40,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FlashcardSettingsScreen(),
                ),
              );
            },
          ),
        ),
      ],
      body: LearningSceneBackground(
        theme: LearningSceneTheme.bambooVillage,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const _FlashcardsHomeSkeleton();
          }

          final stats = controller.dashboardStats.value;
          final selectedHsk = controller.selectedHskLevel.value;
          final currentDeck = controller.hskDecks.firstWhereOrNull(
            (d) => d.level == selectedHsk,
          );

          return RefreshIndicator(
            onRefresh: controller.loadDashboardAndDecks,
            color: AppColors.homeGreen,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 32),
              children: [
                // 1. Dashboard tổng quan FSRS
                if (stats != null) _buildDashboardHeader(stats),
                const SizedBox(height: 16),

                // 2. Lối tắt nhanh
                _buildQuickActionShortcuts(stats),
                const SizedBox(height: 20),

                // 3. Tab chọn HSK Level
                _buildHskSelector(),
                const SizedBox(height: 14),

                // 4. Danh sách các Section trong HSK
                if (currentDeck != null) ...[
                  if (!currentDeck.isAvailable)
                    _buildUnavailableHskNotice(currentDeck.level)
                  else ...[
                    // Tiêu đề HSK và nút học cả HSK
                    Row(
                      children: [
                        const HomePandaFace(size: 26),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: currentDeck.name),
                                TextSpan(
                                  text: '  ${currentDeck.totalWords} từ',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.homeSubtitle,
                                  ),
                                ),
                              ],
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.homeInk,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _showCardCountPicker(
                              hskLevel: currentDeck.level,
                              title: 'Học toàn bộ ${currentDeck.name}',
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.homeGreenLink,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            minimumSize: const Size(0, 34),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Học cả HSK',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, size: 18),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Danh sách từng Section/Unit
                    ...currentDeck.sections.map(
                      (sec) => _buildSectionDeckCard(sec, currentDeck.level),
                    ),
                  ],
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDashboardHeader(FlashcardDashboardStats stats) {
    final hasDue = stats.dueToday > 0;
    return LearningQuestionCard(
      stageLabel: 'HÔM NAY',
      instruction: hasDue
          ? '${stats.dueToday} thẻ đến hạn ôn'
          : 'Không còn thẻ đến hạn',
      trailing: const PandaCompanion(
        mood: PandaMood.happy,
        size: 64,
        animate: false,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                size: 18,
                color: GameVisualTokens.orange,
              ),
              const SizedBox(width: 4),
              Text(
                'Chuỗi học ${stats.streakDays} ngày liên tiếp',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.amberDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Lưới các trạng thái thẻ (Anki Matrix)
          Row(
            children: [
              _buildStatPill(
                'Đến hạn',
                '${stats.dueToday}',
                Icons.alarm_rounded,
                GameVisualTokens.crimson,
              ),
              const SizedBox(width: 8),
              _buildStatPill(
                'Thẻ mới',
                '${stats.newAvailable}',
                Icons.fiber_new_rounded,
                AppColors.homeGreen,
              ),
              const SizedBox(width: 8),
              _buildStatPill(
                'Đang học',
                '${stats.learningCount}',
                Icons.autorenew_rounded,
                AppColors.imperialGold,
              ),
              const SizedBox(width: 8),
              _buildStatPill(
                'Đã nhớ',
                '${stats.reviewCount}',
                Icons.verified_rounded,
                GameVisualTokens.blue,
              ),
            ],
          ),
          const SizedBox(height: 18),

          AppGreenButton(
            label: hasDue ? 'Bắt đầu ôn tập ngay' : 'Học thẻ mới hôm nay',
            icon: Icons.bolt_rounded,
            height: 52,
            fontSize: 16,
            expand: true,
            onPressed: () {
              if (hasDue) {
                _openStudySession(onlyDue: true, cardLimit: 30);
              } else {
                _openStudySession(onlyNew: true, cardLimit: 20);
              }
            },
          ),
        ],
      ),
    );
  }

  /// Ô thống kê nhỏ nổi khối: icon màu trong vòng tròn, số đậm, nhãn xám.
  Widget _buildStatPill(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _line, width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.homeTitle,
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.homeSubtitle,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionShortcuts(FlashcardDashboardStats? stats) {
    return Row(
      children: [
        Expanded(
          child: AppGreenButton.light(
            label: 'Học thẻ mới',
            icon: Icons.add_circle_outline_rounded,
            height: 46,
            fontSize: 14,
            onPressed: () => _openStudySession(onlyNew: true, cardLimit: 20),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AppGreenButton.light(
            label: 'Chỉ ôn đến hạn',
            icon: Icons.history_edu_rounded,
            height: 46,
            fontSize: 14,
            onPressed: () => _openStudySession(onlyDue: true, cardLimit: 30),
          ),
        ),
      ],
    );
  }

  /// Chip HSK: đang chọn là nút xanh nổi khối, còn lại là ô trắng nổi khối.
  Widget _buildHskSelector() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [1, 2, 3, 4, 5, 6].map((lvl) {
          final isSelected = controller.selectedHskLevel.value == lvl;
          final isLocked = lvl > 4;
          return Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 6, top: 2),
            child: GestureDetector(
              onTap: () => controller.selectHsk(lvl),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                // Chip chọn: phẳng, không gờ — chỉ nút hành động mới nổi khối.
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.homeGreenSoft : Colors.white,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: isSelected ? AppColors.homeGreen : _line,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'HSK $lvl',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: isSelected
                            ? AppColors.homeGreenText
                            : isLocked
                            ? const Color(0xFFA8A196)
                            : AppColors.homeSubtitle,
                      ),
                    ),
                    if (isLocked) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.lock_rounded,
                        size: 13,
                        color: isSelected
                            ? AppColors.homeGreenText
                            : const Color(0xFFA8A196),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUnavailableHskNotice(int lvl) {
    return LearningQuestionCard(
      child: Column(
        children: [
          const PandaCompanion(
            mood: PandaMood.thinking,
            size: 72,
            animate: false,
          ),
          const SizedBox(height: 12),
          Text(
            'HSK $lvl đang được biên soạn',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.homeTitle,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Dữ liệu từ vựng HSK 5 & 6 sẽ sớm ra mắt. Bạn hãy chinh phục các cấp độ HSK 1–4 trước nhé!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.homeBody,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Thẻ một Section/Unit, kiểu ô nổi khối như ô đáp án ở màn học.
  Widget _buildSectionDeckCard(FlashcardSectionDeck sec, int hskLevel) {
    final title = LearningPresentationMapper.sectionUnitLabel(sec.title);
    final percent = sec.progressPercent.clamp(0, 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _line, width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x14635D3B), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFFDF6), Color(0xFFFFF4DE)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF5C979), width: 1.5),
              ),
              child: const Icon(
                Icons.style_rounded,
                color: AppColors.amberDark,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.homeTitle,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _deckChip(
                        '${sec.totalWords} thẻ',
                        AppColors.homeSubtitle,
                        const Color(0xFFF3EEE4),
                      ),
                      if (sec.dueWords > 0)
                        _deckChip(
                          '${sec.dueWords} đến hạn',
                          GameVisualTokens.crimson,
                          GameVisualTokens.crimson.withValues(alpha: .1),
                        ),
                      if (sec.newWords > 0)
                        _deckChip(
                          '${sec.newWords} mới',
                          AppColors.homeGreenText,
                          AppColors.homeGreenSoft,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: percent / 100.0,
                            minHeight: 7,
                            backgroundColor: const Color(0xFFEDE5D6),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.homeGreen,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$percent%',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: AppColors.homeGreenText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AppGreenButton(
              label: 'Học',
              icon: Icons.play_arrow_rounded,
              height: 40,
              fontSize: 14,
              onPressed: () {
                _showCardCountPicker(
                  hskLevel: hskLevel,
                  unitId: sec.unitId,
                  title: 'Học "$title"',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _deckChip(String text, Color color, Color background) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
    ),
  );
}

/// Khung đang tải khớp bố cục màn: thẻ "Hôm nay", hai nút phụ, chip HSK và
/// danh sách bộ thẻ.
class _FlashcardsHomeSkeleton extends StatelessWidget {
  const _FlashcardsHomeSkeleton();

  @override
  Widget build(BuildContext context) => AppShimmer(
        child: ListView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 32),
          children: [
            SkeletonCard(
              style: SkeletonCardStyle.cream,
              radius: 26,
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const SkeletonQuestionHeader(pandaSize: 64),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: ShimmerBox(width: 170, height: 13),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      for (var i = 0; i < 4; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        const Expanded(
                          child: SkeletonCard(
                            radius: 16,
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Column(
                              children: [
                                ShimmerBox.circle(size: 26),
                                SizedBox(height: 6),
                                ShimmerBox(width: 30, height: 16),
                                SizedBox(height: 5),
                                ShimmerBox(width: 44, height: 10),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 18),
                  const ShimmerBox(height: 56, radius: 20),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: _ButtonSkeleton()),
                SizedBox(width: 10),
                Expanded(child: _ButtonSkeleton()),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 40,
              child: Row(
                children: [
                  for (var i = 0; i < 4; i++) ...[
                    const SkeletonPill(width: 78, height: 38),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SkeletonSectionTitle(width: 110, showTrailing: true),
            const SizedBox(height: 12),
            for (var i = 0; i < 8; i++) ...[
              const SkeletonCard(
                padding: EdgeInsets.fromLTRB(14, 14, 12, 14),
                child: Row(
                  children: [
                    ShimmerBox(width: 46, height: 46, radius: 14),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerLine(widthFactor: .6, height: 15),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              SkeletonPill(width: 50, height: 17),
                              SizedBox(width: 6),
                              SkeletonPill(width: 50, height: 17),
                            ],
                          ),
                          SizedBox(height: 9),
                          ShimmerBox(height: 7, radius: 99),
                        ],
                      ),
                    ),
                    SizedBox(width: 10),
                    ShimmerBox(width: 72, height: 44, radius: 15),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      );
}

/// Ô giữ chỗ cho nút phụ phẳng (viền xanh xám, nền trắng).
class _ButtonSkeleton extends StatelessWidget {
  const _ButtonSkeleton();

  @override
  Widget build(BuildContext context) => const SkeletonCard(
        height: 46,
        radius: 17,
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Center(child: ShimmerBox(width: 96, height: 13)),
      );
}
