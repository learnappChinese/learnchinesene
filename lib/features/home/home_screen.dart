import 'package:flutter/material.dart';
import 'widgets/home_practice_tab.dart';
import 'widgets/home_navigation_rail.dart';
import 'package:get/get.dart';
import '../../core/config/feature_flags.dart';
import '../hsk/hsk_screen.dart';
import '../speaking/speaking_screen.dart';
import '../stats/stats_screen.dart';
import 'controller/home_controller.dart';
import 'widgets/home_dashboard.dart';
import 'widgets/home_learning_tab.dart';
import 'widgets/home_progress_tab.dart';
import 'widgets/home_personal_tab.dart';
import 'widgets/home_bottom_navigation.dart';
import 'widgets/home_decorations.dart';
import 'widgets/shared_tab_background.dart';
import '../hanzi_writing/screens/hanzi_writing_home_screen.dart';
import '../../core/responsive/responsive_layout.dart';
import '../conversations/conversations_screen.dart';
import '../lessons/lessons_screen.dart';
import '../hsk_exam/hsk_exam_screen.dart';
import '../history/history_screen.dart';
import '../dictionary/dictionary_screen.dart';
import '../flashcards/flashcards_screen.dart';
import '../hsk_quiz/hsk_quiz_screen.dart';
import '../system/profile_page.dart';
import '../unit_overview/binding/unit_overview_binding.dart';
import '../unit_overview/page/unit_overview_screen.dart';
import '../review/review_screen.dart';
import '../sections/learning_sections_screen.dart';
import '../../core/widgets/learning_scaffold.dart';
import '../../core/widgets/panda_companion.dart';
import '../../core/learning/model/recommended_next_action.dart';
import '../../core/learning/service/learning_progress_sync_service.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  HomeController get controller => Get.find<HomeController>();

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabs = [
      _buildHomeDashboard(),
      _buildLearningTab(),
      _buildGamesTab(),
      _buildProgressTab(),
      _buildPersonalTab(),
    ];
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        Get.isRegistered<LearningProgressSyncService>()) {
      Get.find<LearningProgressSyncService>().syncOnAppResume();
    }
  }

  Widget _buildHomeDashboard() {
    return Obx(() {
      final stats = controller.stats;
      return HomeDashboard(
        journey: controller.journey.value,
        isLoading: controller.isJourneyLoading.value,
        errorMessage: controller.journeyError.value,
        streak: controller.streak.value > 0
            ? controller.streak.value
            : (stats['streak']?.toInt() ?? 0),
        lessons: stats['learned']?.toInt() ?? 0,
        xp: controller.todayXp.value,
        onRefresh: controller.refreshStats,
        onRetry: controller.refreshStats,
        onStartLearning: _openCurrentJourney,
        onGrammar: () => Get.to(() => const HanziWritingHomeScreen()),
        onListening: () => Get.to(() => const FlashcardsScreen()),
        onSpeaking: () => Get.to(
          () => const SpeakingScreen(),
          arguments: const {'standalone': true},
        ),
        onChallenge: () => Get.to(() => const HskQuizScreen()),
        onProgress: () => controller.setIndex(3),
        onReview: () => Get.to(() => const ReviewScreen()),
        onViewAllQuickActions: () => controller.setIndex(1),
      );
    });
  }

  Widget _buildLearningTab() => Obx(() => HomeLearningTab(
        journey: controller.journey.value,
        reviewSummary: controller.reviewSummary.value,
        onLearningPath: _openCurrentJourney,
        onReview: () => Get.to(() => const ReviewScreen()),
        onHanzi: () => Get.to(() => const HanziWritingHomeScreen()),
        onSpeaking: () => Get.to(
          () => const SpeakingScreen(),
          arguments: const {'standalone': true},
        ),
        onFlashcards: () => Get.to(() => const FlashcardsScreen()),
        onPractice: () => Get.to(
          () => _buildPracticePage(),
        ),
        onVocabulary: () => Get.to(() => const LearningSectionsScreen()),
        onSections: () => Get.to(() => const LearningSectionsScreen()),
        onHsk: () => Get.to(() => const HskScreen()),
        onLessons: FeatureFlags.enableAi ? () => Get.to(() => const LessonsScreen()) : () {},
        onConversation: FeatureFlags.enableAi ? () => Get.to(() => const ConversationsScreen()) : () {},
      ));

  void _openCurrentJourney() {
    final journey = controller.journey.value;
    final nextAction = journey?.nextAction;

    if (nextAction != null) {
      switch (nextAction.type) {
        case RecommendedActionType.review:
          Get.to(() => const ReviewScreen());
          return;
        case RecommendedActionType.explore:
          Get.to(() => const LearningSectionsScreen());
          return;
        case RecommendedActionType.nextUnit:
          if (nextAction.unitId != null && nextAction.unitId!.isNotEmpty) {
            Get.to(
              () => const UnitOverviewScreen(),
              binding: UnitOverviewBinding(
                unitId: nextAction.unitId!,
                unitTitle: nextAction.title,
                sectionNumber: nextAction.sectionNumber ?? 1,
                unitNumber: nextAction.unitNumber ?? 1,
              ),
            );
            return;
          }
          break;
        case RecommendedActionType.resume:
        case RecommendedActionType.fightBoss:
        case RecommendedActionType.startMission:
        case RecommendedActionType.practiceWeakness:
          if (journey?.unitId != null && journey!.unitId!.isNotEmpty) {
            Get.to(
              () => const UnitOverviewScreen(),
              binding: UnitOverviewBinding(
                unitId: journey.unitId!,
                unitTitle: journey.chapterTitle,
                sectionNumber: journey.worldNumber,
                unitNumber: journey.chapterNumber,
              ),
            );
            return;
          }
          break;
      }
    }

    if (journey == null || journey.unitId == null) {
      Get.to(() => const LearningSectionsScreen());
      return;
    }
    Get.to(
      () => const UnitOverviewScreen(),
      binding: UnitOverviewBinding(
        unitId: journey.unitId!,
        unitTitle: journey.chapterTitle,
        sectionNumber: journey.worldNumber,
        unitNumber: journey.chapterNumber,
      ),
    );
  }

  Widget _buildGamesTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PandaCompanion(mood: PandaMood.thinking, size: 96),
            SizedBox(height: 16),
            Text(
              'Tính năng Trò chơi đang hoàn thiện',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF342E10),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Các mini-game vui nhộn đang được cải tiến để mang lại trải nghiệm học tập tốt nhất. Bạn vui lòng quay lại sau nhé!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressTab() => HomeProgressTab(
        onStats: () => Get.to(() => const StatsScreen()),
        onExam: FeatureFlags.enableAi ? () => Get.to(() => const HskExamScreen()) : () {},
        onHistory: () => Get.to(() => const HistoryScreen()),
      );

  Widget _buildPersonalTab() => HomePersonalTab(
        onProfile: () => Get.to(() => const ProfilePage()),
        onDictionary: FeatureFlags.enableAi ? () => Get.to(() => const DictionaryScreen()) : () {},
      );

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final index = controller.currentIndex.value.clamp(0, 4);
      final content = IndexedStack(
        index: index,
        children: _tabs,
      );

      final body = index == 0 ? content : SharedTabBackground(child: content);

      return ResponsiveLayout(
        mobile: _buildMobileLayout(index, body),
        tablet: _buildRailLayout(index, body),
        desktop: _buildRailLayout(index, body, extended: true),
      );
    });
  }

  Widget _buildMobileLayout(int index, Widget body) {
    return Scaffold(
      backgroundColor: index == 0 ? homePageBackground : homeCream,
      extendBody: true,
      body: body,
      bottomNavigationBar: HomeBottomNavigation(
        currentIndex: index,
        onSelected: controller.setIndex,
      ),
    );
  }

  Widget _buildRailLayout(int index, Widget body, {bool extended = false}) {
    return Scaffold(
      body: Row(
        children: [
          HomeNavigationRail(
              index: index,
              onSelected: controller.setIndex,
              extended: extended),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _buildPracticePage() {
    return LearningScaffold(
      title: 'Học tập & Luyện tập',
      body: Obx(
        () => HomePracticeTab(
          journey: controller.journey.value,
          reviewSummary: controller.reviewSummary.value,
          isLoading: controller.isJourneyLoading.value,
          onReview: () => Get.to(() => const ReviewScreen()),
          onSpeaking: () => Get.to(() => const SpeakingScreen(),
              arguments: const {'standalone': true}),
          onWriting: () => Get.to(() => const HanziWritingHomeScreen()),
          onFlashcards: () => Get.to(() => const FlashcardsScreen()),
          onLearningPath: _openCurrentJourney,
          onQuiz: () => Get.to(() => const HskQuizScreen()),
        ),
      ),
    );
  }
}
