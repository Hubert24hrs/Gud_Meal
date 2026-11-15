import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

/// A dish seen from above, as on the Discover carousel: the kitchen's photo when it has uploaded one,
/// otherwise an illustrated plate drawn in code (original art, no image assets).
class DishPlate extends StatelessWidget {
  const DishPlate({super.key, required this.dish, required this.size});
  final DiscoverDish dish;
  final double size;

  @override
  Widget build(BuildContext context) {
    final art = PlateArt(art: dish.art, name: dish.name, size: size);
    final url = dish.imageUrl;
    return Semantics(
      image: true,
      label: dish.name,
      child: DecoratedBox(
        // The plate's drop shadow (two layers, like a soft studio light).
        decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: [
          BoxShadow(color: Color(0x33000000), blurRadius: 22, offset: Offset(0, 16)),
          BoxShadow(color: Color(0x1F000000), blurRadius: 5, offset: Offset(0, 3)),
        ]),
        child: SizedBox.square(
          dimension: size,
          child: url == null || url.isEmpty
              ? art
              : ClipOval(
                  child: Image.network(
                    url,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => art,
                    loadingBuilder: (_, child, progress) => progress == null ? child : art,
                  ),
                ),
        ),
      ),
    );
  }
}

/// The illustrated plate for a dish family (`rice`, `soup_swallow`, `broth`, `skewers`, `grill`, `pizza`,
/// `wrap`, `bites`, `bowl`, `plate`); [name] picks the variant (jollof vs fried rice, egusi vs efo...).
class PlateArt extends StatelessWidget {
  const PlateArt({super.key, required this.art, required this.name, this.size});
  final String art;
  final String name;
  final double? size;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: size == null ? Size.zero : Size.square(size!),
        painter: PlatePainter(art: art, name: name),
      );
}

class PlatePainter extends CustomPainter {
  PlatePainter({required this.art, required this.name});
  final String art;
  final String name;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height) / 100;
    canvas.save();
    canvas.translate((size.width - 100 * s) / 2, (size.height - 100 * s) / 2);
    canvas.scale(s);
    final d = _Draw(canvas, name);
    switch (art) {
      case 'rice':
        d.rice();
      case 'soup_swallow':
        d.soupAndSwallow();
      case 'broth':
        d.broth();
      case 'skewers':
        d.skewers();
      case 'grill':
        d.grill();
      case 'pizza':
        d.pizza();
      case 'wrap':
        d.wrap();
      case 'bites':
        d.bites();
      case 'bowl':
        d.bowl();
      default:
        d.generic();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PlatePainter old) => old.art != art || old.name != name;
}

