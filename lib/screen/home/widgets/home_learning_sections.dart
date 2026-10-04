import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'home_decorations.dart';
import 'home_green_button.dart';
import 'home_landscape_accent.dart';
import 'home_learning_icon.dart';

class HomeLearningSections extends StatelessWidget {
  const HomeLearningSections({
    super.key,
    required this.streak,
    required this.lessons,
    required this.xp,
    required this.onStartLearning,
    required this.onGrammar,
    required this.onListening,
    required this.onSpeaking,
    required this.onChallenge,
    required this.onViewAllQuickActions,
  });

  final int streak, lessons, xp;
  final VoidCallback onStartLearning, onGrammar, onListening, onSpeaking;
  final VoidCallback onChallenge, onViewAllQuickActions;

  @override
  Widget build(BuildContext context) => Column(
        key: const ValueKey('home-learning-sections'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
                child: _Metric(
              assetPath: 'assets/images/backgrounds/home_metric_streak.png',
              value: '$streak',
              label: 'Ngày học',
              color: const Color(0xFFFF4D25),
            )),
            SizedBox(width: 8.w),
            Expanded(
                child: _Metric(
              assetPath: 'assets/images/backgrounds/home_metric_lessons.png',
              value: '$lessons',
              label: 'Bài học',
              color: const Color(0xFF0F9B30),
            )),
            SizedBox(width: 8.w),
            Expanded(
                child: _Metric(
              assetPath: 'assets/images/backgrounds/home_metric_xp.png',
              value: '$xp',
              label: 'Điểm XP',
              color: const Color(0xFFFF9900),
            )),
          ]),
          SizedBox(height: 13.w),
          _SectionTitle(title: 'Bài học hôm nay', onViewAll: onStartLearning),
          SizedBox(height: 8.w),
          _lesson(),
          SizedBox(height: 13.w),
          _SectionTitle(title: 'Học nhanh', onViewAll: onViewAllQuickActions),
          SizedBox(height: 8.w),
          Row(children: [
            for (final action in <(String, Color, VoidCallback)>[
              ('Từ vựng', const Color(0xFFFFD5CD), onStartLearning),
              ('Ngữ pháp', const Color(0xFFBEE5FF), onGrammar),
              ('Luyện nghe', const Color(0xFFC8F5DB), onListening),
              ('Luyện nói', const Color(0xFFFFE9AC), onSpeaking),
            ]) ...[
              if (action.$1 != 'Từ vựng') SizedBox(width: 7.w),
              Expanded(
                  child: _QuickAction(
                label: action.$1,
                color: action.$2,
                onTap: action.$3,
              )),
            ],
          ]),
          SizedBox(height: 13.w),
          _SectionTitle(title: 'Thử thách hôm nay', onViewAll: onChallenge),
          SizedBox(height: 8.w),
          _challenge(),
        ],
      );

  Widget _lesson() => Stack(
        clipBehavior: Clip.none,
        children: [
          _SurfaceCard(
            onTap: onStartLearning,
            child: SizedBox(
              height: 76.w,
              child: Stack(children: [
                Positioned.fill(
                    child: const HomeLandscapeAccent(color: Color(0xFF4AB56A))),
                Padding(
                  padding: EdgeInsets.all(8.w),
                  child: Row(children: [
                    const _LessonBook(),
                    SizedBox(width: 9.w),
                    Expanded(
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Từ vựng cơ bản',
                            maxLines: 1,
                            style: TextStyle(
                                color: homeInk,
                                fontSize: 14.sp,
                                height: 1.05,
                                fontWeight: FontWeight.w900)),
                        SizedBox(height: 3.w),
                        Text('Chủ đề: Gia đình',
                            maxLines: 1,
                            style: TextStyle(
                                color: const Color(0xFF65655F),
                                fontSize: 10.sp,
                                height: 1.05)),
                        SizedBox(height: 7.w),
                        Row(children: [
                          Expanded(child: _progress(3 / 8)),
                          SizedBox(width: 6.w),
                          Text('3/8',
                              style: TextStyle(
                                  fontSize: 9.sp,
                                  color: const Color(0xFF747871),
                                  height: 1)),
                        ]),
                      ],
                    )),
                    SizedBox(width: 12.w),
                    SizedBox(
                      width: 88.w,
                      child: HomeGreenButton(
                        label: 'Tiếp tục',
                        onTap: onStartLearning,
                        chevronIcon: false,
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
          Positioned(
              right: -3.w,
              bottom: -4.w,
              child: HomeLeaves(size: 38.w, rotation: .35)),
        ],
      );

  Widget _challenge() => _SurfaceCard(
        onTap: onChallenge,
        child: SizedBox(
          height: 60.w,
          child: Stack(children: [
            Positioned.fill(
                child: const HomeLandscapeAccent(color: Color(0xFF70B399))),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 7.w),
              child: Row(children: [
                Container(
                    width: 47.w,
                    height: 47.w,
                    decoration: BoxDecoration(
                        color: const Color(0xFFFFF7E6),
                        borderRadius: BorderRadius.circular(15.r)),
                    child: Center(
                        child:
                            HomeLearningIcon(label: 'Thử thách', size: 39.w))),
                SizedBox(width: 9.w),
                Expanded(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hoàn thành 10 câu hỏi',
                        maxLines: 1,
                        style: TextStyle(
                            color: homeInk,
                            fontSize: 13.sp,
                            height: 1.05,
                            fontWeight: FontWeight.w900)),
                    SizedBox(height: 8.w),
                    Row(children: [
                      Expanded(child: _progress(.6)),
                      SizedBox(width: 7.w),
                      Text('6/10',
                          style: TextStyle(
                              fontSize: 9.sp,
                              height: 1,
                              color: const Color(0xFF7B807A))),
                    ]),
                  ],
                )),
                SizedBox(width: 12.w),
                Text('🎁', style: TextStyle(fontSize: 38.sp)),
              ]),
            ),
          ]),
        ),
      );

  Widget _progress(double value) => LinearProgressIndicator(
        value: value,
        minHeight: 8.w,
        borderRadius: BorderRadius.circular(20.r),
        color: const Color(0xFF31B63A),
        backgroundColor: const Color(0xFFE4E9E9),
      );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.assetPath,
    required this.value,
    required this.label,
    required this.color,
  });
  final String assetPath, value, label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16.r);
    return Container(
      height: 72.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .16),
            blurRadius: 8.r,
            offset: Offset(0, 4.w),
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
            color: Color.lerp(Colors.white, color, .3)!, width: 1.5.w),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: LayoutBuilder(
            builder: (context, constraints) => Stack(
                  children: [
                    Positioned.fill(
                      child: ExcludeSemantics(
                        child: Image.asset(assetPath,
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.high),
                      ),
                    ),
                    Positioned(
                      left: constraints.maxWidth * .36,
                      right: 8.w,
                      top: 12.w,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(value,
                            style: TextStyle(
                                color: color,
                                fontSize: 24.sp,
                                height: 1.05,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                    Positioned(
                      left: 12.w,
                      right: 8.w,
                      bottom: 13.w,
                      child: Text(label,
                          maxLines: 1,
                          style: TextStyle(
                              color: homeInk,
                              fontSize: 11.sp,
                              height: 1.1,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                )),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.onViewAll});
  final String title;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(minHeight: 34.w),
        child: Row(children: [
          HomePandaFace(size: 25.w),
          SizedBox(width: 10.w),
          Expanded(
              child: Text(title,
                  style: TextStyle(
                      color: homeInk,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900))),
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                minimumSize: Size(82.w, 34.w),
                foregroundColor: const Color(0xFF2C7042),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: Row(children: [
              Text('Xem tất cả',
                  style:
                      TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800)),
              Icon(Icons.chevron_right_rounded, size: 17.w),
            ]),
          ),
        ]),
      );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(
      {required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _SurfaceCard(
        onTap: onTap,
        color: color,
        radius: 16.r,
        border:
            BorderSide(color: Color.lerp(color, homeInk, .16)!, width: 1.5.w),
        child: SizedBox(
          height: 80.w,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.w),
            child: Column(children: [
              Expanded(
                  child: Center(
                      child: HomeLearningIcon(label: label, size: 43.w))),
              SizedBox(height: 4.w),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label,
                    style: TextStyle(
                        fontSize: 11.sp,
                        color: homeInk,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ),
      );
}

class _LessonBook extends StatelessWidget {
  const _LessonBook();

  @override
  Widget build(BuildContext context) => Container(
        width: 63.w,
        height: 59.w,
        decoration: BoxDecoration(
            color: const Color(0xFFEAF6DE),
            borderRadius: BorderRadius.circular(13.r)),
        child: Center(
            child: Transform.rotate(
          angle: -.12,
          child: Container(
            width: 46.w,
            height: 53.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF36B83B), Color(0xFF008529)]),
              borderRadius: BorderRadius.circular(7.r),
              border: Border(
                  left: BorderSide(color: const Color(0xFF086D24), width: 6.w)),
              boxShadow: [
                BoxShadow(
                    color: const Color(0x35518B3C),
                    blurRadius: 3.r,
                    offset: Offset(2.w, 3.w))
              ],
            ),
            child: Center(
                child: Text('你',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 31.sp,
                        height: 1,
                        fontWeight: FontWeight.w900))),
          ),
        )),
      );
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard(
      {required this.child,
      required this.onTap,
      this.color = Colors.white,
      this.radius,
      this.border});
  final Widget child;
  final VoidCallback onTap;
  final Color color;
  final double? radius;
  final BorderSide? border;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius ?? 17.r);
    return Container(
      decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: [
        BoxShadow(
            color: const Color(0x24445C3E),
            blurRadius: 10.r,
            offset: Offset(0, 4.w))
      ]),
      child: Material(
          color: color,
          shape: RoundedRectangleBorder(
              borderRadius: borderRadius,
              side: border ??
                  BorderSide(color: const Color(0xFFC0D3BD), width: 1.5.w)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: onTap, child: child)),
    );
  }
}
