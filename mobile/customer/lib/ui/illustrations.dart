import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Original Gud Meal illustrations drawn in code (no image assets, no third-party artwork).
/// Each painter draws in a 100×100 design space scaled to the widget size.
abstract class _Illustration extends CustomPainter {
  const _Illustration();

  void draw(Canvas c);

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height) / 100;
    canvas.save();
    canvas.translate((size.width - 100 * s) / 2, (size.height - 100 * s) / 2);
    canvas.scale(s);
    draw(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Paint _fill(Color c) => Paint()..color = c;
Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round;

void _shadow(Canvas c, Offset center, double w, double h) =>
    c.drawOval(Rect.fromCenter(center: center, width: w, height: h), _fill(const Color(0x1F000000)));

/// A bowl of smoky jollof with a drumstick, dodo and a sprig of green.
class FoodIllustration extends _Illustration {
  const FoodIllustration();

  @override
  void draw(Canvas c) {
    _shadow(c, const Offset(50, 86), 66, 8);
    // steam
    final steam = _stroke(const Color(0xFFD9CFC4), 3);
    for (final x in [40.0, 56.0]) {
      final p = Path()..moveTo(x, 24);
      p.cubicTo(x - 6, 18, x + 6, 13, x, 6);
      c.drawPath(p, steam);
    }
    // rice dome
    final rice = Path()
      ..moveTo(16, 56)
      ..cubicTo(18, 30, 82, 30, 84, 56)
      ..close();
    c.drawPath(rice, _fill(const Color(0xFFE2622C)));
    final grain = _fill(const Color(0xFFF08A4B));
    final rnd = math.Random(7);
    for (var i = 0; i < 26; i++) {
      final x = 22 + rnd.nextDouble() * 56;
      final y = 40 + rnd.nextDouble() * 14;
      c.save();
      c.translate(x, y);
      c.rotate(rnd.nextDouble() * math.pi);
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-2.2, -0.9, 4.4, 1.8), const Radius.circular(1)), grain);
      c.restore();
    }
    // dodo (fried plantain) slices
    for (final (dx, dy, a) in [(28.0, 44.0, -0.4), (36.0, 40.0, 0.2), (24.0, 37.0, 0.6)]) {
      c.save();
      c.translate(dx, dy);
      c.rotate(a);
      final r = Rect.fromCenter(center: Offset.zero, width: 11, height: 7);
      c.drawOval(r, _fill(const Color(0xFFF5B942)));
      c.drawOval(r, _stroke(const Color(0xFFB8741C), 1.4));
      c.restore();
    }
    // drumstick
    c.save();
    c.translate(63, 40);
    c.rotate(-0.55);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-12, -7, 22, 14), const Radius.circular(7)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFFB4561F), Color(0xFF7A3512)]).createShader(const Rect.fromLTWH(-12, -7, 22, 14)));
    c.drawRect(const Rect.fromLTWH(9, -2, 9, 4), _fill(const Color(0xFFF7EBDD)));
    c.drawCircle(const Offset(19, -2.5), 3, _fill(const Color(0xFFF7EBDD)));
    c.drawCircle(const Offset(19, 2.5), 3, _fill(const Color(0xFFF7EBDD)));
    c.restore();
    // green garnish
    for (final (dx, a) in [(46.0, -0.6), (51.0, 0.5)]) {
      c.save();
      c.translate(dx, 33);
      c.rotate(a);
      c.drawOval(const Rect.fromLTWH(-2.5, -6, 5, 12), _fill(const Color(0xFF2E8B57)));
      c.restore();
    }
    // bowl
    final bowl = Path()
      ..moveTo(12, 55)
      ..lineTo(88, 55)
      ..cubicTo(86, 74, 70, 86, 50, 86)
      ..cubicTo(30, 86, 14, 74, 12, 55)
      ..close();
    c.drawPath(bowl, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFEF6E3E), Color(0xFFC9471F)]).createShader(const Rect.fromLTWH(12, 55, 76, 31)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(10, 52, 80, 7), const Radius.circular(4)), _fill(const Color(0xFFF5B942)));
    final pattern = _stroke(const Color(0x66FFFFFF), 2);
    for (final x in [30.0, 50.0, 70.0]) {
      c.drawCircle(Offset(x, 70), 3.2, pattern);
    }
  }
}

