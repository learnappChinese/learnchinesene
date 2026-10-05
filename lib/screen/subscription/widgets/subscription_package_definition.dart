import 'package:flutter/material.dart';

class SubscriptionPackageDefinition {
  const SubscriptionPackageDefinition({
    required this.productId,
    required this.index,
    required this.title,
    required this.fallbackPrice,
    required this.icon,
    required this.features,
    this.isPopular = false,
  });

  final String productId;
  final int index;
  final String title;
  final String fallbackPrice;
  final IconData icon;
  final List<String> features;
  final bool isPopular;
}

const subscriptionPackages = [
  SubscriptionPackageDefinition(
    productId: 'premium_package',
    index: 1,
    title: 'Gói Cao Cấp',
    fallbackPrice: '299.000 đ',
    icon: Icons.workspace_premium_rounded,
    features: [
      'Mở khóa toàn bộ từ vựng HSK 1-6',
      'Hội thoại AI & Thi thử HSK không giới hạn',
    ],
    isPopular: true,
  ),
  SubscriptionPackageDefinition(
    productId: 'standard_package',
    index: 0,
    title: 'Gói Tiêu Chuẩn',
    fallbackPrice: '69.000 đ',
    icon: Icons.menu_book_rounded,
    features: ['Học từ vựng cơ bản HSK 1-3'],
  ),
];
