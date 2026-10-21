import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/backend/supabase_bootstrap.dart';
import 'core/theme/app_theme.dart';
import 'core/database/app_database.dart';
import 'di.dart';
import 'features/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Render the first Flutter frame immediately.
  // Local-first SQLite storage boots up first so users can study offline.
  runApp(const AppBootstrap());
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  Object? _error;
  bool _ready = false;
  bool _diInitialized = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    if (mounted && _error != null) {
      setState(() => _error = null);
    }

    try {
      // 1. Khởi tạo Database SQLite cục bộ & nạp dữ liệu HSK đóng gói sẵn
      await AppDatabase.instance.init();
      await AppDatabase.instance.ensureContentPackSeeded();

      // 2. Khởi tạo Dependency Injection
      if (!_diInitialized) {
        initDI();
        _diInitialized = true;
      }

      // 3. Khởi tạo Supabase không đồng bộ (Không bao giờ chặn màn hình khi offline)
      unawaited(_initCloudOptional());

      if (!mounted) return;
      setState(() => _ready = true);
    } catch (error) {
      debugPrint('Khởi động dữ liệu cục bộ thất bại: $error');
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  Future<void> _initCloudOptional() async {
    try {
      await SupabaseBootstrap.initialize().timeout(
        const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint('Khởi động chế độ Ngoại tuyến (Offline mode): $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      return const ChineseMasterApp();
    }

    // Màn khởi động giống hệt Splash nhưng không có vòng tải; Splash nối tiếp
    // ngay sau mà không chạy lại hiệu ứng logo.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: SplashIntro(
        error: _error == null
            ? null
            : 'Không thể đọc dữ liệu học trên máy. '
                'Hãy thử lại hoặc khởi động lại ứng dụng.',
        onRetry: _initialize,
      ),
    );
  }
}
