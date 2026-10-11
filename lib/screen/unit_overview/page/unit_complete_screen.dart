import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/learning/data/learning_journey_repository.dart';
import '../../../core/learning/model/learning_journey_models.dart';
import '../../../core/responsive/responsive_layout.dart';
import '../../../core/theme/game_visual_tokens.dart';
import '../../../core/widgets/learning_scaffold.dart';
import '../../../core/widgets/learning_scene_background.dart';
import '../../../core/widgets/panda_companion.dart';
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
    this.xpEarned = 50,
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
    Get.back(result: true);
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
                  _buildStarsRow(),
                  const SizedBox(height: 12),
                  _buildRibbon(),
                  const SizedBox(height: 20),
                  const PandaCompanion(
                    size: 130,
                    mood: PandaMood.victory,
                    speechText: 'Tuyệt đỉnh công phu! Bạn đã hoàn thành bài học!',
                  ),
                  const SizedBox(height: 20),
                  _buildSummaryCard(),
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

  Widget _buildStarsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final active = i < widget.starsEarned;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            active ? '⭐' : '🖤',
            style: TextStyle(fontSize: i == 1 ? 52 : 36),
          ),
        );
      }),
    );
  }

  Widget _buildRibbon() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [GameVisualTokens.crimson, GameVisualTokens.imperialGold],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: GameVisualTokens.crimson.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Text(
        '🏆 BÀI HỌC HOÀN THÀNH 🏆',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: GameVisualTokens.imperialGold, width: 2),
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
              color: GameVisualTokens.goldLight,
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
              color: Color(0xFFE2E8F0),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _metricBadge('PHẦN THƯỞNG', '+${widget.xpEarned} XP',
                  GameVisualTokens.imperialGold),
              _metricBadge('THÀNH THẠO', '100%', GameVisualTokens.jade),
              _metricBadge('XẾP HẠNG', 'Xuất sắc', const Color(0xFF38BDF8)),
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
            color: Color(0xFF94A3B8),
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
