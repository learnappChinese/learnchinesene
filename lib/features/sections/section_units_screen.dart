import 'package:flutter/material.dart';
import '../../core/widgets/app_shimmer.dart';
import 'package:get/get.dart';
import '../../core/learning/data/learning_journey_repository.dart';
import '../../core/learning/model/learning_journey_models.dart';
import '../../core/learning/service/learning_progress_sync_service.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/game_visual_tokens.dart';
import '../../core/theme/learning_theme.dart';
import '../../core/widgets/adventure_node.dart';
import '../../core/widgets/app_green_button.dart';
import '../../core/widgets/learning_scaffold.dart';
import '../../core/widgets/learning_scene_background.dart';
import '../../core/widgets/learning_trail.dart';
import '../../core/widgets/segmented_progress_node.dart';
import '../../core/widgets/locked_mission_sheet.dart';
import '../../core/widgets/adventure_quest_banner.dart';
import '../../core/widgets/panda_companion.dart';
import '../home/widgets/home_decorations.dart';
import '../unit_overview/binding/unit_overview_binding.dart';
import '../unit_overview/page/unit_overview_screen.dart';

class SectionUnitsScreen extends StatefulWidget {
  const SectionUnitsScreen({super.key, required this.section});

  final LearningSectionViewModel section;

  @override
  State<SectionUnitsScreen> createState() => _SectionUnitsScreenState();
}