// ------------------------------------------------------------------------------------- drawing kit
Paint _fill(Color c) => Paint()..color = c;
Paint _line(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round;

/// Draws in a 100×100 space; a name-seeded random keeps every dish's plate stable between frames.
class _Draw {
  _Draw(this.c, String name)
      : n = name.toLowerCase(),
        rnd = math.Random(name.toLowerCase().codeUnits.fold<int>(7, (h, u) => (h * 31 + u) & 0x7fffffff));

  final Canvas c;
  final String n;
  final math.Random rnd;

  bool has(List<String> words) => words.any(n.contains);
  double r(double a, double b) => a + rnd.nextDouble() * (b - a);

  // ------------------------------------------------------------------ dishes & bowls
  void plate({Color rim = const Color(0xFFFBF8F3), Color well = const Color(0xFFF3EDE4)}) {
    const o = Offset(50, 50);
    c.drawCircle(o, 49, Paint()..shader = RadialGradient(colors: [rim, Color.lerp(rim, const Color(0xFFD9D0C3), .55)!], stops: const [.8, 1]).createShader(Rect.fromCircle(center: o, radius: 49)));
    c.drawCircle(o, 48.6, _line(const Color(0x14000000), .8));
    c.drawCircle(o, 38, Paint()..shader = RadialGradient(colors: [Colors.white, well], stops: const [.55, 1]).createShader(Rect.fromCircle(center: o, radius: 38)));
    c.drawCircle(o, 38, _line(const Color(0x12000000), .9));
    // light catching the rim
    c.drawArc(Rect.fromCircle(center: o, radius: 44), -2.6, 1.3, false, _line(const Color(0x99FFFFFF), 2.4));
  }

  void bowlBase(Color rim, Color inside, {Color? glaze}) {
    const o = Offset(50, 50);
    c.drawCircle(o, 49, Paint()..shader = RadialGradient(colors: [glaze ?? rim, Color.lerp(rim, Colors.black, .25)!], stops: const [.7, 1]).createShader(Rect.fromCircle(center: o, radius: 49)));
    c.drawCircle(o, 41, _fill(Color.lerp(rim, Colors.black, .35)!));
    c.drawCircle(o, 39.5, Paint()..shader = RadialGradient(colors: [inside, Color.lerp(inside, Colors.black, .28)!], stops: const [.55, 1]).createShader(Rect.fromCircle(center: o, radius: 39.5)));
    c.drawArc(Rect.fromCircle(center: o, radius: 45), -2.7, 1.4, false, _line(const Color(0x66FFFFFF), 2.2));
  }

  /// An irregular, hand-drawn looking blob.
  Path blob(Offset o, double radius, {double wobble = .12, int points = 14}) {
    final p = Path();
    final rs = [for (var i = 0; i < points; i++) radius * (1 + r(-wobble, wobble))];
    for (var i = 0; i <= points; i++) {
      final a = i / points * 2 * math.pi;
      final rr = rs[i % points];
      final pt = o + Offset(math.cos(a) * rr, math.sin(a) * rr);
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        final pa = (i - .5) / points * 2 * math.pi;
        final pr = (rs[(i - 1) % points] + rr) / 2 * 1.04;
        final ctrl = o + Offset(math.cos(pa) * pr, math.sin(pa) * pr);
        p.quadraticBezierTo(ctrl.dx, ctrl.dy, pt.dx, pt.dy);
      }
    }
    return p..close();
  }

  void mound(Offset o, double radius, Color base, {double wobble = .1}) {
    final path = blob(o, radius, wobble: wobble);
    c.drawPath(path.shift(const Offset(0, 1.6)), _fill(const Color(0x22000000)));
    c.drawPath(path, Paint()..shader = RadialGradient(center: const Alignment(-.3, -.35), colors: [Color.lerp(base, Colors.white, .18)!, base, Color.lerp(base, Colors.black, .18)!], stops: const [0, .6, 1]).createShader(Rect.fromCircle(center: o, radius: radius)));
  }

  /// Rice-like grains scattered over a disc.
  void grains(Offset o, double radius, List<Color> colors, {int count = 130, double w = 2.6, double h = 1.15}) {
    for (var i = 0; i < count; i++) {
      final a = r(0, 2 * math.pi);
      final d = math.sqrt(rnd.nextDouble()) * radius;
      c.save();
      c.translate(o.dx + math.cos(a) * d, o.dy + math.sin(a) * d);
      c.rotate(r(0, math.pi));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: w, height: h), Radius.circular(h / 2)), _fill(colors[rnd.nextInt(colors.length)]));
      c.restore();
    }
  }

  void dots(Offset o, double spread, int count, List<Color> colors, {double size = 1}) {
    for (var i = 0; i < count; i++) {
      final a = r(0, 2 * math.pi);
      final d = math.sqrt(rnd.nextDouble()) * spread;
      c.drawCircle(o + Offset(math.cos(a) * d, math.sin(a) * d), size * r(.7, 1.3), _fill(colors[rnd.nextInt(colors.length)]));
    }
  }

  void chunk(Offset o, double w, double h, double angle, Color color, {double radius = 2.2}) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(angle);
    final rect = Rect.fromCenter(center: Offset.zero, width: w, height: h);
    c.drawRRect(RRect.fromRectAndRadius(rect.shift(const Offset(.5, 1)), Radius.circular(radius)), _fill(const Color(0x2A000000)));
    c.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)), Paint()..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color.lerp(color, Colors.white, .22)!, color, Color.lerp(color, Colors.black, .25)!]).createShader(rect));
    c.restore();
  }

  void leaf(Offset o, double length, double angle, Color color) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(angle);
    final p = Path()
      ..moveTo(-length / 2, 0)
      ..quadraticBezierTo(0, -length * .38, length / 2, 0)
      ..quadraticBezierTo(0, length * .38, -length / 2, 0)
      ..close();
    c.drawPath(p, _fill(color));
    c.drawLine(Offset(-length / 2, 0), Offset(length / 2.2, 0), _line(Color.lerp(color, Colors.white, .35)!, .5));
    c.restore();
  }

  /// A round slice: tomato, cucumber, dodo, garden egg...
  void slice(Offset o, double radius, Color skin, Color flesh, {Color? seeds, double squash = 1}) {
    final rect = Rect.fromCenter(center: o, width: radius * 2, height: radius * 2 * squash);
    c.drawOval(rect.shift(const Offset(.4, .9)), _fill(const Color(0x26000000)));
    c.drawOval(rect, _fill(skin));
    c.drawOval(rect.deflate(radius * .18), _fill(flesh));
    if (seeds != null) {
      for (var i = 0; i < 6; i++) {
        final a = i / 6 * 2 * math.pi;
        c.drawCircle(o + Offset(math.cos(a) * radius * .45, math.sin(a) * radius * .45 * squash), radius * .12, _fill(seeds));
      }
    }
  }

  void ring(Offset o, double radius, Color color, {double width = 1.3}) => c.drawCircle(o, radius, _line(color, width));

  void tomatoes(Offset o, int count, double size) {
    for (var i = 0; i < count; i++) {
      slice(o + Offset(r(-6, 6), r(-5, 5)), size * r(.85, 1.1), const Color(0xFFD32F2F), const Color(0xFFEF5350), seeds: const Color(0xFFFFCDD2));
    }
  }

  void onions(Offset o, int count, double size) {
    for (var i = 0; i < count; i++) {
      final p = o + Offset(r(-7, 7), r(-6, 6));
      ring(p, size * r(.8, 1.2), const Color(0xFF9C5BA9));
      ring(p, size * r(.45, .6), const Color(0xCCE1BEE7), width: .9);
    }
  }

  void dodo(Offset o, int count) {
    for (var i = 0; i < count; i++) {
      c.save();
      c.translate(o.dx + r(-6, 6), o.dy + r(-5, 5));
      c.rotate(r(-1, 1));
      final rect = Rect.fromCenter(center: Offset.zero, width: r(10, 12.5), height: r(6.5, 8));
      c.drawOval(rect.shift(const Offset(.5, 1)), _fill(const Color(0x30000000)));
      c.drawOval(rect, Paint()..shader = const RadialGradient(colors: [Color(0xFFF8C15C), Color(0xFFE69A2E), Color(0xFFB8641A)], stops: [0, .65, 1]).createShader(rect));
      c.restore();
    }
  }

  void drumstick(Offset o, double angle, {double scale = 1}) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(angle);
    c.scale(scale);
    final meat = Path()
      ..moveTo(-13, 0)
      ..cubicTo(-13, -10, 3, -9, 6, -3)
      ..lineTo(12, -1.6)
      ..lineTo(12, 1.6)
      ..lineTo(6, 3)
      ..cubicTo(3, 9, -13, 10, -13, 0)
      ..close();
    c.drawPath(meat.shift(const Offset(.8, 1.4)), _fill(const Color(0x33000000)));
    c.drawPath(meat, Paint()..shader = const RadialGradient(center: Alignment(-.3, -.4), colors: [Color(0xFFD4843F), Color(0xFFA2491A), Color(0xFF6B2B0C)], stops: [0, .6, 1]).createShader(const Rect.fromLTWH(-13, -10, 25, 20)));
    for (var i = 0; i < 3; i++) {
      c.drawLine(Offset(-9.0 + i * 5, -6), Offset(-6.0 + i * 5, 6), _line(const Color(0x553B1406), 1.4));
    }
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(11, -1.4, 6, 2.8), const Radius.circular(1.4)), _fill(const Color(0xFFF6EAD8)));
    c.drawCircle(const Offset(17.5, -1.8), 2.3, _fill(const Color(0xFFF6EAD8)));
    c.drawCircle(const Offset(17.5, 1.8), 2.3, _fill(const Color(0xFFF6EAD8)));
    c.restore();
  }

  void greens(Offset o, int count, {double size = 7}) {
    const shades = [Color(0xFF2E7D32), Color(0xFF43A047), Color(0xFF66BB6A), Color(0xFF1B5E20)];
    for (var i = 0; i < count; i++) {
      leaf(o + Offset(r(-8, 8), r(-7, 7)), size * r(.8, 1.3), r(0, math.pi), shades[rnd.nextInt(shades.length)]);
    }
  }

  // ------------------------------------------------------------------ families
  void rice() {
    plate();
    final (base, light, dark) = has(['fried'])
        ? (const Color(0xFFE2B84C), const Color(0xFFF4D98A), const Color(0xFFC0912C))
        : has(['ofada'])
            ? (const Color(0xFFCDB892), const Color(0xFFE6D8B9), const Color(0xFFAE9567))
            : has(['coconut'])
                ? (const Color(0xFFEFE3C6), const Color(0xFFFFF6E3), const Color(0xFFD8C7A1))
                : (const Color(0xFFD9572A), const Color(0xFFF07A3E), const Color(0xFFB8421B));
    const o = Offset(44, 50);
    mound(o, 26, base);
    grains(o, 24, [light, base, dark, light], count: 170);
    if (has(['fried'])) {
      dots(o, 22, 18, const [Color(0xFF5FA83A), Color(0xFF7CC24E)], size: 1.4);
      for (var i = 0; i < 12; i++) {
        chunk(o + Offset(r(-18, 18), r(-16, 16)), 2.4, 2.4, r(0, 1), const Color(0xFFF08A2B), radius: .5);
      }
    }
    if (has(['ofada'])) {
      // ayamase: green pepper stew with red oil and assorted meat
      final sauce = blob(const Offset(66, 60), 15, wobble: .16);
      c.drawPath(sauce, _fill(const Color(0xFF3E5A23)));
      dots(const Offset(66, 60), 12, 20, const [Color(0xCCB71C1C), Color(0x99E65100)], size: 1.3);
      for (var i = 0; i < 4; i++) {
        chunk(Offset(r(58, 74), r(52, 68)), 6, 4.5, r(0, 3), const Color(0xFF6D3B22));
      }
    } else {
      drumstick(const Offset(66, 40), -.6);
      dodo(const Offset(66, 66), 3);
    }
    greens(const Offset(32, 70), 2, size: 6);
    tomatoes(const Offset(30, 32), 1, 4.5);
  }

  void soupAndSwallow() {
    plate();
    // soup bowl on the plate
    const soupAt = Offset(37, 45);
    c.drawCircle(soupAt + const Offset(0, 1.6), 23, _fill(const Color(0x26000000)));
    c.drawCircle(soupAt, 23, _fill(const Color(0xFFFFFFFF)));
    c.drawCircle(soupAt, 23, _line(const Color(0x14000000), .8));
    final (soup, specks) = switch (n) {
      _ when has(['gbegiri']) => (const Color(0xFFE2A93B), const [Color(0xFFF2C866), Color(0xFFC88A23)]),
      _ when has(['efo', 'edikang', 'afang']) => (const Color(0xFF2E5E2A), const [Color(0xFF3E7D35), Color(0xFF1E431C), Color(0xCCB71C1C)]),
      _ when has(['onugbu', 'bitterleaf', 'oha', 'owerri']) => (const Color(0xFF4B4A22), const [Color(0xFF6B6B2E), Color(0xFF2F3A17), Color(0xAAC0392B)]),
      _ when has(['okra', 'ogbono']) => (const Color(0xFF6B8A33), const [Color(0xFF8DAA4A), Color(0xFFE8E2B0)]),
      _ when has(['banga']) => (const Color(0xFFB45A24), const [Color(0xFFD9823C), Color(0xFF7A3712)]),
      _ => (const Color(0xFFB8A23E), const [Color(0xFFE6D58A), Color(0xFF8C7A24), Color(0xAAD84315)]), // egusi
    };
    c.drawCircle(soupAt, 19.5, Paint()..shader = RadialGradient(colors: [Color.lerp(soup, Colors.white, .12)!, soup, Color.lerp(soup, Colors.black, .22)!], stops: const [0, .7, 1]).createShader(Rect.fromCircle(center: soupAt, radius: 19.5)));
    if (has(['gbegiri']) && has(['ewedu'])) {
      // gbegiri and ewedu side by side, with a ladle of stew
      final ewedu = Path()..addArc(Rect.fromCircle(center: soupAt, radius: 19.5), .9, 2.4);
      c.drawPath(ewedu, _fill(const Color(0xFF4C7F2E)));
      dots(soupAt + const Offset(-6, 8), 7, 16, const [Color(0xFF6FA64A), Color(0xFF2F5A1C)], size: .9);
    }
    dots(soupAt, 16, 46, specks, size: 1.2);
    for (var i = 0; i < 4; i++) {
      chunk(soupAt + Offset(r(-11, 11), r(-11, 11)), r(5, 7), r(4, 5.5), r(0, 3), const Color(0xFF6D3B22));
    }
    // a slick of palm oil
    c.drawOval(Rect.fromCenter(center: soupAt + const Offset(6, -7), width: 9, height: 4), _fill(const Color(0x55FF8F00)));

    // the swallow, wrapped and glossy
    final swallow = switch (n) {
      _ when has(['amala']) => const Color(0xFF6B4E3D),
      _ when has(['eba', 'garri']) => const Color(0xFFE9D79E),
      _ when has(['semo', 'semovita', 'fufu']) => const Color(0xFFF1E9D8),
      _ => const Color(0xFFF5F0E6), // pounded yam
    };
    const ballAt = Offset(69, 64);
    c.drawCircle(ballAt + const Offset(.8, 2), 17, _fill(const Color(0x33000000)));
    c.drawCircle(ballAt, 17, Paint()..shader = RadialGradient(center: const Alignment(-.35, -.4), colors: [Color.lerp(swallow, Colors.white, .35)!, swallow, Color.lerp(swallow, Colors.black, .2)!], stops: const [0, .55, 1]).createShader(Rect.fromCircle(center: ballAt, radius: 17)));
    c.drawArc(Rect.fromCircle(center: ballAt, radius: 12), -2.5, 1.1, false, _line(const Color(0x88FFFFFF), 2));
    greens(const Offset(72, 36), 1, size: 6);
  }

  void broth() {
    bowlBase(const Color(0xFF9C4A26), const Color(0xFF8E3A16), glaze: const Color(0xFFB65A2E));
    const o = Offset(50, 50);
    // pepper soup: catfish/goat pieces in a deep red-brown broth
    final fish = has(['fish', 'catfish', 'point and kill']);
    for (var i = 0; i < 5; i++) {
      final p = o + Offset(r(-18, 18), r(-18, 18));
      if (fish) {
        c.drawCircle(p + const Offset(.5, 1), 6.2, _fill(const Color(0x33000000)));
        c.drawCircle(p, 6.2, _fill(const Color(0xFF6E5A4C)));
        c.drawCircle(p, 4.4, _fill(const Color(0xFFE2CFB6)));
        c.drawCircle(p, 1.2, _fill(const Color(0xFFBFA88A)));
      } else {
        chunk(p, r(7, 9), r(5, 7), r(0, 3), const Color(0xFF6D3B22));
      }
    }
    dots(o, 30, 30, const [Color(0x66FFB74D), Color(0x44FFE0B2)], size: 1.8); // oil sheen
    dots(o, 30, 26, const [Color(0xFFE53935), Color(0xFFFF7043)], size: .7); // pepper
    greens(const Offset(46, 40), 3, size: 6.5); // scent leaf
  }

  void skewers() {
    plate();
    final asun = has(['asun', 'gizzard']);
    if (asun) {
      for (var i = 0; i < 16; i++) {
        chunk(Offset(r(28, 72), r(28, 72)), r(6, 8.5), r(5, 7), r(0, 3), const Color(0xFF7B2E12));
      }
      dots(const Offset(50, 50), 24, 30, const [Color(0xFFD32F2F), Color(0xFF43A047), Color(0xFFFFB300)], size: 1.4);
    } else {
      for (var k = 0; k < 3; k++) {
        final y = 36.0 + k * 13;
        final from = Offset(20, y + 10);
        final to = Offset(80, y - 10);
        c.drawLine(from, to, _line(const Color(0xFFC9A06A), 1.6));
        for (var i = 0; i < 5; i++) {
          final t = .14 + i * .17;
          final p = Offset.lerp(from, to, t)!;
          chunk(p, 9, 7, -.32 + r(-.15, .15), i.isEven ? const Color(0xFF7B2E12) : const Color(0xFF8E3A16));
        }
      }
      // yaji spice
      dots(const Offset(50, 48), 28, 60, const [Color(0xFFD9893B), Color(0xFF5A2A12), Color(0xFFB0532A)], size: .7);
    }
    onions(const Offset(30, 72), 2, 5);
    tomatoes(const Offset(70, 74), 2, 4.6);
    // cabbage shreds
    for (var i = 0; i < 8; i++) {
      final p = Offset(r(40, 60), r(70, 80));
      c.drawArc(Rect.fromCenter(center: p, width: r(6, 9), height: r(3, 5)), r(0, 3), 2.2, false, _line(const Color(0xFFC5E1A5), 1.1));
    }
  }

  void grill() {
    plate();
    if (has(['croaker', 'fish', 'tilapia'])) {
      // a whole grilled fish with grill marks
      c.save();
      c.translate(48, 48);
      c.rotate(-.5);
      final body = Path()
        ..moveTo(-30, 0)
        ..cubicTo(-22, -13, 14, -14, 22, -2)
        ..lineTo(32, -9)
        ..lineTo(30, 0)
        ..lineTo(32, 9)
        ..lineTo(22, 2)
        ..cubicTo(14, 14, -22, 13, -30, 0)
        ..close();
      c.drawPath(body.shift(const Offset(1, 2)), _fill(const Color(0x33000000)));
      c.drawPath(body, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB07A4A), Color(0xFF8A5530), Color(0xFF5E3A20)]).createShader(const Rect.fromLTWH(-30, -14, 62, 28)));
      for (var i = 0; i < 6; i++) {
        c.drawLine(Offset(-18.0 + i * 6, -9), Offset(-22.0 + i * 6, 9), _line(const Color(0x993B2210), 1.5));
      }
      c.drawCircle(const Offset(-22, -3), 2.2, _fill(Colors.white));
      c.drawCircle(const Offset(-22, -3), 1.1, _fill(Colors.black87));
      c.restore();
      if (has(['bole'])) {
        for (var i = 0; i < 3; i++) {
          chunk(Offset(r(64, 78), r(66, 78)), 12, 6, r(-.6, .6), const Color(0xFFD99A3B));
          c.drawLine(Offset(r(64, 76), r(66, 76)), Offset(r(66, 78), r(68, 78)), _line(const Color(0xAA3E2723), 1.2));
        }
      }
    } else {
      // grilled chicken quarter with peppers
      const o = Offset(46, 48);
      final p = blob(o, 21, wobble: .16, points: 10);
      c.drawPath(p.shift(const Offset(1, 2)), _fill(const Color(0x33000000)));
      c.drawPath(p, Paint()..shader = const RadialGradient(center: Alignment(-.3, -.4), colors: [Color(0xFFE09A4E), Color(0xFFB8641E), Color(0xFF7A3510)], stops: [0, .6, 1]).createShader(Rect.fromCircle(center: o, radius: 21)));
      for (var i = 0; i < 5; i++) {
        c.drawLine(Offset(30.0 + i * 7, 32), Offset(26.0 + i * 7, 64), _line(const Color(0x88401708), 1.8));
      }
      drumstick(const Offset(70, 34), .9, scale: .7);
    }
    // peppers & onion
    for (var i = 0; i < 4; i++) {
      chunk(Offset(r(60, 78), r(56, 74)), 7, 3, r(0, 3), i.isEven ? const Color(0xFFD32F2F) : const Color(0xFF43A047), radius: 1.5);
    }
    onions(const Offset(30, 74), 2, 4.5);
  }

  void pizza() {
    // wooden board
    const o = Offset(50, 50);
    c.drawCircle(o, 49, Paint()..shader = const RadialGradient(colors: [Color(0xFFC9955A), Color(0xFF9C6B37)], stops: [.75, 1]).createShader(Rect.fromCircle(center: o, radius: 49)));
    c.drawCircle(o + const Offset(.8, 1.6), 43, _fill(const Color(0x33000000)));
    c.drawCircle(o, 43, Paint()..shader = const RadialGradient(colors: [Color(0xFFF1C27A), Color(0xFFD9963F)], stops: [.82, 1]).createShader(Rect.fromCircle(center: o, radius: 43)));
    c.drawCircle(o, 36, _fill(const Color(0xFFC6402B)));
    // cheese
    for (var i = 0; i < 14; i++) {
      final a = r(0, 2 * math.pi);
      final d = math.sqrt(rnd.nextDouble()) * 28;
      c.drawPath(blob(o + Offset(math.cos(a) * d, math.sin(a) * d), r(5, 8), wobble: .25, points: 8), _fill(const Color(0xFFF7D98F)));
    }
    if (has(['margherita'])) {
      for (var i = 0; i < 6; i++) {
        final a = i / 6 * 2 * math.pi;
        c.drawCircle(o + Offset(math.cos(a) * 20, math.sin(a) * 20), 5.5, _fill(const Color(0xFFFFF4DA)));
      }
      greens(o, 5, size: 7);
    } else {
      final suya = has(['suya']);
      for (var i = 0; i < 14; i++) {
        final a = r(0, 2 * math.pi);
        final d = math.sqrt(rnd.nextDouble()) * 30;
        chunk(o + Offset(math.cos(a) * d, math.sin(a) * d), 5, 4, r(0, 3), suya ? const Color(0xFF7B2E12) : const Color(0xFFB8641E), radius: 1.5);
      }
      for (var i = 0; i < 8; i++) {
        final a = r(0, 2 * math.pi);
        final d = math.sqrt(rnd.nextDouble()) * 28;
        chunk(o + Offset(math.cos(a) * d, math.sin(a) * d), 6, 2.4, r(0, 3), i.isEven ? const Color(0xFF43A047) : const Color(0xFFFFB300), radius: 1);
      }
      onions(o, 3, 4.5);
    }
    // slice cuts
    for (var i = 0; i < 6; i++) {
      final a = i / 6 * 2 * math.pi + .3;
      c.drawLine(o, o + Offset(math.cos(a) * 42, math.sin(a) * 42), _line(const Color(0x55000000), .7));
    }
  }

  void wrap() {
    plate();
    for (final (o, angle) in [(const Offset(42, 44), -.55), (const Offset(58, 58), -.55)]) {
      c.save();
      c.translate(o.dx, o.dy);
      c.rotate(angle);
      const rect = Rect.fromLTWH(-24, -9, 48, 18);
      c.drawRRect(RRect.fromRectAndRadius(rect.shift(const Offset(1, 2)), const Radius.circular(9)), _fill(const Color(0x33000000)));
      c.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(9)), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF0C989), Color(0xFFD9A35B), Color(0xFFB37A38)]).createShader(rect));
      for (var i = 0; i < 5; i++) {
        c.drawLine(Offset(-16.0 + i * 8, -8), Offset(-20.0 + i * 8, 8), _line(const Color(0x66704214), 1.4));
      }
      // wrapper paper with a stripe
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, -9.6, 17, 19.2), const Radius.circular(4)), _fill(const Color(0xFFFAFAFA)));
      c.drawRect(const Rect.fromLTWH(14, -9.6, 3, 19.2), _fill(const Color(0xFFE85D32)));
      // the cut end: chicken, cabbage, carrot, sauce
      const end = Offset(-22, 0);
      c.drawCircle(end, 8, _fill(const Color(0xFFF3E1BE)));
      dots(end, 6, 14, const [Color(0xFFC7894B), Color(0xFFCFE8A5), Color(0xFFF08A2B), Color(0xFFFFFFFF), Color(0xFFD32F2F)], size: 1.3);
      c.restore();
    }
  }

  void bites() {
    plate();
    void puff(Offset p, double radius) {
      c.drawCircle(p + const Offset(.6, 1.4), radius, _fill(const Color(0x33000000)));
      c.drawCircle(p, radius, Paint()..shader = RadialGradient(center: const Alignment(-.35, -.4), colors: const [Color(0xFFF6C66A), Color(0xFFDB8A2C), Color(0xFF9C5214)], stops: const [0, .6, 1]).createShader(Rect.fromCircle(center: p, radius: radius)));
    }

    if (has(['puff'])) {
      for (final p in [const Offset(36, 38), const Offset(54, 34), const Offset(66, 50), const Offset(46, 54), const Offset(30, 58), const Offset(58, 68), const Offset(42, 72)]) {
        puff(p + Offset(r(-2, 2), r(-2, 2)), r(8, 10));
      }
      dots(const Offset(50, 52), 26, 40, const [Color(0xEEFFFFFF)], size: .6); // sugar
      return;
    }
    if (has(['fries', 'chips'])) {
      for (var i = 0; i < 26; i++) {
        chunk(Offset(r(28, 72), r(28, 72)), r(14, 20), 3.6, r(0, 3), const Color(0xFFF2C14E), radius: 1.2);
      }
      if (has(['loaded'])) dots(const Offset(50, 50), 18, 30, const [Color(0xFFFFF59D), Color(0xFFD32F2F), Color(0xFF7B2E12)], size: 1.6);
      return;
    }
    if (has(['meat pie', 'pie'])) {
      for (final (p, a) in [(const Offset(38, 42), -.4), (const Offset(62, 46), .5), (const Offset(48, 66), .1)]) {
        c.save();
        c.translate(p.dx, p.dy);
        c.rotate(a);
        final pie = Path()
          ..addArc(const Rect.fromLTWH(-15, -15, 30, 30), math.pi, math.pi)
          ..close();
        c.drawPath(pie.shift(const Offset(.6, 1.6)), _fill(const Color(0x33000000)));
        c.drawPath(pie, Paint()..shader = const LinearGradient(colors: [Color(0xFFF2CB7E), Color(0xFFD99A45)]).createShader(const Rect.fromLTWH(-15, -15, 30, 15)));
        for (var i = 0; i < 9; i++) {
          final x = -13 + i * 3.25;
          c.drawCircle(Offset(x, 0), 1, _fill(const Color(0xFFB8782E)));
        }
        c.restore();
      }
      return;
    }
    if (has(['moi moi', 'moimoi'])) {
      leaf(const Offset(50, 50), 70, -.5, const Color(0xFF3E7D35));
      c.drawPath(blob(const Offset(50, 50), 18, wobble: .08), _fill(const Color(0xFFE07A3F)));
      dots(const Offset(50, 50), 14, 14, const [Color(0xFFF5E6C8), Color(0xFF7B2E12)], size: 1.4);
      return;
    }
    // small chops platter: puff-puff, spring rolls, samosa and peppered gizzard
    for (final p in [const Offset(34, 36), const Offset(44, 30), const Offset(30, 48)]) {
      puff(p, 7.5);
    }
    for (var i = 0; i < 3; i++) {
      chunk(Offset(62 + i * 4.0, 34 + i * 7.0), 22, 6.5, -.5, const Color(0xFFD9A35B), radius: 3);
    }
    for (final (p, a) in [(const Offset(38, 66), .2), (const Offset(54, 70), -.3)]) {
      c.save();
      c.translate(p.dx, p.dy);
      c.rotate(a);
      final tri = Path()
        ..moveTo(0, -9)
        ..lineTo(9, 7)
        ..lineTo(-9, 7)
        ..close();
      c.drawPath(tri.shift(const Offset(.6, 1.4)), _fill(const Color(0x33000000)));
      c.drawPath(tri, _fill(const Color(0xFFD99A45)));
      c.restore();
    }
    for (var i = 0; i < 5; i++) {
      chunk(Offset(r(64, 76), r(58, 72)), 5, 4, r(0, 3), const Color(0xFF6D2A12));
    }
  }

  void bowl() {
    if (has(['parfait', 'yoghurt', 'yogurt', 'granola'])) {
      bowlBase(const Color(0xFFE8F1F7), const Color(0xFFFFFFFF), glaze: const Color(0xFFF7FBFE)); // a glass
      const o = Offset(50, 50);
      c.drawCircle(o, 36, _fill(const Color(0xFFFFFBF2)));
      dots(o, 30, 26, const [Color(0xFFB07A3A), Color(0xFFD9A35B), Color(0xFF8D5A2B)], size: 2.2); // granola
      for (var i = 0; i < 7; i++) {
        final p = o + Offset(r(-24, 24), r(-24, 24));
        c.drawCircle(p, r(3, 4), _fill(i.isEven ? const Color(0xFFC62828) : const Color(0xFF5E35B1)));
      }
      for (var i = 0; i < 6; i++) {
        chunk(o + Offset(r(-20, 20), r(-20, 20)), 5, 5, r(0, 1), const Color(0xFFFFB300), radius: 1);
      }
      greens(o + const Offset(4, -6), 1, size: 6);
      return;
    }
    if (has(['fruit'])) {
      bowlBase(const Color(0xFFF4EFE6), const Color(0xFFFFFFFF));
      const colors = [Color(0xFFE53935), Color(0xFFFFC107), Color(0xFFFF8F00), Color(0xFF7CB342), Color(0xFF8E24AA)];
      for (var i = 0; i < 26; i++) {
        final p = const Offset(50, 50) + Offset(r(-28, 28), r(-28, 28));
        if ((p - const Offset(50, 50)).distance > 32) continue;
        chunk(p, r(5, 7), r(5, 7), r(0, 2), colors[rnd.nextInt(colors.length)], radius: 1.4);
      }
      return;
    }
    bowlBase(const Color(0xFFF4EFE6), const Color(0xFFFFFFFF));
    const o = Offset(50, 50);
    if (has(['abacha'])) {
      // shredded cassava with ugba, palm-oil dressing, fish and garden egg
      c.drawCircle(o, 34, _fill(const Color(0x66E65100)));
      for (var i = 0; i < 60; i++) {
        final p = o + Offset(r(-26, 26), r(-26, 26));
        if ((p - o).distance > 30) continue;
        c.drawArc(Rect.fromCenter(center: p, width: r(6, 10), height: r(2, 4)), r(0, 3), 2.4, false, _line(const Color(0xFFF1E3C8), 1.3));
      }
      dots(o, 26, 24, const [Color(0xFF4E342E), Color(0xFF6D4C41)], size: 1.6);
      for (var i = 0; i < 3; i++) {
        slice(o + Offset(r(-16, 16), r(-16, 16)), 5, const Color(0xFFDCE775), const Color(0xFFFAFAF0), seeds: const Color(0xFFBDB76B));
      }
      chunk(o + const Offset(12, 10), 14, 9, .4, const Color(0xFF8D6E63));
      onions(o + const Offset(-10, 8), 2, 4.5);
      greens(o + const Offset(-6, -14), 2, size: 6);
      return;
    }
    // salad / power bowl: greens with toppings in sections
    greens(o + const Offset(-10, -8), 14, size: 9);
    if (has(['plantain', 'bean'])) {
      dots(o + const Offset(10, -10), 10, 40, const [Color(0xFF8D5524), Color(0xFF6D3B1F)], size: 1.9); // beans
      for (var i = 0; i < 7; i++) {
        chunk(o + Offset(r(4, 20), r(4, 20)), 5, 5, r(0, 1), const Color(0xFFF2A93B), radius: 1.2); // plantain
      }
    }
    if (has(['quinoa'])) {
      dots(o + const Offset(8, 8), 14, 90, has(['jollof']) ? const [Color(0xFFE8763A), Color(0xFFF29A5B)] : const [Color(0xFFE6D3A3), Color(0xFFD1BC8A)], size: .9);
    }
    if (has(['chicken'])) {
      for (var i = 0; i < 5; i++) {
        chunk(o + Offset(4 + i * 3.0, 6 + i * 2.5), 12, 4.5, -.6, const Color(0xFFC98A4B), radius: 2);
      }
    }
    // avocado and egg
    for (var i = 0; i < 3; i++) {
      c.save();
      c.translate(o.dx - 16 + i * 4, o.dy + 14);
      c.rotate(-.4);
      c.drawOval(const Rect.fromLTWH(-6, -3, 12, 6), _fill(const Color(0xFF9CCC65)));
      c.drawOval(const Rect.fromLTWH(-6, -3, 12, 2.4), _fill(const Color(0xFF33691E)));
      c.restore();
    }
    slice(o + const Offset(16, -16), 6, const Color(0xFFFFFFFF), const Color(0xFFFFC107));
    tomatoes(o + const Offset(-14, -16), 2, 3.6);
  }

  void generic() {
    plate();
    const o = Offset(48, 50);
    mound(o, 22, const Color(0xFFE8A23B));
    grains(o, 20, const [Color(0xFFF7C46A), Color(0xFFD4882A)], count: 90);
    greens(const Offset(66, 38), 2, size: 7);
    tomatoes(const Offset(66, 64), 2, 4.5);
  }
}
