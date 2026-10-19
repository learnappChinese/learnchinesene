import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/learning/data/learning_journey_repository.dart';
import '../../../core/learning/model/learning_journey_models.dart';
import '../../../core/learning/model/learning_navigation_outcome.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/theme/game_visual_tokens.dart';
import '../../../core/widgets/learning_scaffold.dart';
import '../../../core/widgets/learning_scene_background.dart';
import '../../../core/widgets/panda_companion.dart';
import '../../../core/widgets/adventure_quest_banner.dart';
import '../../hsk/hsk_screen.dart';
import '../binding/unit_overview_binding.dart';
import 'unit_overview_screen.dart';

class UnitCompleteScreen extends StatefulWidget {
  const UnitCompleteScreen({
    super.key,
    required this.unitId,
    required this.unitTitle,
    this.sectionNumber = 1,
    this.unitNumber = 1,
    this.bossName,
    this.xpEarned = 0,
    this.starsEarned = 3,
    this.journeyRepository,
  });

  final String unitId;
  final String unitTitle;
  final int sectionNumber;
  final int unitNumber;
  final String? bossName;
  final int xpEarned;
  final int starsEarned;
  final LearningJourneyRepository? journeyRepository;

  @override
  State<UnitCompleteScreen> createState() => _UnitCompleteScreenState();
}

class _UnitCompleteScreenState extends State<UnitCompleteScreen> {
  late final LearningJourneyRepository _journeyRepo;
  bool _isLoadingNext = true;
  LearningUnitViewModel? _nextUnit;

  @override
  void initState() {
    super.initState();
    _journeyRepo =
        widget.journeyRepository ?? SupabaseLearningJourneyRepository();
    _resolveNextUnit();
  }

  Future<void> _resolveNextUnit() async {
    try {
      final next = await _journeyRepo.getNextUnit(widget.unitId);
      if (mounted) {
        setState(() {
          _nextUnit = next;
          _isLoadingNext = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingNext = false;
        });
      }
    }
  }

  void _onGoToNextUnit() {
    if (_nextUnit != null) {
      Get.off(
        () => const UnitOverviewScreen(),
        binding: UnitOverviewBinding(
          unitId: _nextUnit!.id,
          unitTitle: _nextUnit!.title,
          sectionNumber: _nextUnit!.sectionNumber,
          unitNumber: _nextUnit!.unitNumber,
        ),
      );
    } else {
      Get.off(() => const HskScreen());
    }
  }

  void _onBackToUnit() {
    Get.back(
      result: LearningNavigationOutcome.completed(
        nextUnitId: _nextUnit?.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: 'Hoàn thành bài học',
      body: LearningSceneBackground(
        theme: LearningSceneTheme.bambooVillage,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveHelper.contentMaxWidth(context),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.horizontalPadding(context),
                vertical: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AdventureQuestBanner(
                    eyebrow:
                        'Chương ${widget.sectionNumber} · Chặng hoàn thành',
                    title: 'Bài ${widget.unitNumber}: ${widget.unitTitle}',
                    description: widget.bossName != null
                        ? 'Bạn đã vượt mọi nhiệm vụ và đánh bại ${widget.bossName}. Panda đã sẵn sàng đồng hành sang chặng kế tiếp.'
                        : 'Bạn đã hoàn thành hành trình của bài học này. Cùng Panda tiếp tục khám phá bản đồ phía trước!',
                    statusLabel: '${widget.starsEarned.clamp(0, 3)}/3 sao',
                    mood: PandaMood.victory,
                    accent: GameVisualTokens.crimson,
                  ),
                  const SizedBox(height: 20),
                  _buildSummaryCard(),
                  const SizedBox(height: 14),
                  _buildNextJourneyCard(),
                  const SizedBox(height: 28),
                  _buildPrimaryNextButton(),
                  const SizedBox(height: 12),
                  _buildSecondaryBackButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFBEB), Color(0xFFFFF1D4)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: GameVisualTokens.imperialGold.withValues(alpha: .72),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'BÀI ${widget.unitNumber}: ${widget.unitTitle}'.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: GameVisualTokens.ink,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.bossName != null
                ? 'Đã chinh phục tất cả ải và đánh bại Boss ${widget.bossName}!'
                : 'Đã hoàn thành xuất sắc tất cả ải học trong bài!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: GameVisualTokens.muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _metricBadge(
                'PHẦN THƯỞNG',
                '+${widget.xpEarned} XP',
                GameVisualTokens.imperialGold,
              ),
              _metricBadge(
                'HUY HIỆU',
                '${widget.starsEarned.clamp(0, 3)}/3 sao',
                GameVisualTokens.jade,
              ),
              _metricBadge(
                'HÀNH TRÌNH',
                _isLoadingNext
                    ? 'Đang tải'
                    : (_nextUnit == null ? 'Bản đồ' : 'Bài kế'),
                GameVisualTokens.crimson,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: GameVisualTokens.muted,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildNextJourneyCard() {
    final next = _nextUnit;
    return Semantics(
      container: true,
      label: _isLoadingNext
          ? 'Đang tìm bài học tiếp theo'
          : next == null
              ? 'Hành trình tiếp theo là bản đồ thế giới'
              : 'Bài học tiếp theo: ${next.title}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: GameVisualTokens.jade.withValues(alpha: .28),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: GameVisualTokens.jade.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: _isLoadingNext
                  ? const Padding(
                      padding: EdgeInsets.all(13),
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(
                      Icons.explore_rounded,
                      color: GameVisualTokens.jade,
                      size: 28,
                    ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ĐÍCH ĐẾN TIẾP THEO',
                    style: TextStyle(
                      color: GameVisualTokens.jade,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isLoadingNext
                        ? 'Đang mở bản đồ hành trình…'
                        : next == null
                            ? 'Trở về bản đồ thế giới'
                            : 'Bài ${next.unitNumber}: ${next.title}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GameVisualTokens.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryNextButton() {
    final next = _nextUnit;
    final label = _isLoadingNext
        ? 'ĐANG TẢI BÀI TIẾP THEO...'
        : (next != null
            ? 'BÀI HỌC TIẾP THEO: ${next.title}'
            : 'VỀ BẢN ĐỒ THẾ GIỚI');

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: _isLoadingNext ? null : _onGoToNextUnit,
        style: FilledButton.styleFrom(
          backgroundColor: GameVisualTokens.jade,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryBackButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: _onBackToUnit,
        icon: const Icon(Icons.menu_book_rounded,
            color: GameVisualTokens.templeWood, size: 18),
        label: const Text(
          'Xem lại bài học vừa hoàn thành',
          style: TextStyle(
            color: GameVisualTokens.templeWood,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
