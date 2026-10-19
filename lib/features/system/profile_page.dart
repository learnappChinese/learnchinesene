import 'package:flutter/material.dart';
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
      body: _buildAchievements(context),
    );
  }

  Widget _buildAchievements(BuildContext context) {
    return FutureBuilder<UserStats>(
      future: _userStatsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: GameVisualTokens.primaryGreen),
                SizedBox(height: 16),
                Text('Đang tải dữ liệu...'),
              ],
            ),
          );
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
