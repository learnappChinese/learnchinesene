import 'package:flutter/material.dart';

class PurchasePendingOverlay extends StatelessWidget {
  const PurchasePendingOverlay({super.key, required this.isPending});

  final bool isPending;

  @override
  Widget build(BuildContext context) {
    if (!isPending) return const SizedBox.shrink();
    return BlockSemantics(
      child: Semantics(
        label: 'Đang xử lý thanh toán',
        liveRegion: true,
        child: Container(
          color: Colors.black45,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
