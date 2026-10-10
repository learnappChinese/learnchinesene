import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/learning/data/learning_journey_repository.dart';
import '../../core/learning/model/learning_journey_models.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/theme/game_visual_tokens.dart';
import '../../core/widgets/learning_scaffold.dart';
import '../../core/widgets/learning_scene_background.dart';
import '../../core/widgets/locked_mission_sheet.dart';
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

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  Future<void> _loadSections() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await _journeyRepo.getSections();
      if (mounted) {
        setState(() {
          _sections = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể tải danh sách phần học: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: 'Lộ trình học tập',
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
                onPressed: _loadSections,
                style: FilledButton.styleFrom(
                    backgroundColor: GameVisualTokens.jade),
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
                child: const Text('THỬ LẠI'),
              ),
            ],
          ),
        ),
      );
    }

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
          itemCount: _sections.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, idx) {
            final section = _sections[idx];
            return _SectionCard(
              section: section,
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
                )?.then((_) => _loadSections());
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
  });

  final LearningSectionViewModel section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLocked = !section.isUnlocked;
    final isCompleted = section.isCompleted;

    return Container(
      decoration: BoxDecoration(
        color: isLocked ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? GameVisualTokens.jade.withValues(alpha: 0.6)
              : isLocked
                  ? const Color(0xFFE2E8F0)
                  : GameVisualTokens.imperialGold.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLocked ? 0.02 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isLocked
                        ? Colors.grey.shade200
                        : isCompleted
                            ? GameVisualTokens.jade.withValues(alpha: 0.15)
                            : GameVisualTokens.imperialGold
                                .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isLocked
                        ? '🔒'
                        : isCompleted
                            ? '🏆'
                            : '🏮',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: isLocked ? Colors.grey : GameVisualTokens.gold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        section.subtitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isLocked
                              ? Colors.grey.shade600
                              : GameVisualTokens.templeWood,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${section.completedUnitCount} / ${section.unitCount} bài hoàn thành',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isLocked
                      ? Icons.lock_rounded
                      : Icons.arrow_forward_ios_rounded,
                  color: isLocked ? Colors.grey : GameVisualTokens.jade,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
