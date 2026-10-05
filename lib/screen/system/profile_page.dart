import 'package:flutter/material.dart';
import 'widget/profile_achievements.dart';
import 'package:get/get.dart';

import '../vocabulary/data/models/user_stats_model.dart';
import '../vocabulary/domain/usecases/get_user_stats.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with WidgetsBindingObserver, RouteAware {
  late GetUserStatsUseCase _getUserStats;
  late Future<UserStats> _userStatsFuture;
  late RouteObserver<ModalRoute<dynamic>> _routeObserver;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _routeObserver = Get.find<RouteObserver<ModalRoute<dynamic>>>();
    _getUserStats = Get.find<GetUserStatsUseCase>();
    _refreshStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ⭐ Register trang này với RouteObserver
    _routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPush() {
    print('👁️ [PROFILE] Trang được push');
  }

  @override
  void didPopNext() {
    print('👁️ [PROFILE] Quay lại từ trang khác → Refresh streak');
    _refreshStats();
  }

  @override
  void didPop() {
    print('👁️ [PROFILE] Trang bị pop');
  }

  @override
  void dispose() {
    _routeObserver.unsubscribe(this); // ⭐ Unsubscribe khi dispose
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ⭐ Khi trang được resume (user quay lại từ practice)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('👁️ [PROFILE] App resumed → Refresh streak');
      _refreshStats();
    }
  }

  // 🔄 Hàm refresh dữ liệu từ database
  void _refreshStats() {
    print('🔄 [PROFILE] _refreshStats() được gọi');
    setState(() {
      _userStatsFuture = _getUserStats().then((stats) {
        print('📊 [PROFILE] Dữ liệu từ database:');
        print('   💰 totalExp: ${stats.totalExp}');
        print('   🔥 currentStreak: ${stats.currentStreak}');
        print('   📖 totalWordsMastered: ${stats.totalWordsMastered}');
        print('   📅 lastStudyDate: ${stats.lastStudyDate}');
        return stats;
      }).catchError((e) {
        print('❌ [PROFILE] Lỗi load dữ liệu: $e');
        throw e; // ⭐ Throw error để FutureBuilder xử lý
      });
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
