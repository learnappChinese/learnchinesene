import 'package:flash_learn_chinese/core/helper/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../controller/subscription_controller.dart';
import '../widgets/package_card_widget.dart';
import '../widgets/purchase_pending_overlay.dart';
import '../widgets/subscription_package_definition.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final controller = Get.find<SubscriptionController>();

  late final Worker _statusWorker;

  @override
  void initState() {
    super.initState();

    _statusWorker = ever(controller.status, (status) {
      if (!mounted) return;
      if (status == SubscriptionStatus.purchaseError) {
        AppToast.showError(
          context: context,
          title: controller.errorMessage.value ??
              'Có lỗi xảy ra khi xác minh thanh toán',
        );
      } else if (status == SubscriptionStatus.purchaseSuccess) {
        AppToast.showSuccess(
          context: context,
          title: 'Đã kích hoạt gói thành công!',
        );
      }
    });
  }

  @override
  void dispose() {
    _statusWorker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFFBF8F2), // Warm Parchment
          appBar: AppBar(
            backgroundColor: const Color(0xFFFBF8F2),
            elevation: 0,
            iconTheme: const IconThemeData(color: AppColors.ink),
            title: const Text(
              "Nâng cấp Premium",
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => controller.restorePurchases(),
                child: const Text(
                  'Khôi phục',
                  style: TextStyle(
                    color: AppColors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          body: _buildBody(context),
        ),
        Obx(
          () => PurchasePendingOverlay(
            isPending: controller.status.value ==
                    SubscriptionStatus.purchasePending ||
                controller.status.value == SubscriptionStatus.purchaseVerifying,
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildActiveStatusBanner(),
          const SizedBox(height: 16),
          for (var i = 0; i < subscriptionPackages.length; i++) ...[
            if (i > 0) const SizedBox(height: 20),
            Obx(() => _buildPackage(context, subscriptionPackages[i])),
          ],
          const SizedBox(height: 24),
          _buildTermsAndPrivacy(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildActiveStatusBanner() {
    return Obx(() {
      if (!controller.isPremium && !controller.isStandard) {
        return const SizedBox.shrink();
      }

      final packageName =
          controller.isPremium ? 'Gói Cao Cấp (Premium)' : 'Gói Tiêu Chuẩn';
      final days = controller.remainingDays;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFA5D6A7)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.verified_rounded,
              color: Color(0xFF2E7D32),
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đang hoạt động: $packageName',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hạn sử dụng còn lại: $days ngày',
                    style: const TextStyle(
                      color: Color(0xFF388E3C),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPackage(
    BuildContext context,
    SubscriptionPackageDefinition package,
  ) {
    final product = controller.productFor(package.productId);
    final active = controller.activeProductId.value == package.productId;
    return PackageCardWidget(
      key: ValueKey(package.productId),
      index: package.index,
      title: package.title,
      price: product?.price ?? package.fallbackPrice,
      icon: package.icon,
      features: package.features,
      isSelected: controller.selectedPackageIndex.value == package.index,
      isPopular: package.isPopular,
      isActive: active,
      remainingDays: active ? controller.remainingDays : null,
      onTap: () => controller.selectPackage(package.index),
      onSubscribeTap: () {
        if (product != null) {
          controller.subscribe(product);
        } else {
          AppToast.showError(context: context, title: 'Gói chưa sẵn sàng');
        }
      },
    );
  }

  Widget _buildTermsAndPrivacy() {
    return Column(
      children: [
        const Text(
          'Thanh toán được bảo mật và xác thực bởi Google Play / Apple App Store.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {},
              child: const Text(
                'Điều khoản dịch vụ',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
            const Text('•', style: TextStyle(color: AppColors.muted)),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Chính sách bảo mật',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
