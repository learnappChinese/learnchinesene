import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/game_visual_tokens.dart';
import '../../../core/widgets/panda_companion.dart';
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
            radius: 20.r,
            border: BorderSide(
              color: GameVisualTokens.gold.withValues(alpha: .5),
              width: 1.5.w,
            ),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFFDF5),
                    Color(0xFFF7F4E9),
                    Color(0xFFEFF5EA),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: const HomeLandscapeAccent(color: Color(0xFF4AB56A)),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8.w, vertical: 3.w),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      GameVisualTokens.gold,
                                      Color(0xFFD49A00)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: GameVisualTokens.gold
                                          .withValues(alpha: .3),
                                      blurRadius: 4.r,
                                      offset: Offset(0, 1.w),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'CHƯƠNG 1 • KHỞI HÀNH',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: GameVisualTokens.gold, size: 14),
                                  SizedBox(width: 2.w),
                                  Text(
                                    'Thành thục: 65%',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w700,
                                      color: GameVisualTokens.templeWood,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 6.w),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const _LessonBook(),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Từ vựng cơ bản',
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: homeInk,
                                      fontSize: 15.sp,
                                      height: 1.1,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(height: 2.w),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Nhiệm vụ: ',
                                          style: TextStyle(
                                            color: const Color(0xFF65655F),
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '🎧 Nghe và chọn',
                                          style: TextStyle(
                                            color: GameVisualTokens.jadeDark,
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 6.w),
                                  Row(
                                    children: [
                                      Expanded(child: _progress(4 / 7)),
                                      SizedBox(width: 8.w),
                                      Text(
                                        '4/7 nhiệm vụ',
                                        style: TextStyle(
                                          fontSize: 9.5.sp,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF5D6559),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 6.w),
                            PandaCompanion(
                              mood: PandaMood.happy,
                              size: 52.w,
                            ),
                          ],
                        ),
                        SizedBox(height: 8.w),
                        SizedBox(
                          width: double.infinity,
                          child: HomeGreenButton(
                            label: 'Tiếp tục',
                            onTap: onStartLearning,
                            playIcon: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: -3.w,
            top: -4.w,
            child: HomeLeaves(size: 38.w, rotation: .35),
          ),
        ],
      );

  Widget _challenge() => _SurfaceCard(
        onTap: onChallenge,
        radius: 18.r,
        border: BorderSide(
          color: GameVisualTokens.gold.withValues(alpha: .4),
          width: 1.2.w,
        ),
        child: SizedBox(
          height: 64.w,
          child: Stack(children: [
            Positioned.fill(
                child: const HomeLandscapeAccent(color: Color(0xFF70B399))),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.w),
              child: Row(children: [
                Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFF7E6), Color(0xFFFFE8B2)],
                        ),
                        borderRadius: BorderRadius.circular(15.r),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1F855B1B),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ]),
                    child: Center(
                        child:
                            HomeLearningIcon(label: 'Thử thách', size: 39.w))),
                SizedBox(width: 10.w),
                Expanded(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Hoàn thành 10 câu hỏi',
                              maxLines: 1,
                              style: TextStyle(
                                  color: homeInk,
                                  fontSize: 13.sp,
                                  height: 1.05,
                                  fontWeight: FontWeight.w900)),
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 5.w, vertical: 1.w),
                            decoration: BoxDecoration(
                              color:
                                  GameVisualTokens.crimson.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              '+50 XP',
                              style: TextStyle(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w800,
                                color: GameVisualTokens.crimsonDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 7.w),
                    Row(children: [
                      Expanded(child: _progress(.6)),
                      SizedBox(width: 7.w),
                      Text('6/10',
                          style: TextStyle(
                              fontSize: 9.sp,
                              height: 1,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF7B807A))),
                    ]),
                  ],
                )),
                SizedBox(width: 10.w),
                const Text('🎁', style: TextStyle(fontSize: 34)),
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
