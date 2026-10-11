import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/database/db_helper.dart';
import '../home/controller/home_controller.dart';
import '../vocabulary/data/models/user_stats_model.dart';
import 'widget/profile_achievements.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with WidgetsBindingObserver {
  late Future<UserStats> _userStatsFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStats();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStats();
    }
  }

  Future<UserStats> _loadStats() async {
    final dbStats = await DbHelper.instance.getStats();
    int exp = dbStats['totalExp']?.toInt() ?? 0;
    int streak = dbStats['streak']?.toInt() ?? 0;
    final mastered = dbStats['mastered']?.toInt() ?? 0;
    final favorites = dbStats['favorites']?.toInt() ?? 0;

    if (Get.isRegistered<HomeController>()) {
      final home = Get.find<HomeController>();
      if (home.lifetimeXp.value > 0) exp = home.lifetimeXp.value;
      if (home.streak.value > 0) streak = home.streak.value;
    }

    return UserStats(
      id: 1,
      totalExp: exp,
      currentStreak: streak,
      lastStudyDate: DateTime.now(),
      totalWordsMastered: mastered,
      totalFavorites: favorites,
    );
  }

  void _refreshStats() {
    setState(() {
      _userStatsFuture = _loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ & thành tích'),
        actions: [
          // ⟲ Nút refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshStats,
            tooltip: 'Tải lại dữ liệu',
          ),
        ],
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
                CircularProgressIndicator(),
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

        return ProfileAchievements(userStats: userStats);
      },
    );
  }
}
