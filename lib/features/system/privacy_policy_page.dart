import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_green_button.dart';

const _privacyPolicyUrl =
    'https://sites.google.com/view/privacy-policy-for-pandarin/trang-ch%E1%BB%A7';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Tạo controller một lần để trang không bị tải lại mỗi lần rebuild.
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress);
        },
        onPageStarted: (_) {
          if (mounted) setState(() => _hasError = false);
        },
        onWebResourceError: (error) {
          // Chỉ báo lỗi khi chính trang chính không tải được.
          if (error.isForMainFrame ?? true) {
            if (mounted) setState(() => _hasError = true);
          }
        },
      ))
      ..loadRequest(Uri.parse(_privacyPolicyUrl));
  }

  void _reload() {
    setState(() {
      _hasError = false;
      _progress = 0;
    });
    _controller.loadRequest(Uri.parse(_privacyPolicyUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chính sách quyền riêng tư'),
        bottom: _progress < 100 && !_hasError
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _progress == 0 ? null : _progress / 100,
                  minHeight: 3,
                  color: AppColors.homeGreen,
                  backgroundColor: AppColors.homeTrack,
                ),
              )
            : null,
      ),
      body: _hasError ? _buildError() : WebViewWidget(controller: _controller),
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 56, color: AppColors.homeIconMuted),
              const SizedBox(height: 12),
              const Text(
                'Không tải được trang.\nVui lòng kiểm tra kết nối mạng.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.homeBody,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              AppGreenButton(
                label: 'Thử lại',
                icon: Icons.refresh_rounded,
                onPressed: _reload,
              ),
            ],
          ),
        ),
      );
}
