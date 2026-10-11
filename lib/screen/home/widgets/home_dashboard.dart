import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../model/home_journey.dart';
import 'home_decorations.dart';
import 'home_green_button.dart';
import 'home_learning_sections.dart';
import 'home_streak_badge.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({
    super.key,
    required this.onStartLearning,
    required this.onGrammar,
    required this.onListening,
    required this.onSpeaking,
    required this.onChallenge,
    required this.onProgress,
    this.onReview,
    this.onViewAllQuickActions,
    this.onRefresh,
    this.onRetry,
    this.journey,
    this.isLoading = false,
    this.errorMessage,
    this.streak = 7,
    this.lessons = 12,
    this.xp = 156,
  });

  final VoidCallback onStartLearning;
  final VoidCallback onGrammar;
  final VoidCallback onListening;
  final VoidCallback onSpeaking;
  final VoidCallback onChallenge;
  final VoidCallback onProgress;
  final VoidCallback? onReview;
  final VoidCallback? onViewAllQuickActions;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onRetry;
  final HomeJourney? journey;
  final bool isLoading;
  final String? errorMessage;
  final int streak;
  final int lessons;
  final int xp;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: homePageBackground,
        child: Align(
          alignment: Alignment.topCenter,
          child: LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth;
            final topInset = MediaQuery.paddingOf(context).top;
            // One continuous scene covers the status bar and the dashboard.
            // Expand it for taller insets, then align the parchment overlays
            // with the same vertical scale instead of painting a second crop.
            final crop = 24.w;
            final sceneTop = (topInset - crop).clamp(-crop, 0.0);
            final sceneHeight = width * .862 + (topInset - crop - sceneTop);
            final headerHeight = 64.w + topInset;
            Widget page = SingleChildScrollView(
              key: const PageStorageKey('home-dashboard'),
              physics: const ClampingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              child: ConstrainedBox(
                // Fill short pages with the ivory backdrop below the content.
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Stack(
                  children: [
                    Positioned(
                      top: sceneTop,
                      left: 0,
                      right: 0,
                      child: ExcludeSemantics(
                        child: Image.asset(
                          homeSceneAsset,
                          width: width,
                          height: sceneHeight,
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: topInset),
                          child: _header(),
                        ),
                        _hero(width, sceneTop, sceneHeight, headerHeight),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 22.w),
                          child: HomeLearningSections(
                            streak: streak,
                            lessons: lessons,
                            xp: xp,
                            journey: journey,
                            onStartLearning: onStartLearning,
                            onGrammar: onGrammar,
                            onListening: onListening,
                            onSpeaking: onSpeaking,
                            onChallenge: onChallenge,
                            onViewAllQuickActions:
                                onViewAllQuickActions ?? onStartLearning,
                          ),
                        ),
                        SizedBox(height: 118.w),
                      ],
                    ),
                  ],
                ),
              ),
            );
            if (onRefresh != null) {
              page = RefreshIndicator(
                color: homeGreen,
                onRefresh: onRefresh!,
                child: page,
              );
            }
            return page;
          }),
        ),
      ),
    );
  }

  Widget _header() => SizedBox(
        width: double.infinity,
        height: 64.w,
        child: Padding(
          padding: EdgeInsets.fromLTRB(18.w, 12.w, 15.w, 0),
          child: Stack(children: [
            Container(
              width: 41.w,
              height: 41.w,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFF3C7),
                  border:
                      Border.all(color: const Color(0xFFFFDB87), width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x24956A23),
                        blurRadius: 7,
                        offset: Offset(0, 3))
                  ]),
              child: ClipOval(
                  child: Padding(
                      padding: EdgeInsets.all(2.w),
                      child: Image.asset(homePandaPeekAsset,
                          fit: BoxFit.contain))),
            ),
            Positioned(
                left: 49.w,
                top: 2.w,
                child: Text('你好! 👋',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w900))),
            Positioned(
                left: 49.w,
                top: 27.w,
                child: Text('Hôm nay cùng học tiếng Trung nào!',
                    style: TextStyle(
                        color: const Color(0xFF4F514A),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600))),
            Positioned(
                right: 0,
                top: 0,
                child: HomeStreakBadge(streak: streak, onTap: onProgress)),
          ]),
        ),
      );

  Widget _hero(
      double width, double sceneTop, double sceneHeight, double headerHeight) {
    // Bounds measured on the artwork, independent of header and safe insets.
    double sceneY(double fraction) =>
        sceneTop + sceneHeight * fraction - headerHeight;
    Rect artworkRect(Rect bounds) => Rect.fromLTWH(
          width * bounds.left,
          sceneY(bounds.top),
          width * bounds.width,
          sceneHeight * bounds.height,
        );
    return SizedBox(
      height: sceneY(.885),
      child: Stack(children: [
        Positioned.fromRect(
            rect: artworkRect(const Rect.fromLTRB(.128, .344, .373, .380)),
            child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('BÀI HỌC HÔM NAY',
                    maxLines: 1,
                    style: TextStyle(
                        color: const Color(0xFF57300A),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w900)))),
        Positioned.fromRect(
            rect: artworkRect(const Rect.fromLTRB(.095, .408, .438, .604)),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topLeft,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mỗi ngày\nmạnh hơn',
                        style: TextStyle(
                            color: const Color(0xFF342E10),
                            fontSize: 24.sp,
                            height: 1.03,
                            letterSpacing: -.6.w,
                            fontWeight: FontWeight.w900)),
                    Text('một chút',
                        style: TextStyle(
                            color: const Color(0xFF375B1C),
                            fontSize: 24.sp,
                            height: 1.08,
                            fontWeight: FontWeight.w900)),
                  ]),
            )),
        Positioned.fromRect(
            rect: artworkRect(const Rect.fromLTRB(.095, .625, .438, .748)),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width * .343,
                child: Text(
                    'Học từ vựng, luyện nghe và mở khóa thế giới tiếng Trung đầy thú vị!',
                    style: TextStyle(
                        color: const Color(0xFF5D5C54),
                        fontSize: 9.8.sp,
                        height: 1.5,
                        fontWeight: FontWeight.w600)),
              ),
            )),
        Positioned(
            left: width * .09,
            top: sceneY(.770),
            width: width * .348,
            child: HomeGreenButton(
                label: 'Bắt đầu học', onTap: onStartLearning, playIcon: true)),
      ]),
    );
  }
}
