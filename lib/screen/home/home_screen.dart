import 'package:flutter/material.dart';
import 'widgets/home_practice_tab.dart';
import 'widgets/home_navigation_rail.dart';
import 'package:get/get.dart';
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
import '../subscription/page/subscription_page.dart';
import '../subscription/controller/subscription_controller.dart';
import '../../core/helper/upgrade_dialog_helper.dart';
import '../duolingo/duo_game_center_screen.dart';
import '../game_hub/game_hub_screen.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeController get controller => Get.find<HomeController>();

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      _buildHomeDashboard(),
      _buildLearningTab(),
      _buildGamesTab(),
      _buildProgressTab(),
      _buildPersonalTab(),
    ];
  }

  void _runIfFeatureUnlocked(String featureKey, String title, String message,
      List<String> benefits, VoidCallback onUnlocked) {
    final subController = Get.find<SubscriptionController>();
    if (subController.isFeatureUnlocked(featureKey)) {
      onUnlocked();
    } else {
      UpgradeDialogHelper.showUpgradeDialog(
        context: context,
        title: title,
        message: message,
        benefits: benefits,
      );
    }
  }

  Widget _buildHomeDashboard() {
    return Obx(() {
      final stats = controller.stats;
      return HomeDashboard(
        streak: stats['streak']?.toInt() ?? 0,
        lessons: stats['learned']?.toInt() ?? 0,
        xp: stats['totalExp']?.toInt() ?? 0,
        onRefresh: controller.refreshStats,
        onStartLearning: () => Get.to(() => const HskScreen()),
        onGrammar: () => _runIfFeatureUnlocked(
          'lessons',
          'Mở khóa Bài học AI',
          'Tính năng này yêu cầu nâng cấp.',
          const ['Bài học ngữ pháp chuyên sâu'],
          () => Get.to(() => const LessonsScreen()),
        ),
        onListening: () => Get.to(() => const ConversationsScreen()),
        onSpeaking: () => Get.to(
          () => const SpeakingScreen(),
          arguments: const {'standalone': true},
        ),
        onChallenge: () => Get.to(() => const HskQuizScreen()),
        onProgress: () => controller.setIndex(3),
        onViewAllQuickActions: () => controller.setIndex(1),
      );
    });
  }

  Widget _buildLearningTab() => HomeLearningTab(
        onPractice: () => Get.to(
          () => _buildPracticePage(),
        ),
        onVocabulary: () => Get.to(() => const HskScreen()),
        onLessons: () => _runIfFeatureUnlocked(
          'lessons',
          'Mở khóa Bài học AI',
          'Tính năng biên soạn bài học ngữ pháp AI yêu cầu nâng cấp gói cước Cao Cấp.',
          const [
            'Bài học ngữ pháp chuyên sâu tự động',
            'Bài tập thực hành đi kèm phong phú',
            'Hỏi đáp bài học trực tiếp'
          ],
          () => Get.to(() => const LessonsScreen()),
        ),
        onConversation: () => _runIfFeatureUnlocked(
          'ai_chat',
          'Mở khóa Hội thoại AI',
          'Tính năng trò chuyện tình huống thông minh yêu cầu nâng cấp gói cước Cao Cấp.',
          const [
            'Giao tiếp tình huống không giới hạn',
            'Phát âm và sửa lỗi thời gian thực',
            'Đàm thoại AI thông minh'
          ],
          () => Get.to(() => const ConversationsScreen()),
        ),
      );

  Widget _buildGamesTab() {
    return const GameHubScreen(embedded: true);
  }

  Widget _buildProgressTab() => HomeProgressTab(
        onStats: () => Get.to(() => const StatsScreen()),
        onExam: () => _runIfFeatureUnlocked(
          'hsk_exam',
          'Mở khóa Thi thử AI',
          'Tính năng làm đề thi thử và chấm điểm AI yêu cầu nâng cấp gói cước Cao Cấp.',
          const [
            'Đề thi thử HSK 1-6 chuẩn cấu trúc',
            'Chấm điểm và sửa bài chi tiết bằng AI',
            'Xem lại lịch sử thi bất kỳ lúc nào'
          ],
          () => Get.to(() => const HskExamScreen()),
        ),
        onHistory: () => Get.to(() => const HistoryScreen()),
      );

  Widget _buildPersonalTab() => HomePersonalTab(
        onProfile: () => Get.to(() => const ProfilePage()),
        onPremium: () => Get.to(() => const SubscriptionPage()),
        onDictionary: () => Get.to(() => const DictionaryScreen()),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Luyện tập')),
      body: SafeArea(
          child: HomePracticeTab(
              onSpeaking: () => Get.to(() => const SpeakingScreen(),
                  arguments: const {'standalone': true}),
              onWriting: () => Get.to(() => const HanziWritingHomeScreen()),
              onFlashcards: () => Get.to(() => const FlashcardsScreen()),
              onLearningPath: () => Get.to(() => const DuoGameCenterScreen()),
              onQuiz: () => Get.to(() => const HskQuizScreen()))),
    );
  }
}
