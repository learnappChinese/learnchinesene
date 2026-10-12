import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/learning/data/learning_journey_repository.dart';
import '../../core/learning/model/learning_journey_models.dart';
import '../../core/learning/service/learning_progress_sync_service.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/theme/game_visual_tokens.dart';
import '../../core/widgets/learning_scaffold.dart';
import '../../core/widgets/learning_scene_background.dart';
import '../../core/widgets/locked_mission_sheet.dart';
import '../../core/widgets/adventure_quest_banner.dart';
import '../../core/widgets/panda_companion.dart';
import '../unit_overview/binding/unit_overview_binding.dart';
import '../unit_overview/page/unit_overview_screen.dart';

class SectionUnitsScreen extends StatefulWidget {
  const SectionUnitsScreen({
    super.key,
    required this.section,
  });

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
      _syncRegistration =
          Get.find<LearningProgressSyncService>().registerRefresher(
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await _journeyRepo.getUnits(widget.section.id);
      if (mounted && request == _loadRequest) {
        setState(() {
          _units = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && request == _loadRequest) {
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
      title: '${widget.section.title}: ${widget.section.subtitle}',
      body: LearningSceneBackground(
        theme: LearningSceneTheme.bambooVillage,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: GameVisualTokens.jade),
      );
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
              FilledButton(
                onPressed: _loadUnits,
                style: FilledButton.styleFrom(
                    backgroundColor: GameVisualTokens.jade),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_units.isEmpty) {
      return const Center(
        child: Text('Chưa có bài học nào trong phần này.'),
      );
    }

    final units = _units.toList()
      ..sort((a, b) => a.unitNumber.compareTo(b.unitNumber));
    final completed = units.where((unit) => unit.isCompleted).length;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ResponsiveHelper.contentMaxWidth(context),
        ),
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(
            ResponsiveHelper.horizontalPadding(context),
            20,
            ResponsiveHelper.horizontalPadding(context),
            40,
          ),
          itemCount: units.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, idx) {
            if (idx == 0) {
              return AdventureQuestBanner(
                eyebrow: widget.section.title,
                title: widget.section.subtitle,
                description:
                    'Đi lần lượt qua từng Unit. Unit đang học luôn ở đầu đường và Boss bảo vệ lối sang phần mới.',
                progress: units.isEmpty ? 0 : completed / units.length,
                progressLabel: '$completed/${units.length} Unit',
                statusLabel: 'Phần ${widget.section.sectionNumber}',
                mood: PandaMood.happy,
                compact: true,
              );
            }
            final unit = units[idx - 1];
            return _UnitPathCard(
              index: idx - 1,
              isLast: idx == units.length,
              child: _UnitCard(
                unit: unit,
                onTap: () {
                  if (!unit.isUnlocked) {
                    showLockedMissionSheet(
                      context,
                      title: 'Bài học chưa mở',
                      message: unit.lockReason ??
                          'Hoàn thành bài học trước để mở khóa bài này.',
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
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UnitPathCard extends StatelessWidget {
  const _UnitPathCard({
    required this.index,
    required this.isLast,
    required this.child,
  });

  final int index;
  final bool isLast;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final left = index.isEven ? 0.0 : 24.0;
    final right = index.isEven ? 24.0 : 0.0;
    return Padding(
      padding: EdgeInsets.only(left: left, right: right),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (!isLast)
            Positioned(
              left: index.isEven ? 28 : null,
              right: index.isEven ? null : 28,
              top: 114,
              bottom: -24,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: GameVisualTokens.imperialGold.withValues(alpha: .6),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({
    required this.unit,
    required this.onTap,
  });

  final LearningUnitViewModel unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLocked = !unit.isUnlocked;
    final isCompleted = unit.isCompleted;
    final inProgress = unit.inProgress;

    return Container(
      decoration: BoxDecoration(
        color: isLocked ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? GameVisualTokens.jade.withValues(alpha: 0.6)
              : inProgress
                  ? GameVisualTokens.imperialGold
                  : const Color(0xFFE2E8F0),
          width: inProgress ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLocked ? 0.02 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isLocked
                            ? Colors.grey.shade200
                            : isCompleted
                                ? GameVisualTokens.jade.withValues(alpha: 0.15)
                                : GameVisualTokens.imperialGold
                                    .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isLocked
                            ? '🔒'
                            : isCompleted
                                ? '⭐'
                                : '📜',
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unit.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: isLocked
                                  ? Colors.grey.shade600
                                  : GameVisualTokens.templeWood,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            unit.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${unit.completedMissionCount} / ${unit.missionCount} nhiệm vụ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isLocked
                                ? Colors.grey
                                : GameVisualTokens.templeWood,
                          ),
                        ),
                        if (!isLocked) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: GameVisualTokens.imperialGold
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Mastery ${(unit.mastery * 100).round()}%',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: GameVisualTokens.gold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    _buildActionButton(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    if (!unit.isUnlocked) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, size: 16, color: Colors.grey),
          SizedBox(width: 4),
          Text('Khóa', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      );
    }

    if (unit.isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: GameVisualTokens.jade.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'ĐÃ HOÀN THÀNH',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: GameVisualTokens.jadeDark,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: GameVisualTokens.jade,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        unit.completedMissionCount == 0 ? 'BẮT ĐẦU' : 'TIẾP TỤC',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
