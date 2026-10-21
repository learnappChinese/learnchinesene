import 'package:flutter/material.dart';

/// Màu khối giữ chỗ và vệt sáng quét qua, hợp với nền kem của app.
const _kShimmerBase = Color(0xFFEDE6DA);
const _kShimmerHighlight = Color(0xFFFAF6EF);

/// Vùng shimmer: mọi [ShimmerBox] bên trong dùng chung một vệt sáng quét
/// ngang qua cả vùng, nên các khối sáng lên đồng bộ như một mặt phẳng.
///
/// Chỉ [ShimmerBox] được phủ vệt sáng; thẻ, viền và nền xung quanh giữ nguyên
/// màu thật, để khung đang tải trông giống hệt giao diện sắp hiện ra.
/// Khi người dùng tắt hiệu ứng chuyển động, khối đứng yên.
class AppShimmer extends StatefulWidget {
  const AppShimmer({super.key, required this.child});

  final Widget child;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Đang tải',
      liveRegion: true,
      child: ExcludeSemantics(
        child: _ShimmerScope(
          animation: _controller,
          area: this,
          child: widget.child,
        ),
      ),
    );
  }
}

class _ShimmerScope extends InheritedWidget {
  const _ShimmerScope({
    required this.animation,
    required this.area,
    required super.child,
  });

  final Animation<double> animation;
  final State<AppShimmer> area;

  static _ShimmerScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShimmerScope>();

  @override
  bool updateShouldNotify(_ShimmerScope oldWidget) =>
      animation != oldWidget.animation;
}

/// Khối giữ chỗ bo góc. Trong [AppShimmer] khối có vệt sáng chạy qua.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({super.key, this.width, this.height = 14, this.radius = 8});

  /// Khối tròn đường kính [size].
  const ShimmerBox.circle({super.key, required double size})
    : width = size,
      height = size,
      radius = 999;

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _kShimmerBase,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    final scope = _ShimmerScope.of(context);
    if (scope == null) return box;

    return AnimatedBuilder(
      animation: scope.animation,
      child: box,
      builder: (context, child) {
        final area = scope.area.context.findRenderObject() as RenderBox?;
        final self = context.findRenderObject() as RenderBox?;
        if (area == null ||
            self == null ||
            !area.hasSize ||
            !self.hasSize ||
            !self.attached) {
          return child!;
        }
        // Vị trí khối trong vùng shimmer: gradient trải theo cả vùng nên các
        // khối ở các hàng/cột khác nhau sáng lên nối tiếp nhau.
        final offset = area.globalToLocal(self.localToGlobal(Offset.zero));
        final areaSize = area.size;
        final t = scope.animation.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (_) =>
              LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: const [
                  _kShimmerBase,
                  _kShimmerHighlight,
                  _kShimmerBase,
                ],
                stops: const [.35, .5, .65],
                transform: _SlideGradient(t),
              ).createShader(
                Rect.fromLTWH(
                  -offset.dx,
                  -offset.dy,
                  areaSize.width,
                  areaSize.height,
                ),
              ),
          child: child,
        );
      },
    );
  }
}

/// Dịch gradient từ ngoài mép trái sang ngoài mép phải theo [percent].
class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.percent);

  final double percent;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (percent * 2 - 1), 0, 0);
}

/// Dòng chữ giữ chỗ chiếm [widthFactor] bề ngang chỗ đặt.
class ShimmerLine extends StatelessWidget {
  const ShimmerLine({
    super.key,
    this.widthFactor = 1,
    this.height = 12,
    this.alignment = Alignment.centerLeft,
  });

  final double widthFactor;
  final double height;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    widthFactor: widthFactor,
    alignment: alignment,
    child: ShimmerBox(height: height, radius: height / 2),
  );
}

/// Kiểu khung thẻ giữ chỗ, khớp với các kiểu thẻ thật trong app.
enum SkeletonCardStyle {
  /// Thẻ trắng viền kem (thẻ danh sách, ô thống kê).
  plain,

  /// Thẻ kem gradient viền trắng dày (thẻ câu hỏi, hero, banner).
  cream,
}

/// Khung thẻ thật (nền, viền, bo góc) chứa các [ShimmerBox].
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    super.key,
    required this.child,
    this.style = SkeletonCardStyle.plain,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18,
    this.height,
  });

  final Widget child;
  final SkeletonCardStyle style;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final cream = style == SkeletonCardStyle.cream;
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: cream ? null : Colors.white,
        gradient: cream
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFDF6), Color(0xFFFFF4DE)],
              )
            : null,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: cream ? Colors.white : const Color(0xFFE8E1D6),
          width: cream ? 4 : 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14635D3B),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Khung giữ chỗ cho các thành phần dùng chung. Kích thước, bo góc và khoảng
// cách lấy theo widget thật tương ứng để khi tải xong, nội dung hiện ra đúng
// chỗ khung vừa chiếm.
// ---------------------------------------------------------------------------