/// A cream jar, a serum dropper and a lipstick with sparkles.
class BeautyIllustration extends _Illustration {
  const BeautyIllustration();

  void _sparkle(Canvas c, Offset o, double r) {
    final p = Path()
      ..moveTo(o.dx, o.dy - r)
      ..quadraticBezierTo(o.dx, o.dy, o.dx + r, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + r)
      ..quadraticBezierTo(o.dx, o.dy, o.dx - r, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - r)
      ..close();
    c.drawPath(p, _fill(const Color(0xFFF5B942)));
  }

  @override
  void draw(Canvas c) {
    _shadow(c, const Offset(52, 88), 70, 8);
    _sparkle(c, const Offset(18, 22), 6);
    _sparkle(c, const Offset(86, 18), 4.5);
    _sparkle(c, const Offset(30, 10), 3);
    // serum dropper (back)
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(44, 30, 18, 6), const Radius.circular(2)), _fill(const Color(0xFF2B2B2B)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(47, 16, 12, 16), const Radius.circular(6)), _fill(const Color(0xFF3A3A3A)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(41, 36, 24, 46), const Radius.circular(7)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFFD9893A), Color(0xFFA85A1A)]).createShader(const Rect.fromLTWH(41, 36, 24, 46)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(45, 52, 16, 14), const Radius.circular(3)), _fill(const Color(0xFFFDF1D6)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(44, 40, 4, 34), const Radius.circular(2)), _fill(const Color(0x40FFFFFF)));
    // cream jar (front left)
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(10, 56, 36, 30), const Radius.circular(8)), _fill(const Color(0xFFFFF7F0)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(10, 56, 36, 30), const Radius.circular(8)), _stroke(const Color(0xFFEBD8C8), 1.6));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, 47, 40, 12), const Radius.circular(5)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFFF59AA8), Color(0xFFE06A7E)]).createShader(const Rect.fromLTWH(8, 47, 40, 12)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(14, 66, 28, 10), const Radius.circular(3)), _fill(const Color(0xFFFDE7DE)));
    c.drawCircle(const Offset(28, 71), 3, _fill(const Color(0xFFE85D32)));
    // lipstick (front right)
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(68, 58, 18, 28), const Radius.circular(3)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFFE9C25A), Color(0xFFB98A22)]).createShader(const Rect.fromLTWH(68, 58, 18, 28)));
    c.drawRect(const Rect.fromLTWH(70, 46, 14, 13), _fill(const Color(0xFFC9A03A)));
    final bullet = Path()
      ..moveTo(71, 46)
      ..lineTo(71, 34)
      ..quadraticBezierTo(76, 26, 83, 28)
      ..lineTo(83, 46)
      ..close();
    c.drawPath(bullet, _fill(const Color(0xFFD23B4E)));
    c.drawLine(const Offset(73, 44), const Offset(73, 34), _stroke(const Color(0x55FFFFFF), 2));
  }
}

/// A delivery scooter carrying a Gud Meal parcel box.
class ParcelIllustration extends _Illustration {
  const ParcelIllustration();

