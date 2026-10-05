import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Local, scalable illustrations keep the quick actions consistent on iOS,
/// Android and web, where the appearance of emoji otherwise differs.
class HomeLearningIcon extends StatelessWidget {
  const HomeLearningIcon({super.key, required this.label, required this.size});
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox(
            width: size,
            height: size,
            child: switch (label) {
              'Từ vựng' => _cards(),
              'Ngữ pháp' =>
                CustomPaint(painter: const _LearningIconPainter('grammar')),
              'Luyện nghe' =>
                CustomPaint(painter: const _LearningIconPainter('listening')),
              'Thử thách' =>
                CustomPaint(painter: const _LearningIconPainter('challenge')),
              _ => CustomPaint(painter: const _LearningIconPainter('speaking')),
            }),
      );

  Widget _cards() => Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
              left: size * .08,
              top: size * .12,
              child: Transform.rotate(
                  angle: -.15,
                  child: _card('字', const Color(0xFFFF714D),
                      const Color(0xFFF43C21), Colors.white))),
          Positioned(
              right: size * .08,
              top: size * .20,
              child: Transform.rotate(
                  angle: .15,
                  child: _card('字', const Color(0xFFFFFEF5),
                      const Color(0xFFF0E7D6), const Color(0xFF29251F)))),
        ],
      );

  Widget _card(String text, Color light, Color dark, Color ink) => Container(
        width: size * .52,
        height: size * .65,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * .08),
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [light, dark]),
          border: Border.all(color: light, width: 1.5),
          boxShadow: [
            BoxShadow(
                color: const Color(0x30593216),
                blurRadius: size * .05,
                offset: Offset(1, size * .04))
          ],
        ),
        child: Center(
            child: Text(text,
                style: TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w900,
                    fontSize: size * .37,
                    height: 1))),
      );
}

class _LearningIconPainter extends CustomPainter {
  const _LearningIconPainter(this.kind);
  final String kind;

  Paint _gradient(Rect bounds, Color light, Color dark) => Paint()
    ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [light, dark]).createShader(bounds);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64, size.height / 64);
    switch (kind) {
      case 'challenge':
        const center = Offset(25, 38);
        for (final ring in <(double, Color)>[
          (20, const Color(0xFFDC2525)),
          (15.5, Colors.white),
          (11.5, const Color(0xFFDC2525)),
          (7, Colors.white),
          (3.5, const Color(0xFFDC2525)),
        ]) {
          canvas.drawCircle(center, ring.$1, Paint()..color = ring.$2);
        }
        canvas.drawLine(
            center,
            const Offset(54, 9),
            Paint()
              ..color = const Color(0xFF238F9B)
              ..strokeWidth = 4
              ..strokeCap = StrokeCap.round);
        final feathers = Path()
          ..moveTo(42, 21)
          ..lineTo(43, 10)
          ..lineTo(51, 5)
          ..lineTo(51, 16)
          ..lineTo(60, 16)
          ..lineTo(54, 23)
          ..close();
        canvas.drawPath(
            feathers,
            _gradient(const Rect.fromLTWH(42, 5, 18, 18),
                const Color(0xFF5BD0D1), const Color(0xFF218B98)));
        canvas.drawPath(
            Path()
              ..moveTo(23, 40)
              ..lineTo(26, 31)
              ..lineTo(32, 37)
              ..close(),
            Paint()..color = const Color(0xFF177C89));
      case 'grammar':
        _bubble(canvas, const Rect.fromLTWH(29, 28, 33, 27),
            const Color(0xFF88D5FF), const Color(0xFF419AF1));
        _bubble(canvas, const Rect.fromLTWH(4, 6, 45, 35),
            const Color(0xFF40BDFF), const Color(0xFF007BEF));
      case 'listening':
        final arch = Path()
          ..addArc(const Rect.fromLTWH(11, 5, 42, 49), math.pi, math.pi);
        canvas.drawPath(
            arch,
            Paint()
              ..color = const Color(0xFF178D37)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 9
              ..strokeCap = StrokeCap.round);
        canvas.drawPath(
            arch,
            _gradient(const Rect.fromLTWH(0, 0, 64, 48),
                const Color(0xFF67E483), const Color(0xFF239D43))
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6
              ..strokeCap = StrokeCap.round);
        for (final x in [6.0, 45.0]) {
          final pad = Rect.fromLTWH(x, 29, 13, 26);
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  pad.shift(const Offset(0, 2)), const Radius.circular(6)),
              Paint()
                ..color = const Color(0x352B8C39)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5));
          canvas.drawRRect(
              RRect.fromRectAndRadius(pad, const Radius.circular(6)),
              _gradient(pad, const Color(0xFF6DEB85), const Color(0xFF05992B)));
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromLTWH(x + 2, 32, 2.5, 17), const Radius.circular(2)),
              Paint()..color = const Color(0x70C4FFD0));
        }
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(17, 31, 5, 22), const Radius.circular(2)),
            Paint()..color = const Color(0xFF08792C));
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(42, 31, 5, 22), const Radius.circular(2)),
            Paint()..color = const Color(0xFF08792C));
      case 'speaking':
        final capsule = const Rect.fromLTWH(23, 4, 21, 34);
        canvas.drawRRect(
            RRect.fromRectAndRadius(capsule, const Radius.circular(12)),
            _gradient(
                capsule, const Color(0xFFFFD35D), const Color(0xFFEF8B08)));
        final grille = Paint()
          ..color = const Color(0xFFC97506)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        for (final y in [14.0, 21.0, 28.0]) {
          canvas.drawLine(Offset(25, y), Offset(31, y + 1), grille);
        }
        final stand = Paint()
          ..color = const Color(0xFFBA6100)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.5
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(
            Path()
              ..moveTo(16, 26)
              ..cubicTo(16, 53, 51, 53, 51, 26),
            stand);
        canvas.drawLine(const Offset(33.5, 47), const Offset(33.5, 58), stand);
        canvas.drawOval(
            const Rect.fromLTWH(20, 57, 28, 6),
            _gradient(const Rect.fromLTWH(20, 57, 28, 6),
                const Color(0xFFF4A727), const Color(0xFFA65500)));
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(26, 8, 3, 10), const Radius.circular(2)),
            Paint()..color = const Color(0x90FFEBA3));
    }
    canvas.restore();
  }

  void _bubble(Canvas canvas, Rect bounds, Color light, Color dark) {
    final tail = Path()
      ..moveTo(bounds.left + bounds.width * .2, bounds.bottom - 4)
      ..lineTo(bounds.left + bounds.width * .19, bounds.bottom + 8)
      ..lineTo(bounds.left + bounds.width * .48, bounds.bottom - 3)
      ..close();
    final paint = _gradient(bounds, light, dark);
    canvas.drawPath(tail, paint);
    canvas.drawOval(
        bounds.shift(const Offset(0, 2)),
        Paint()
          ..color = const Color(0x283689B8)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5));
    canvas.drawOval(bounds, paint);
    canvas.drawArc(
        bounds.deflate(2),
        math.pi * 1.1,
        math.pi * .6,
        false,
        Paint()
          ..color = const Color(0x85BCEEFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round);
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
          Offset(
              bounds.left + bounds.width * (.29 + i * .21), bounds.center.dy),
          bounds.width * .055,
          Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_LearningIconPainter oldDelegate) =>
      kind != oldDelegate.kind;
}
