import 'package:flash_learn_chinese/core/helper/app_toast.dart';
import '../controller/subscription_controller.dart';
import '../widgets/package_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/subscription_package_definition.dart';
import '../widgets/purchase_pending_overlay.dart';

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
                'Có lỗi xảy ra khi thanh toán');
      } else if (status == SubscriptionStatus.purchaseSuccess) {
        AppToast.showSuccess(context: context, title: 'Thanh toán thành công!');
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
          backgroundColor: Colors.white,
          appBar: AppBar(title: const Text("Nâng cấp Premium")),
          body: _buildPackageList(context),
        ),
        Obx(() => PurchasePendingOverlay(
              isPending:
                  controller.status.value == SubscriptionStatus.purchasePending,
            )),
      ],
    );
  }

  Widget _buildPackage(
      BuildContext context, SubscriptionPackageDefinition package) {
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

  Widget _buildPackageList(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          for (var i = 0; i < subscriptionPackages.length; i++) ...[
            if (i > 0) const SizedBox(height: 24),
            Obx(() => _buildPackage(context, subscriptionPackages[i])),
          ],
        ],
      ),
    );
  }
}
