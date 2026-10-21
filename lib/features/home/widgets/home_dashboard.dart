import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../model/home_journey.dart';
import 'home_decorations.dart';
import 'home_green_button.dart';
import 'home_learning_sections.dart';
import 'home_streak_badge.dart';
import 'tab_header.dart';

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
                        if (errorMessage != null && errorMessage!.isNotEmpty)
                          _staleNotice(),
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
                        // Chừa chỗ cho thanh điều hướng nổi + inset đáy,
                        // giống các tab khác.
                        SizedBox(
                            height: 122.w +
                                MediaQuery.viewPaddingOf(context).bottom),
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
            // Cùng cỡ 44 với biểu tượng ở header các tab (TabHeader).
            Container(
              width: 44.w,
              height: 44.w,
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
            // Cùng kiểu chữ và cách căn với header các tab (TabHeader):
            // cụm hai dòng căn giữa theo chiều dọc với ô panda 44.
            Positioned(
                left: 54.w,
                right: 108.w,
                top: 0,
                height: 44.w,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Xin chào! 👋',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TabHeader.titleStyle()),
                    SizedBox(height: TabHeader.titleGap),
                    Text('Hôm nay cùng học tiếng Trung nào!',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TabHeader.subtitleStyle()),
                  ],
                )),
            Positioned(
                right: 0,
                top: 0,
                child: HomeStreakBadge(streak: streak, onTap: onProgress)),
          ]),
        ),
      );

  Widget _hero(
      double width, double sceneTop, double sceneHeight, double headerHeight) {
    final nextAction = journey?.nextAction;
    final hasJourney = journey != null;
    final eyebrow = nextAction?.type.name == 'fightBoss'
        ? 'CỔNG BOSS ĐÃ MỞ'
        : hasJourney
            ? 'NHIỆM VỤ TIẾP THEO'
            : 'BÀI HỌC HÔM NAY';
    final heroTitle = nextAction?.title.trim().isNotEmpty == true
        ? nextAction!.title.trim()
        : (hasJourney ? journey!.missionTitle : 'Khởi hành\ncùng Panda');
    final description = nextAction?.description.trim().isNotEmpty == true
        ? nextAction!.description.trim()
        : (hasJourney
            ? '${journey!.chapterTitle} • Ải ${journey!.missionNumber}/${journey!.totalMissions}'
            : 'Học từ vựng, luyện nghe và mở khóa thế giới tiếng Trung đầy thú vị!');
    final ctaLabel = _sentenceCase(nextAction?.label.trim().isNotEmpty == true
        ? nextAction!.label.trim()
        : (hasJourney ? 'Tiếp tục học' : 'Bắt đầu học'));
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
                child: Text(eyebrow,
                    maxLines: 1,
                    style: TextStyle(
                        color: const Color(0xFF57300A),
                        fontSize: 11.5.sp,
                        letterSpacing: .4,
                        fontWeight: FontWeight.w900)))),
        // Tiêu đề và mô tả nối liền trong khung giấy; chỉ thu nhỏ khi nội
        // dung dài hơn khung.
        Positioned.fromRect(
            rect: artworkRect(const Rect.fromLTRB(.095, .405, .438, .755)),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width * .343,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(heroTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: const Color(0xFF342E10),
                              fontSize: 21.sp,
                              height: 1.1,
                              letterSpacing: -.5.w,
                              fontWeight: FontWeight.w900)),
                      if (hasJourney)
                        Text('cùng Panda',
                            style: TextStyle(
                                color: const Color(0xFF375B1C),
                                fontSize: 16.sp,
                                height: 1.2,
                                fontWeight: FontWeight.w900)),
                      SizedBox(height: 8.w),
                      Text(description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: const Color(0xFF5D5C54),
                              fontSize: 12.sp,
                              height: 1.4,
                              fontWeight: FontWeight.w700)),
                    ]),
              ),
            )),
        Positioned(
            left: width * .09,
            top: sceneY(.770),
            width: width * .348,
            child: HomeGreenButton(
                label: ctaLabel, onTap: onStartLearning, playIcon: true)),
      ]),
    );
  }

  /// "ÔN NGAY" → "Ôn ngay": nhãn nút viết thường như các nút ở màn Home.
  static String _sentenceCase(String label) {
    if (label != label.toUpperCase()) return label;
    final lower = label.toLowerCase();
    return lower.isEmpty ? lower : lower[0].toUpperCase() + lower.substring(1);
  }

  Widget _staleNotice() => Container(
        margin: EdgeInsets.symmetric(horizontal: 22.w, vertical: 4.w),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.w),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E6),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: const Color(0xFFFFE0A3), width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 14.sp, color: const Color(0xFF946200)),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                '${errorMessage ?? 'Tiến độ chưa thể cập nhật đầy đủ'} • Dữ liệu ngoại tuyến',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: const Color(0xFF7A5200),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (onRetry != null)
              GestureDetector(
                onTap: onRetry,
                child: Text(
                  'Thử lại',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: const Color(0xFF573B00),
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),
      );
}
