import 'package:flutter/material.dart';
import '../../core/widgets/app_shimmer.dart';
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
import 'section_units_screen.dart';

class LearningSectionsScreen extends StatefulWidget {
  const LearningSectionsScreen({super.key});

  @override
  State<LearningSectionsScreen> createState() => _LearningSectionsScreenState();
}

class _LearningSectionsScreenState extends State<LearningSectionsScreen> {
  final LearningJourneyRepository _journeyRepo =
      SupabaseLearningJourneyRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<LearningSectionViewModel> _sections = const [];
  LearningSyncRegistration? _syncRegistration;
  int _loadRequest = 0;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<LearningProgressSyncService>()) {
      _syncRegistration =
          Get.find<LearningProgressSyncService>().registerRefresher(
        owner: 'learning-sections',
        domains: const <LearningDomain>{
          LearningDomain.journey,
          LearningDomain.unitPath,
          LearningDomain.identity,
        },
        refresh: (event) async {
          if (event.type == LearningDomainEventType.identityChanged &&
              mounted) {
            setState(() => _sections = const []);
          }
          await _loadSections(rethrowFailure: true);
        },
      );
    }
    _loadSections();
  }

  @override
  void dispose() {
    _loadRequest++;
    _syncRegistration?.dispose();
    super.dispose();
  }

  Future<void> _loadSections({bool rethrowFailure = false}) async {
    final request = ++_loadRequest;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await _journeyRepo.getSections();
      if (mounted && request == _loadRequest) {
        setState(() {
          _sections = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && request == _loadRequest) {
        setState(() {
          _errorMessage = 'Không thể tải danh sách phần học: $e';
          _isLoading = false;
        });
      }
      if (rethrowFailure) rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: 'Lộ trình học tập',
      // Nội dung cuộn tràn xuống đáy, khoảng đệm nằm ở cuối danh sách.
      useSafeArea: false,
      body: LearningSceneBackground(
        theme: LearningSceneTheme.bambooVillage,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const _LearningSectionsSkeleton();
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
                onPressed: _loadSections,
                style: FilledButton.styleFrom(
                    backgroundColor: GameVisualTokens.primaryGreen),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_sections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🐼', style: TextStyle(fontSize: 54)),
              const SizedBox(height: 12),
              const Text(
                'Chưa có thế giới học tập',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Hãy thử đồng bộ lại curriculum từ Supabase.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadSections,
                style: FilledButton.styleFrom(
                    backgroundColor: GameVisualTokens.primaryGreen),
                child: const Text('THỬ LẠI'),
              ),
            ],
          ),
        ),
      );
    }

    final sections = _sections.toList()
      ..sort((a, b) => a.sectionNumber.compareTo(b.sectionNumber));
    final completed = sections.where((section) => section.isCompleted).length;
    final currentIndex =
        sections.indexWhere((s) => s.isUnlocked && !s.isCompleted);

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
            32 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          itemCount: sections.length + 1,
          separatorBuilder: (_, idx) => SizedBox(height: idx == 0 ? 18 : 0),
          itemBuilder: (context, idx) {
            if (idx == 0) {
              return AdventureQuestBanner(
                eyebrow: 'Bản đồ curriculum',
                title: 'Chọn vùng đất tiếp theo',
                description:
                    'Mỗi phần là một vùng phiêu lưu. Hoàn thành Unit và Boss để mở đường sang vùng kế tiếp.',
                progress: sections.isEmpty ? 0 : completed / sections.length,
                progressLabel: '$completed/${sections.length} phần',
                statusLabel: 'Dữ liệu thật',
                mood: PandaMood.archer,
                compact: true,
              );
            }
            final section = sections[idx - 1];
            return _SectionCard(
              section: section,
              isFirst: idx == 1,
              isLast: idx == sections.length,
              isCurrent: idx - 1 == currentIndex,
              onTap: () {
                if (!section.isUnlocked) {
                  showLockedMissionSheet(
                    context,
                    title: 'Phần học chưa mở',
                    message: section.requiredSectionNumber == null
                        ? 'Hoàn thành hành trình trước để mở khóa chủ đề này.'
                        : 'Đánh bại Boss cuối Phần ${section.requiredSectionNumber} để mở khóa.',
                  );
                  return;
                }
                Get.to(
                  () => SectionUnitsScreen(section: section),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.section,
    required this.onTap,
    required this.isFirst,
    required this.isLast,
    required this.isCurrent,
  });

  final LearningSectionViewModel section;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;
  final bool isCurrent;

  static const _ink = Color(0xFF342E10);
  static const _muted = Color(0xFF8C8577);
  static const _line = Color(0xFFF1E6CF);
  static const double _rail = 64;
  static const double _nodeCenter = 14 + 29;

  @override
  Widget build(BuildContext context) {
    final isLocked = !section.isUnlocked;
    final isCompleted = section.isCompleted;
    final progress = section.unitCount == 0
        ? 0.0
        : (section.completedUnitCount / section.unitCount).clamp(0.0, 1.0);
    final lineColor =
        isCompleted ? GameVisualTokens.primaryGreen : const Color(0xFFDCD3C1);

    return Stack(
      children: [
        if (!(isFirst && isLast))
          Positioned(
            left: _rail / 2 - 2,
            top: isFirst ? _nodeCenter : 0,
            bottom: isLast ? null : 0,
            height: isLast ? _nodeCenter : null,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: lineColor,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _rail,
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Center(child: _buildMedallion(isLocked, isCompleted)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Opacity(
                  opacity: isLocked ? .72 : 1,
                  child: _buildCard(isLocked, isCompleted, progress),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedallion(bool isLocked, bool isCompleted) {
    final (List<Color> colors, Color border, Color text) = isLocked
        ? (
            const [Color(0xFFF1EDE4), Color(0xFFE4DDCF)],
            Colors.white,
            const Color(0xFFA39C8C)
          )
        : isCompleted
            ? (
                const [
                  GameVisualTokens.primaryGreenLight,
                  GameVisualTokens.primaryGreen
                ],
                Colors.white,
                Colors.white
              )
            : isCurrent
                ? (
                    const [Colors.white, GameVisualTokens.primaryGreenSoft],
                    GameVisualTokens.primaryGreen,
                    GameVisualTokens.primaryGreenDark
                  )
                : (
                    const [Colors.white, Color(0xFFFFF4DE)],
                    const Color(0xFFF5C979),
                    const Color(0xFFB45309)
                  );

    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: colors,
              ),
              border: Border.all(color: border, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Color.lerp(colors.last, Colors.black, .2)!
                      .withValues(alpha: .5),
                  offset: const Offset(0, 4),
                ),
                if (isCurrent)
                  BoxShadow(
                    color: GameVisualTokens.primaryGreen.withValues(alpha: .4),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Text(
              '${section.sectionNumber}',
              style: TextStyle(
                color: text,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (isLocked || isCompleted)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? GameVisualTokens.gold
                      : const Color(0xFFA39C8C),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  isCompleted ? Icons.emoji_events_rounded : Icons.lock_rounded,
                  size: 11,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(bool isLocked, bool isCompleted, double progress) {
    final radius = BorderRadius.circular(18);
    return Container(
      decoration: BoxDecoration(
        color: isLocked ? const Color(0xFFFBF8F2) : Colors.white,
        borderRadius: radius,
        border: Border.all(
          color: isCurrent ? GameVisualTokens.primaryGreen : _line,
          width: isCurrent ? 2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrent
                ? GameVisualTokens.primaryGreen.withValues(alpha: .2)
                : const Color(0x14635D3B),
            blurRadius: isCurrent ? 16 : 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        shape: RoundedRectangleBorder(borderRadius: radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      section.title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        color: isLocked
                            ? _muted
                            : GameVisualTokens.primaryGreenDark,
                      ),
                    ),
                    const Spacer(),
                    _buildStatusChip(isLocked, isCompleted),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  section.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16.5,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                    color: isLocked ? const Color(0xFF6F685B) : _ink,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 7,
                          backgroundColor: _line,
                          color: GameVisualTokens.primaryGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${section.completedUnitCount}/${section.unitCount} bài',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isLocked
                            ? _muted
                            : GameVisualTokens.primaryGreenDark,
                      ),
                    ),
                  ],
                ),
                if (isLocked && section.requiredSectionNumber != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '🔒 Thắng Boss cuối Phần ${section.requiredSectionNumber} để mở',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isLocked, bool isCompleted) {
    if (isLocked) return const SizedBox.shrink();
    if (isCompleted) {
      return const _Chip(
        label: 'Hoàn thành',
        background: Color(0xFFFEF3C7),
        foreground: Color(0xFFB45309),
      );
    }
    if (isCurrent) {
      return const _Chip(
        label: 'Đang học ▶',
        background: GameVisualTokens.primaryGreen,
        foreground: Colors.white,
      );
    }
    return const Icon(Icons.chevron_right_rounded,
        color: GameVisualTokens.primaryGreen);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: foreground,
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
}

/// Khung đang tải khớp bố cục màn: banner bản đồ và các thẻ phần trên lộ trình.
class _LearningSectionsSkeleton extends StatelessWidget {
  const _LearningSectionsSkeleton();

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
                20,
                ResponsiveHelper.horizontalPadding(context),
                32,
              ),
              children: [
                const SkeletonQuestBanner(),
                const SizedBox(height: 18),
                for (var i = 0; i < 8; i++)
                  SkeletonTrailEntry(
                    isFirst: i == 0,
                    isLast: i == 7,
                    nodeSize: 58,
                    nodeTop: 14,
                    child: const SkeletonCard(
                      padding: EdgeInsets.fromLTRB(14, 12, 12, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBox(width: 60, height: 11),
                          SizedBox(height: 8),
                          ShimmerLine(widthFactor: .8, height: 17),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                  child: ShimmerBox(height: 7, radius: 99)),
                              SizedBox(width: 10),
                              ShimmerBox(width: 38, height: 12),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}
