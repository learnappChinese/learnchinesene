import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/backend/supabase_bootstrap.dart';
import 'di.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Render the first Flutter frame immediately. Network/backend bootstrap runs
  // inside the widget tree so Android is never held on its pre-draw listener
  // while waiting for Supabase.
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
  bool _loading = true;
  bool _diInitialized = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      await SupabaseBootstrap.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException(
          'Không thể kết nối máy chủ trong 15 giây.',
        ),
      );

      if (!_diInitialized) {
        initDI();
        _diInitialized = true;
      }

      if (!mounted) return;
      setState(() {
        _ready = true;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      return const ChineseMasterApp();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD32F2F)),
        useMaterial3: true,
      ),
      home: _buildBootstrapScreen(),
    );
  }

  Widget _buildConnectionStatus() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: _loading
          ? const _CloudLoadingView(key: ValueKey('loading'))
          : _CloudErrorView(
              key: const ValueKey('error'),
              error: _error,
              onRetry: _initialize,
            ),
    );
  }

  Widget _buildBootstrapScreen() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: _buildConnectionStatus(),
          ),
        ),
      ),
    );
  }
}

class _CloudLoadingView extends StatelessWidget {
  const _CloudLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 42,
          height: 42,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        SizedBox(height: 20),
        Text(
          'Đang kết nối dữ liệu học...',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _CloudErrorView extends StatelessWidget {
  const _CloudErrorView({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final Object? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final details = error?.toString() ?? 'Không xác định được lỗi kết nối.';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off_rounded, size: 52),
        const SizedBox(height: 16),
        const Text(
          'Không thể kết nối dữ liệu',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ứng dụng đang dùng dữ liệu trực tuyến. Hãy kiểm tra mạng rồi thử lại.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          details,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Thử lại'),
        ),
      ],
    );
  }
}
