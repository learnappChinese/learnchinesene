import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';

class ChineseMasterApp extends StatelessWidget {
  const ChineseMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(440, 956),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Pandarin: Learn Chinese & HSK',
        theme: AppTheme.light,
        // Giao diện chuẩn theo màn Home, chỉ có chế độ sáng.
        themeMode: ThemeMode.light,
        home: const SplashScreen(),
      ),
    );
  }
}