/// Pill giữ chỗ (nhãn, chip, tag).
class SkeletonPill extends StatelessWidget {
  const SkeletonPill({super.key, this.width = 80, this.height = 22});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) =>
      ShimmerBox(width: width, height: height, radius: 99);
}

/// Khung của `AdventureQuestBanner` (thẻ hero kem có panda góc phải).
class SkeletonQuestBanner extends StatelessWidget {
  const SkeletonQuestBanner({super.key, this.showProgress = true});

  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 126),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFDF6), Color(0xFFFFF1D6)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24635D3B),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            right: 6,
            bottom: 6,
            child: ShimmerBox.circle(size: 76),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 92, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    SkeletonPill(width: 92),
                    SizedBox(width: 7),
                    SkeletonPill(width: 70),
                  ],
                ),
                const SizedBox(height: 12),
                const ShimmerLine(widthFactor: .8, height: 19),
                const SizedBox(height: 9),
                const ShimmerLine(height: 11),
                const SizedBox(height: 6),
                const ShimmerLine(widthFactor: .6, height: 11),
                if (showProgress) ...[
                  const SizedBox(height: 14),
                  const Row(
                    children: [
                      Expanded(child: ShimmerBox(height: 9, radius: 99)),
                      SizedBox(width: 9),
                      ShimmerBox(width: 44, height: 11),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Khung tiêu đề section kiểu Home: mặt panda tròn + chữ tiêu đề
/// (+ link "Xem tất cả" bên phải nếu [showTrailing]).
class SkeletonSectionTitle extends StatelessWidget {
  const SkeletonSectionTitle({
    super.key,
    this.width = 160,
    this.showTrailing = false,
  });

  final double width;
  final bool showTrailing;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 34,
    child: Row(
      children: [
        const ShimmerBox.circle(size: 26),
        const SizedBox(width: 10),
        ShimmerBox(width: width, height: 18),
        const Spacer(),
        if (showTrailing) const ShimmerBox(width: 78, height: 13),
      ],
    ),
  );
}

/// Khung một chặng lộ trình (`LearningTrailEntry`): node tròn trên rail bên
/// trái nối bằng đường dọc, thẻ nội dung bên phải.
class SkeletonTrailEntry extends StatelessWidget {
  const SkeletonTrailEntry({
    super.key,
    required this.isFirst,
    required this.isLast,
    required this.child,
    this.nodeSize = 56,
    this.nodeTop = 10,
  });

  final bool isFirst;
  final bool isLast;
  final Widget child;
  final double nodeSize;
  final double nodeTop;

  static const double _railWidth = 64;

  @override
  Widget build(BuildContext context) {
    final nodeCenter = nodeTop + nodeSize / 2;
    return Stack(
      children: [
        if (!(isFirst && isLast))
          Positioned(
            left: _railWidth / 2 - 2,
            top: isFirst ? nodeCenter : 0,
            bottom: isLast ? null : 0,
            height: isLast ? nodeCenter : null,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE8E1D6),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _railWidth,
                child: Padding(
                  padding: EdgeInsets.only(top: nodeTop),
                  child: Center(child: ShimmerBox.circle(size: nodeSize)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(child: child),
            ],
          ),
        ),
      ],
    );
  }
}

/// Khung thẻ chặng (`LearningTrailCard`): tag, tiêu đề, mô tả, dòng thông tin
/// và pill "Vào học" nếu [showAction].
class SkeletonTrailCard extends StatelessWidget {
  const SkeletonTrailCard({super.key, this.showAction = false});

  final bool showAction;

  @override
  Widget build(BuildContext context) => SkeletonCard(
    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            SkeletonPill(width: 46, height: 18),
            SizedBox(width: 6),
            SkeletonPill(width: 64, height: 18),
          ],
        ),
        const SizedBox(height: 9),
        const ShimmerLine(widthFactor: .7, height: 15),
        const SizedBox(height: 7),
        const ShimmerLine(widthFactor: .9, height: 11),
        const SizedBox(height: 10),
        Row(
          children: [
            const ShimmerBox(width: 58, height: 11),
            const SizedBox(width: 10),
            const ShimmerBox(width: 52, height: 11),
            const Spacer(),
            if (showAction) const SkeletonPill(width: 84, height: 30),
          ],
        ),
      ],
    ),
  );
}

/// Khung đầu thẻ câu hỏi (`LearningQuestionCard`): pill màn chơi, câu hướng
/// dẫn và panda góc phải.
class SkeletonQuestionHeader extends StatelessWidget {
  const SkeletonQuestionHeader({super.key, this.pandaSize = 72});

  final double pandaSize;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonPill(width: 96, height: 24),
            SizedBox(height: 10),
            ShimmerLine(widthFactor: .85, height: 19),
          ],
        ),
      ),
      const SizedBox(width: 8),
      ShimmerBox.circle(size: pandaSize),
    ],
  );
}

/// Khung `MissionIntro`: thẻ kem giữa màn với pill, tiêu đề, panda, phần
/// thưởng và nút bắt đầu.
class SkeletonMissionIntro extends StatelessWidget {
  const SkeletonMissionIntro({super.key});

