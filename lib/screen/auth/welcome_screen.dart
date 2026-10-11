import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/auth/controller/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20.h),
              // Panda illustration / avatar
              Container(
                width: 140.w,
                height: 140.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.red.withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 4,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/characters/panda_avatar.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.pets,
                      size: 64,
                      color: AppColors.red,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 28.h),
              // Title with Chinese fantasy branding
              Text(
                'Hán Ngữ Kỳ Hiệp',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.redDark,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                'CHINESE LEARNING ADVENTURE',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                  letterSpacing: 2.0,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  'Khởi đầu con đường chinh phục Tiếng Trung cùng Đại hiệp Panda! Khám phá từ vựng, ngữ pháp và khiêu chiến Boss huyền thoại.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.ink,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 48.h),
              // Main Action Buttons
              // 1. Play as Guest
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: () async {
                    await authController.continueAsGuest();
                    Get.offAll(() => const HomeScreen());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    elevation: 3,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow_rounded, size: 24),
                      SizedBox(width: 8.w),
                      Text(
                        'CHƠI THỬ NGAY (GUEST)',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              // 2. Sign In / Register Button
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: OutlinedButton(
                  onPressed: () {
                    Get.to(() => const LoginScreen());
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.redDark,
                    side: const BorderSide(color: AppColors.red, width: 1.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.login_rounded, size: 20),
                      SizedBox(width: 8.w),
                      Text(
                        'ĐĂNG NHẬP / TẠO TÀI KHOẢN',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              // Value proposition
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_done_outlined,
                      size: 16.sp, color: AppColors.muted),
                  SizedBox(width: 6.w),
                  Text(
                    'Đăng nhập giúp lưu tiến độ và học trên nhiều thiết bị',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
