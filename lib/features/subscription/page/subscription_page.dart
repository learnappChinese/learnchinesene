import '../../../../core/helper/app_toast.dart';
import '../controller/subscription_controller.dart';
import '../widgets/package_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

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
        AppToast.showError(context: context, title: controller.errorMessage.value ?? 'Có lỗi xảy ra khi thanh toán');
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

  ProductDetails? _getProduct(String id) {
    try {
      return controller.products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(title: const Text("Nâng cấp Premium")),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Obx(() => _buildPremiumPackage(context)),
                const SizedBox(height: 24),
                Obx(() => _buildStandardPackage(context)),
              ],
            ),
          ),
        ),
        Obx(() {
          if (controller.status.value == SubscriptionStatus.purchasePending) {
            return Container(
              color: Colors.black45,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildPremiumPackage(BuildContext context) {
    final product = _getProduct('premium_package');
    final price = product?.price ?? '299.000 đ';

    return PackageCardWidget(
      index: 1,
      title: 'Gói Cao Cấp',
      price: price,
      icon: Icons.workspace_premium_rounded,
      features: const ['Mở khóa toàn bộ từ vựng HSK 1-6', 'Hội thoại AI & Thi thử HSK không giới hạn'],
      isSelected: controller.selectedPackageIndex.value == 1,
      isPopular: true,
      isActive: controller.activeProductId.value == 'premium_package',
      remainingDays: controller.activeProductId.value == 'premium_package' ? controller.remainingDays : null,
      onTap: () {
        controller.selectPackage(1);
      },
      onSubscribeTap: () {
        if (product != null) {
          controller.subscribe(product);
        } else {
          AppToast.showError(context: context, title: 'Gói chưa sẵn sàng');
        }
      },
    );
  }

  Widget _buildStandardPackage(BuildContext context) {
    final product = _getProduct('standard_package');
    final price = product?.price ?? '69.000 đ';

    return PackageCardWidget(
      index: 0,
      title: 'Gói Tiêu Chuẩn',
      price: price,
      icon: Icons.menu_book_rounded,
      features: const ['Học từ vựng cơ bản HSK 1-3'],
      isSelected: controller.selectedPackageIndex.value == 0,
      isActive: controller.activeProductId.value == 'standard_package',
      remainingDays: controller.activeProductId.value == 'standard_package' ? controller.remainingDays : null,
      onTap: () {
        controller.selectPackage(0);
      },
      onSubscribeTap: () {
        if (product != null) {
          controller.subscribe(product);
        } else {
          AppToast.showError(context: context, title: 'Gói chưa sẵn sàng');
        }
      },
    );
  }
}
