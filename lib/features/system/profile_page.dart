import 'package:flutter/material.dart';
import '../../core/widgets/learning_scene_background.dart';
import '../../core/widgets/app_shimmer.dart';
import 'package:get/get.dart';
import '../../core/theme/game_visual_tokens.dart';
import '../../core/database/db_helper.dart';
import '../../core/learning/service/learning_progress_sync_service.dart';
import '../vocabulary/data/models/user_stats_model.dart';
import 'widget/profile_achievements.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<UserStats> _userStatsFuture;
  LearningSyncRegistration? _syncRegistration;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<LearningProgressSyncService>()) {
      _syncRegistration =
          Get.find<LearningProgressSyncService>().registerRefresher(
        owner: 'profile',
        domains: const <LearningDomain>{
          LearningDomain.profile,
          LearningDomain.stats,
          LearningDomain.identity,
        },
        refresh: (_) => _refreshStats(),
      );
    }
    _refreshStats();
  }

  @override
  void dispose() {
    _syncRegistration?.dispose();
    super.dispose();
  }

  Future<UserStats> _loadStats() async {
    final dbStats = await DbHelper.instance.getStats();
    final exp = dbStats['totalExp']?.toInt() ?? 0;
    final streak = dbStats['streak']?.toInt() ?? 0;
    final mastered = dbStats['mastered']?.toInt() ?? 0;
    final favorites = dbStats['favorites']?.toInt() ?? 0;

    return UserStats(
      id: 1,
      totalExp: exp,
      currentStreak: streak,
      lastStudyDate: DateTime.now(),
      totalWordsMastered: mastered,
      totalFavorites: favorites,
    );
  }

  Future<void> _refreshStats() async {
    final next = _loadStats();
    setState(() {
      _userStatsFuture = next;
    });
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ & thành tích'),
      ),
      body: SafeBottomArea(child: _buildAchievements(context)),
    );
  }

  Widget _buildAchievements(BuildContext context) {
    return FutureBuilder<UserStats>(
      future: _userStatsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _ProfileSkeleton();
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('❌ Lỗi: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshStats,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        final userStats = snapshot.data;
        if (userStats == null) {
          return const Center(child: Text('❌ Không có dữ liệu'));
        }

        return RefreshIndicator(
          color: GameVisualTokens.primaryGreen,
          onRefresh: _refreshStats,
          child: ProfileAchievements(userStats: userStats),
        );
      },
    );
  }
}

/// Khung đang tải khớp hồ sơ: thẻ danh tính, hai ô chỉ số, danh hiệu và
/// các chip năng lực.
class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) => AppShimmer(
        child: ListView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.all(20),
          children: [
            const SkeletonCard(
              style: SkeletonCardStyle.cream,
              radius: 24,
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  ShimmerBox.circle(size: 68),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerLine(widthFactor: .6, height: 18),
                        SizedBox(height: 8),
                        ShimmerLine(widthFactor: .4, height: 12),
                        SizedBox(height: 10),
                        SkeletonPill(width: 90, height: 22),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Expanded(child: SkeletonListTile(leadingSize: 36, radius: 16)),
                SizedBox(width: 12),
                Expanded(child: SkeletonListTile(leadingSize: 36, radius: 16)),
              ],
            ),
            const SizedBox(height: 24),
            const ShimmerBox(width: 170, height: 12),
            const SizedBox(height: 12),
            for (var i = 0; i < 5; i++) ...[
              const SkeletonListTile(leadingSize: 44, radius: 16),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 14),
            const ShimmerBox(width: 150, height: 12),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SkeletonPill(width: 140, height: 34),
                SkeletonPill(width: 130, height: 34),
                SkeletonPill(width: 120, height: 34),
                SkeletonPill(width: 110, height: 34),
              ],
            ),
          ],
        ),
      );
}