class _SectionUnitsScreenState extends State<SectionUnitsScreen> {
  final LearningJourneyRepository _journeyRepo =
      SupabaseLearningJourneyRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<LearningUnitViewModel> _units = const [];
  LearningSyncRegistration? _syncRegistration;
  int _loadRequest = 0;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<LearningProgressSyncService>()) {
      _syncRegistration = Get.find<LearningProgressSyncService>()
          .registerRefresher(
            owner: 'section-units:${widget.section.id}',
            domains: const <LearningDomain>{
              LearningDomain.journey,
              LearningDomain.unitPath,
              LearningDomain.identity,
            },
            refresh: (event) async {
              if (event.type == LearningDomainEventType.identityChanged &&
                  mounted) {
                setState(() => _units = const []);
              }
              await _loadUnits(rethrowFailure: true);
            },
          );
    }
    _loadUnits();
  }

  @override
  void dispose() {
    _loadRequest++;
    _syncRegistration?.dispose();
    super.dispose();
  }

  Future<void> _loadUnits({bool rethrowFailure = false}) async {
    final request = ++_loadRequest;
    final hasData = _units.isNotEmpty;
    // Đã có dữ liệu thì làm mới ngầm, không hiện lại skeleton.
    if (!hasData) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final list = await _journeyRepo.getUnits(
        widget.section.id,
        isSectionUnlocked: widget.section.isUnlocked,
      );
      if (mounted && request == _loadRequest) {
        setState(() {
          _units = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && request == _loadRequest && !hasData) {
        setState(() {
          _errorMessage = 'Không thể tải danh sách bài học: $e';
          _isLoading = false;
        });
      }
      if (rethrowFailure) rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: 'Phần ${widget.section.sectionNumber}',
      body: LearningSceneBackground(
        theme: LearningSceneTheme.bambooVillage,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const _SectionUnitsSkeleton();
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              AppGreenButton(
                label: 'Thử lại',
                icon: Icons.refresh_rounded,
                onPressed: _loadUnits,
              ),
            ],
          ),
        ),
      );
    }

    if (_units.isEmpty) {
      return const Center(child: Text('Chưa có bài học nào trong phần này.'));
    }

    final units = _units.toList()
      ..sort((a, b) => a.unitNumber.compareTo(b.unitNumber));
    final completed = units.where((unit) => unit.isCompleted).length;
    final target = units.firstWhereOrNull(
      (unit) => unit.isUnlocked && !unit.isCompleted,
    );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ResponsiveHelper.contentMaxWidth(context),
        ),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            ResponsiveHelper.horizontalPadding(context),
            16,
            ResponsiveHelper.horizontalPadding(context),
            40,
          ),
          children: [
            AdventureQuestBanner(
              eyebrow: 'Phần ${widget.section.sectionNumber}',
              title: widget.section.subtitle,
              description:
                  'Hoàn thành từng bài theo thứ tự để mở khóa bài tiếp theo.',
              progress: completed / units.length,
              progressLabel: '$completed/${units.length} bài',
              statusLabel: completed == units.length
                  ? 'Đã hoàn thành'
                  : completed > 0 || target?.inProgress == true
                  ? 'Đang phiêu lưu'
                  : 'Sẵn sàng khởi hành',
              mood: PandaMood.happy,
              compact: true,
            ),
            const SizedBox(height: 22),
            const Row(
              children: [
                HomePandaFace(size: 26),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Lộ trình bài học',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.homeInk,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final (i, unit) in units.indexed)
              LearningTrailEntry(
                isFirst: i == 0,
                isLast: i == units.length - 1,
                lineColor: unit.isCompleted
                    ? GameVisualTokens.primaryGreen
                    : const Color(0xFFCBD5E1),
                node: SegmentedProgressNode(
                  totalSegments: unit.missionCount,
                  completedSegments: unit.completedMissionCount,
                  state: _nodeState(unit),
                  icon: unit.isCompleted
                      ? Icons.emoji_events_rounded
                      : Icons.menu_book_rounded,
                  isActive: unit.id == target?.id,
                  size: 56,
                  ringWidth: 5,
                ),
                child: _UnitCard(
                  unit: unit,
                  isTarget: unit.id == target?.id,
                  onTap: () => _openUnit(context, unit),
                ),
              ),
          ],
        ),
      ),
    );
  }

  AdventureNodeState _nodeState(LearningUnitViewModel unit) {
    if (!unit.isUnlocked) return AdventureNodeState.locked;
    if (unit.isCompleted) return AdventureNodeState.completed;
    if (unit.inProgress) return AdventureNodeState.inProgress;
    return AdventureNodeState.available;
  }

  void _openUnit(BuildContext context, LearningUnitViewModel unit) {
    if (!unit.isUnlocked) {
      showLockedMissionSheet(
        context,
        title: 'Bài học chưa mở',
        message:
            unit.lockReason ?? 'Hoàn thành bài học trước để mở khóa bài này.',
      );
      return;
    }
    Get.to(
      () => const UnitOverviewScreen(),
      binding: UnitOverviewBinding(
        unitId: unit.id,
        unitTitle: unit.title,
        sectionNumber: unit.sectionNumber,
        unitNumber: unit.unitNumber,
      ),
    );
  }
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({
    required this.unit,
    required this.isTarget,
    required this.onTap,
  });

  final LearningUnitViewModel unit;
  final bool isTarget;
  final VoidCallback onTap;

  static final _numberPrefix = RegExp(r'^Bài\s*\d+\s*[:.\-–]\s*');

  @override
  Widget build(BuildContext context) {
    final isLocked = !unit.isUnlocked;
    final isCompleted = unit.isCompleted;
    final title = unit.title.replaceFirst(_numberPrefix, '');
    final mastery = (unit.mastery * 100).round();

    return LearningTrailCard(
      onTap: onTap,
      highlight: isTarget,
      completed: isCompleted,
      locked: isLocked,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LearningTrailTag(
                label: 'BÀI ${unit.unitNumber}',
                background: isLocked
                    ? const Color(0xFFE2E8F0)
                    : isTarget
                    ? GameVisualTokens.primaryGreen
                    : GameVisualTokens.primaryGreen.withValues(alpha: .12),
                foreground: isLocked
                    ? const Color(0xFF64748B)
                    : isTarget
                    ? Colors.white
                    : GameVisualTokens.primaryGreenDark,
              ),
              if (isTarget) ...[
                const SizedBox(width: 6),
                const LearningTrailTag(
                  label: 'ĐANG HỌC',
                  background: GameVisualTokens.primaryGreenSoft,
                  foreground: GameVisualTokens.primaryGreenDark,
                ),
              ],
              const Spacer(),
              if (isLocked)
                const Icon(
                  Icons.lock_rounded,
                  size: 16,
                  color: Color(0xFF94A3B8),
                )
              else if (isCompleted)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: GameVisualTokens.primaryGreen,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              height: 1.25,
              color: isLocked ? const Color(0xFF64748B) : AppColors.homeTitle,
            ),
          ),
          if (unit.subtitle.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              unit.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                color: LearningColors.muted,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    LearningTrailMeta(
                      icon: Icons.flag_rounded,
                      text:
                          '${unit.completedMissionCount}/${unit.missionCount} nhiệm vụ',
                    ),
                    if (unit.estimatedMinutes > 0)
                      LearningTrailMeta(
                        icon: Icons.schedule_rounded,
                        text: '~${unit.estimatedMinutes} phút',
                      ),
                    if (!isLocked && mastery > 0)
                      LearningTrailMeta(
                        icon: Icons.psychology_rounded,
                        text: 'Thành thạo $mastery%',
                      ),
                  ],
                ),
              ),
              if (isTarget)
                LearningTrailStartPill(
                  label: unit.completedMissionCount == 0
                      ? 'Bắt đầu'
                      : 'Tiếp tục',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Khung đang tải khớp bố cục màn: banner, tiêu đề lộ trình, các thẻ bài.
class _SectionUnitsSkeleton extends StatelessWidget {
  const _SectionUnitsSkeleton();

  @override
  Widget build(BuildContext context) => AppShimmer(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveHelper.contentMaxWidth(context),
            ),
            child: ListView(
              physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
              padding: EdgeInsets.fromLTRB(
                ResponsiveHelper.horizontalPadding(context),
                16,
                ResponsiveHelper.horizontalPadding(context),
                40,
              ),
              children: [
                const SkeletonQuestBanner(),
                const SizedBox(height: 22),
                const SkeletonSectionTitle(width: 150),
                const SizedBox(height: 14),
                for (var i = 0; i < 10; i++)
                  SkeletonTrailEntry(
                    isFirst: i == 0,
                    isLast: i == 9,
                    child: SkeletonTrailCard(showAction: i == 0),
                  ),
              ],
            ),
          ),
        ),
      );
}
