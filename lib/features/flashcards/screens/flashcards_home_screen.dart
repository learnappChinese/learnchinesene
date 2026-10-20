import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/game_visual_tokens.dart';
import '../../../core/widgets/learning_scene_background.dart';
import '../../../core/widgets/panda_companion.dart';
import '../controller/flashcards_deck_controller.dart';
import '../models/flashcard_models.dart';
import 'flashcard_settings_screen.dart';
import 'flashcard_stats_screen.dart';
import 'flashcard_study_screen.dart';

/// Trang chủ Flashcard với Dashboard Spaced Repetition thông minh,
/// danh sách bộ thẻ theo HSK/Section và các lối tắt ôn tập FSRS.
class FlashcardsHomeScreen extends StatefulWidget {
  final int initialLevel;

  const FlashcardsHomeScreen({
    super.key,
    this.initialLevel = 1,
  });

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

  void _showCardCountPicker({
    int? hskLevel,
    int? unitId,
    String? title,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Học Flashcard FSRS',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: GameVisualTokens.ink),
            tooltip: 'Thống kê',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FlashcardStatsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: GameVisualTokens.ink),
            tooltip: 'Cài đặt',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FlashcardSettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: LearningSceneBackground(
        theme: LearningSceneTheme.bambooVillage,
        child: SafeArea(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(
                  color: GameVisualTokens.primaryGreen,
                ),
              );
            }

            final stats = controller.dashboardStats.value;
            final selectedHsk = controller.selectedHskLevel.value;
            final currentDeck = controller.hskDecks.firstWhereOrNull(
              (d) => d.level == selectedHsk,
            );

            return RefreshIndicator(
              onRefresh: controller.loadDashboardAndDecks,
              color: GameVisualTokens.primaryGreen,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  // 1. Dashboard tổng quan FSRS
                  if (stats != null) _buildDashboardHeader(stats),
                  const SizedBox(height: 16),

                  // 2. Lối tắt nhanh
                  _buildQuickActionShortcuts(stats),
                  const SizedBox(height: 18),

                  // 3. Tab chọn HSK Level
                  _buildHskSelector(),
                  const SizedBox(height: 12),

                  // 4. Danh sách các Section trong HSK
                  if (currentDeck != null) ...[
                    if (!currentDeck.isAvailable)
                      _buildUnavailableHskNotice(currentDeck.level)
                    else ...[
                      // Tiêu đề HSK và nút học cả HSK
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${currentDeck.name} (${currentDeck.totalWords} từ vựng)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: GameVisualTokens.ink,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              _showCardCountPicker(
                                hskLevel: currentDeck.level,
                                title: 'Học toàn bộ ${currentDeck.name}',
                              );
                            },
                            icon: const Icon(Icons.play_arrow_rounded, size: 18),
                            label: const Text(
                              'Học cả HSK',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Danh sách từng Section/Unit
                      ...currentDeck.sections.map((sec) => _buildSectionDeckCard(sec, currentDeck.level)),
                    ],
                  ],
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDashboardHeader(FlashcardDashboardStats stats) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const PandaCompanion(
                mood: PandaMood.happy,
                size: 64,
                animate: false,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HÔM NAY CẦN ÔN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '${stats.dueToday}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: GameVisualTokens.primaryGreenDark,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'thẻ đến hạn',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '🔥 Chuỗi học: ${stats.streakDays} ngày liên tiếp',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Lưới các trạng thái thẻ (Anki Matrix)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatPill('Ôn tập', '${stats.dueToday}', const Color(0xFF059669)),
                _buildDivider(),
                _buildStatPill('Thẻ mới', '${stats.newAvailable}', const Color(0xFF0284C7)),
                _buildDivider(),
                _buildStatPill('Đang học', '${stats.learningCount}', const Color(0xFFD97706)),
                _buildDivider(),
                _buildStatPill('Đã nhớ', '${stats.reviewCount}', const Color(0xFF7C3AED)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Nút lớn BẮT ĐẦU ÔN TẬP
          GestureDetector(
            onTap: () {
              if (stats.dueToday > 0) {
                _openStudySession(onlyDue: true, cardLimit: 30);
              } else {
                _openStudySession(onlyNew: true, cardLimit: 20);
              }
            },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    GameVisualTokens.primaryGreen,
                    GameVisualTokens.primaryGreenDark,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: GameVisualTokens.primaryGreenDark.withValues(alpha: 0.35),
                    offset: const Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    stats.dueToday > 0 ? 'BẮT ĐẦU ÔN TẬP NGAY' : 'HỌC THẺ MỚI HÔM NAY',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 28, color: const Color(0xFFE2E8F0));
  }

  Widget _buildQuickActionShortcuts(FlashcardDashboardStats? stats) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.add_circle_outline_rounded,
            label: 'Học thẻ mới',
            color: const Color(0xFF0284C7),
            onTap: () => _openStudySession(onlyNew: true, cardLimit: 20),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionButton(
            icon: Icons.history_edu_rounded,
            label: 'Chỉ ôn đến hạn',
            color: GameVisualTokens.primaryGreenDark,
            onTap: () => _openStudySession(onlyDue: true, cardLimit: 30),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHskSelector() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [1, 2, 3, 4, 5, 6].map((lvl) {
          final isSelected = controller.selectedHskLevel.value == lvl;
          final isLocked = lvl > 4;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(isLocked ? 'HSK $lvl 🔒' : 'HSK $lvl'),
              onSelected: (_) {
                controller.selectHsk(lvl);
              },
              selectedColor: GameVisualTokens.primaryGreenSoft,
              checkmarkColor: GameVisualTokens.primaryGreenDark,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected
                    ? GameVisualTokens.primaryGreen
                    : const Color(0xFFE2E8F0),
              ),
              labelStyle: TextStyle(
                color: isSelected
                    ? GameVisualTokens.primaryGreenDark
                    : isLocked
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF334155),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUnavailableHskNotice(int lvl) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
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
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: GameVisualTokens.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Dữ liệu từ vựng HSK 5 & 6 sẽ sớm ra mắt. Bạn hãy chinh phục các cấp độ HSK 1–4 trước nhé!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDeckCard(FlashcardSectionDeck sec, int hskLevel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  sec.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: GameVisualTokens.ink,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _showCardCountPicker(
                    hskLevel: hskLevel,
                    unitId: sec.unitId,
                    title: 'Học "${sec.title}"',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameVisualTokens.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Học',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Tổng ${sec.totalWords} thẻ',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 12),
              if (sec.dueWords > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${sec.dueWords} đến hạn',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              if (sec.newWords > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '${sec.newWords} mới',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF0284C7)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: sec.progressPercent / 100.0,
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(
                GameVisualTokens.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
