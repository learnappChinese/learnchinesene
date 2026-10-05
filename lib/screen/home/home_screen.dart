import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
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
import '../../features/hanzi_writing/screens/hanzi_writing_home_screen.dart';
import '../../core/responsive/responsive_layout.dart';
import '../conversations/conversations_screen.dart';
import '../lessons/lessons_screen.dart';
import '../hsk_exam/hsk_exam_screen.dart';
import '../history/history_screen.dart';
import '../dictionary/dictionary_screen.dart';
import '../flashcards/flashcards_screen.dart';
import '../hsk_quiz/hsk_quiz_screen.dart';
import '../../features/system/presentation/pages/profile_page.dart';
import '../../features/subscription/page/subscription_page.dart';
import '../../features/subscription/controller/subscription_controller.dart';
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
        streak: stats['streak']?.toInt() ?? 7,
        lessons: stats['learned']?.toInt() ?? 12,
        xp: ((stats['correct'] ?? 0) * 10).toInt() + 156,
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
          () => Scaffold(
            appBar: AppBar(title: const Text('Luyện tập')),
            body: SafeArea(child: _buildPracticeTab()),
          ),
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

  Widget _buildPracticeTab() {
    return Center(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: ResponsiveHelper.contentMaxWidth(context)),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Luyện tập & Thực hành',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            _Action(
              icon: Icons.record_voice_over_rounded,
              title: 'Luyện phát âm',
              subtitle: 'Cải thiện phát âm với điểm số tức thì',
              color: AppColors.orange,
              onTap: () => Get.to(
                () => const SpeakingScreen(),
                arguments: const {'standalone': true},
              ),
            ),
            const SizedBox(height: 12),
            _Action(
              icon: Icons.draw_rounded,
              title: 'Luyện viết chữ Hán',
              subtitle: 'Học viết chữ Hán theo thứ tự nét chuẩn',
              color: AppColors.red,
              onTap: () => Get.to(() => const HanziWritingHomeScreen()),
            ),
            const SizedBox(height: 12),
            _Action(
              icon: Icons.style_rounded,
              title: 'Flashcards ôn tập',
              subtitle: 'Ghi nhớ từ vựng với hiệu ứng lật thẻ 3D',
              color: AppColors.success,
              onTap: () => Get.to(() => const FlashcardsScreen()),
            ),
            const SizedBox(height: 12),
            _Action(
              icon: Icons.games_rounded,
              title: 'Lộ Trình Học Tập',
              subtitle:
                  'Học tiếng Trung qua các trò chơi tương tác như Duolingo',
              color: Colors.blue,
              onTap: () => Get.to(() => const DuoGameCenterScreen()),
            ),
            const SizedBox(height: 12),
            _Action(
              icon: Icons.quiz_rounded,
              title: 'Trắc nghiệm HSK',
              subtitle: 'Bài tập trắc nghiệm ngẫu nhiên theo cấp độ HSK',
              color: AppColors.redDark,
              onTap: () => Get.to(() => const HskQuizScreen()),
            ),
          ],
        ),
      ),
    );
  }

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
        children: [
          _buildHomeDashboard(),
          _buildLearningTab(),
          _buildGamesTab(),
          _buildProgressTab(),
          _buildPersonalTab(),
        ],
      );

      final body = index == 0 ? content : SharedTabBackground(child: content);

      return ResponsiveLayout(
        mobile: Scaffold(
          backgroundColor: index == 0 ? homePageBackground : homeCream,
          extendBody: true,
          body: body,
          bottomNavigationBar: HomeBottomNavigation(
            currentIndex: index,
            onSelected: controller.setIndex,
          ),
        ),
        tablet: Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: index,
                onDestinationSelected: controller.setIndex,
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: Text('Trang chủ'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.menu_book_outlined),
                    selectedIcon: Icon(Icons.menu_book_rounded),
                    label: Text('Học tập'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.sports_esports_outlined),
                    selectedIcon: Icon(Icons.sports_esports_rounded),
                    label: Text('Trò chơi'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.bar_chart_outlined),
                    selectedIcon: Icon(Icons.bar_chart_rounded),
                    label: Text('Tiến độ'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.person_outline_rounded),
                    selectedIcon: Icon(Icons.person_rounded),
                    label: Text('Cá nhân'),
                  ),
                ],
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(child: body),
            ],
          ),
        ),
        desktop: Scaffold(
          body: Row(
            children: [
              NavigationRail(
                extended: true,
                selectedIndex: index,
                onDestinationSelected: controller.setIndex,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: Text('Trang chủ'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.menu_book_outlined),
                    selectedIcon: Icon(Icons.menu_book_rounded),
                    label: Text('Học tập'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.sports_esports_outlined),
                    selectedIcon: Icon(Icons.sports_esports_rounded),
                    label: Text('Trò chơi'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.bar_chart_outlined),
                    selectedIcon: Icon(Icons.bar_chart_rounded),
                    label: Text('Tiến độ'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.person_outline_rounded),
                    selectedIcon: Icon(Icons.person_rounded),
                    label: Text('Cá nhân'),
                  ),
                ],
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(child: body),
            ],
          ),
        ),
      );
    });
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
            ),
          ),
        ),
      );
}
