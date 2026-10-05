import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'theme/app_colors.dart';
import 'screens/home/home_screen.dart';
import 'screens/game_hub/game_hub_screen.dart';
import 'screens/boss_battle/boss_battle_intro_screen.dart';
import 'screens/boss_battle/boss_battle_gameplay_screen.dart';
import 'screens/boss_battle/boss_battle_victory_screen.dart';
import 'screens/boss_battle/boss_battle_defeat_screen.dart';
import 'screens/radical_builder/radical_builder_screen.dart';
import 'screens/tone_ninja/tone_ninja_screen.dart';
import 'screens/chinese_restaurant/chinese_restaurant_screen.dart';
import 'screens/quick_answer/quick_answer_screen.dart';

void main() {
  runApp(const ChineseLearningGameApp());
}

class ChineseLearningGameApp extends StatelessWidget {
  const ChineseLearningGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(440, 956),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) => MaterialApp(
        title: 'Chinese Boss Battle',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Roboto',
          scaffoldBackgroundColor: AppColors.backgroundDark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryOrange,
            primary: AppColors.primaryOrange,
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => HomeScreen(
                onNavigateToGameHub: () =>
                    Navigator.pushNamed(context, '/game_hub'),
              ),
          '/game_hub': (context) => GameHubScreen(
                onBackToHome: () => Navigator.pop(context),
                onSelectBossBattle: () =>
                    Navigator.pushNamed(context, '/boss_intro'),
                onSelectRadicalBuilder: () =>
                    Navigator.pushNamed(context, '/radical_builder'),
                onSelectToneNinja: () =>
                    Navigator.pushNamed(context, '/tone_ninja'),
                onSelectRestaurant: () =>
                    Navigator.pushNamed(context, '/restaurant'),
                onSelectQuickAnswer: () =>
                    Navigator.pushNamed(context, '/quick_answer'),
              ),
          '/boss_intro': (context) => BossBattleIntroScreen(
                onBack: () => Navigator.pop(context),
                onStartGame: () =>
                    Navigator.pushNamed(context, '/boss_gameplay'),
              ),
          '/boss_gameplay': (context) => BossBattleGameplayScreen(
                onExit: () => Navigator.pop(context),
                onVictory: () =>
                    Navigator.pushReplacementNamed(context, '/victory'),
                onDefeat: () =>
                    Navigator.pushReplacementNamed(context, '/defeat'),
              ),
          '/victory': (context) => BossBattleVictoryScreen(
                onContinue: () =>
                    Navigator.pushReplacementNamed(context, '/boss_gameplay'),
                onBackToHub: () => Navigator.popUntil(
                    context, ModalRoute.withName('/game_hub')),
              ),
          '/defeat': (context) => BossBattleDefeatScreen(
                onRetry: () =>
                    Navigator.pushReplacementNamed(context, '/boss_gameplay'),
                onBackToHub: () => Navigator.popUntil(
                    context, ModalRoute.withName('/game_hub')),
              ),
          '/radical_builder': (context) => RadicalBuilderScreen(
                onBack: () => Navigator.pop(context),
              ),
          '/tone_ninja': (context) => ToneNinjaScreen(
                onBack: () => Navigator.pop(context),
              ),
          '/restaurant': (context) => ChineseRestaurantScreen(
                onBack: () => Navigator.pop(context),
              ),
          '/quick_answer': (context) => QuickAnswerScreen(
                onBack: () => Navigator.pop(context),
              ),
        },
      ),
    );
  }
}