  @override
  void draw(Canvas c) {
    _shadow(c, const Offset(52, 88), 72, 7);
    final motion = _stroke(const Color(0xFFD9CFC4), 3);
    for (final (y, len) in [(58.0, 10.0), (66.0, 14.0), (74.0, 9.0)]) {
      c.drawLine(Offset(2, y), Offset(2 + len, y), motion);
    }
    // parcel box
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(16, 24, 34, 32), const Radius.circular(4)), _fill(const Color(0xFFE4AB6E)));
    c.drawRect(const Rect.fromLTWH(30, 24, 6, 32), _fill(const Color(0xFFC98A4B)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(16, 24, 34, 32), const Radius.circular(4)), _stroke(const Color(0xFFB4743A), 1.4));
    c.drawCircle(const Offset(23, 47), 3.4, _fill(const Color(0xFFE85D32)));
    // scooter body
    final body = Path()
      ..moveTo(14, 62)
      ..lineTo(60, 62)
      ..quadraticBezierTo(70, 62, 74, 70)
      ..lineTo(80, 72)
      ..lineTo(18, 72)
      ..quadraticBezierTo(12, 70, 14, 62)
      ..close();
    c.drawPath(body, Paint()..shader = const LinearGradient(colors: [Color(0xFF2E9465), Color(0xFF1D754E)]).createShader(const Rect.fromLTWH(12, 60, 70, 14)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(34, 54, 24, 7), const Radius.circular(3.5)), _fill(const Color(0xFF2B2B2B)));
    // steering column + handlebar
    c.drawLine(const Offset(70, 66), const Offset(80, 32), _stroke(const Color(0xFF1D754E), 5));
    c.drawLine(const Offset(74, 31), const Offset(88, 31), _stroke(const Color(0xFF2B2B2B), 4));
    c.drawCircle(const Offset(84, 40), 3, _fill(const Color(0xFFF5B942)));
    // wheels
    for (final x in [26.0, 76.0]) {
      c.drawCircle(Offset(x, 78), 10, _fill(const Color(0xFF2B2B2B)));
      c.drawCircle(Offset(x, 78), 4, _fill(const Color(0xFFC8C8C8)));
    }
  }
}

/// Gudy, the Gud Meal AI assistant: a friendly robot face in a blue disc with a chat-bubble tail.
class RobotPainter extends CustomPainter {
  const RobotPainter({this.eyeOpen = 1, this.ring = 0});

  /// 1 = eyes open, 0 = closed (blink).
  final double eyeOpen;

  /// 0..1 pulse ring around the disc.
  final double ring;

  static const blue = Color(0xFF1F5EFF);
  static const blueDark = Color(0xFF1546C9);

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height) / 100;
    canvas.save();
    canvas.scale(s);
    if (ring > 0) {
      canvas.drawCircle(const Offset(50, 50), 50 + 8 * ring, _fill(blue.withValues(alpha: .25 * (1 - ring))));
    }
    canvas.drawCircle(
      const Offset(50, 50),
      50,
      Paint()..shader = const RadialGradient(center: Alignment(-.3, -.4), radius: 1.1, colors: [Color(0xFF4D82FF), blue, blueDark]).createShader(const Rect.fromLTWH(0, 0, 100, 100)),
    );
    final white = _fill(Colors.white);
    // antenna
    canvas.drawLine(const Offset(50, 31), const Offset(50, 21), _stroke(Colors.white, 3.4));
    canvas.drawCircle(const Offset(50, 18.5), 4.6, white);
    // ears
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(19, 44, 8, 15), const Radius.circular(4)), _fill(const Color(0xFFDCE6FF)));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(73, 44, 8, 15), const Radius.circular(4)), _fill(const Color(0xFFDCE6FF)));
    // head with chat tail
    final head = Path()
      ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(25, 31, 50, 38), const Radius.circular(17)))
      ..moveTo(36, 64)
      ..lineTo(33, 78)
      ..lineTo(50, 67)
      ..close();
    canvas.drawPath(head, white);
    // visor
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(32, 40, 36, 19), const Radius.circular(9.5)), _fill(blue));
    // eyes (blink by squashing vertically)
    final eyeH = 8.4 * eyeOpen.clamp(0.08, 1);
    for (final x in [42.0, 58.0]) {
      canvas.drawOval(Rect.fromCenter(center: Offset(x, 49.5), width: 8.4, height: eyeH), white);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RobotPainter oldDelegate) => oldDelegate.eyeOpen != eyeOpen || oldDelegate.ring != ring;
}