  @override
  Widget build(BuildContext context) => AppShimmer(
    child: Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: const SkeletonCard(
            style: SkeletonCardStyle.cream,
            radius: 28,
            padding: EdgeInsets.all(22),
            child: Column(
              children: [
                SkeletonPill(width: 120, height: 26),
                SizedBox(height: 14),
                ShimmerLine(
                  widthFactor: .7,
                  height: 24,
                  alignment: Alignment.center,
                ),
                SizedBox(height: 10),
                ShimmerLine(
                  widthFactor: .85,
                  height: 13,
                  alignment: Alignment.center,
                ),
                SizedBox(height: 18),
                ShimmerBox.circle(size: 118),
                SizedBox(height: 16),
                SkeletonPill(width: 210, height: 34),
                SizedBox(height: 20),
                ShimmerBox(height: 56, radius: 18),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Khung màn câu hỏi trắc nghiệm (Quiz, HSK Quiz): thanh tiến độ, nhãn dạng
/// câu, đề bài và 4 ô đáp án.
class SkeletonQuiz extends StatelessWidget {
  const SkeletonQuiz({super.key, this.horizontalPadding = 16});

  final double horizontalPadding;

  @override
  Widget build(BuildContext context) => AppShimmer(
    child: ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(horizontalPadding, 4, horizontalPadding, 20),
      children: [
        const Row(
          children: [
            Expanded(child: ShimmerBox(height: 8, radius: 8)),
            SizedBox(width: 12),
            ShimmerBox(width: 36, height: 14),
          ],
        ),
        const SizedBox(height: 28),
        const ShimmerBox(width: 96, height: 12),
        const SizedBox(height: 12),
        const ShimmerLine(widthFactor: .85, height: 26),
        const SizedBox(height: 8),
        const ShimmerLine(widthFactor: .5, height: 26),
        const SizedBox(height: 26),
        for (var i = 0; i < 4; i++) ...[
          const SkeletonCard(
            height: 62,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ShimmerBox.circle(size: 26),
                SizedBox(width: 12),
                Expanded(child: ShimmerLine(widthFactor: .55, height: 16)),
              ],
            ),
          ),
          const SizedBox(height: 11),
        ],
      ],
    ),
  );
}

/// Khung chung cho các màn ít dùng chưa có khung riêng.
///
/// - [SkeletonPage.list]: thẻ đầu trang + danh sách.
/// - [SkeletonPage.card]: một thẻ lớn giữa màn.
/// - [SkeletonPage.path]: thẻ đầu trang + node tròn uốn lượn.
class SkeletonPage extends StatelessWidget {
  const SkeletonPage.list({super.key, this.itemCount = 8, this.showHero = true})
    : _kind = _SkeletonKind.list;

  const SkeletonPage.card({super.key})
    : _kind = _SkeletonKind.card,
      itemCount = 0,
      showHero = false;

  const SkeletonPage.path({super.key, this.itemCount = 10})
    : _kind = _SkeletonKind.path,
      showHero = true;

  final _SkeletonKind _kind;
  final int itemCount;
  final bool showHero;

  @override
  Widget build(BuildContext context) {
    if (_kind == _SkeletonKind.card) return const SkeletonMissionIntro();
    return AppShimmer(
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (showHero) ...[
            const SkeletonQuestBanner(),
            const SizedBox(height: 20),
          ],
          if (_kind == _SkeletonKind.list)
            for (var i = 0; i < itemCount; i++) ...[
              const SkeletonListTile(),
              const SizedBox(height: 12),
            ]
          else
            for (var i = 0; i < itemCount; i++) ...[
              Align(
                alignment: Alignment(const [0.0, .45, .2, -.4, -.15][i % 5], 0),
                child: const ShimmerBox.circle(size: 72),
              ),
              const SizedBox(height: 40),
            ],
        ],
      ),
    );
  }
}

enum _SkeletonKind { list, card, path }

/// Dòng danh sách chung: ô vuông trái + hai dòng chữ (+ pill phải).
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({
    super.key,
    this.leadingSize = 46,
    this.leadingCircle = false,
    this.trailingPillWidth,
    this.radius = 18,
  });

  final double leadingSize;
  final bool leadingCircle;
  final double? trailingPillWidth;
  final double radius;

  @override
  Widget build(BuildContext context) => SkeletonCard(
    radius: radius,
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        leadingCircle
            ? ShimmerBox.circle(size: leadingSize)
            : ShimmerBox(width: leadingSize, height: leadingSize, radius: 15),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerLine(widthFactor: .65, height: 15),
              SizedBox(height: 8),
              ShimmerLine(widthFactor: .4, height: 11),
            ],
          ),
        ),
        if (trailingPillWidth != null) ...[
          const SizedBox(width: 8),
          SkeletonPill(width: trailingPillWidth!, height: 26),
        ],
      ],
    ),
  );
}
