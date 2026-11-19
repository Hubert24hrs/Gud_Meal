import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

// The stage is 440 x 930 design units; every size is a multiple of one unit, so the printer scales with the
// screen exactly like the website's (apps/web/src/components/ui/receipt-printer.tsx).
const _stageW = 440.0;
const _stageH = 930.0;
const _slotY = 690.0; // where the paper comes out
const _paperW = 300.0;
const _paperX = (_stageW - _paperW) / 2;

enum _Phase { idle, printing, stopped }

/// One printed copy on the strip, shown as far as it has printed.
class _Copy {
  _Copy(this.id, this.controller) : feed = CurvedAnimation(parent: controller, curve: const Cubic(0.4, 0, 0.9, 1));
  final int id;
  final AnimationController controller;
  final CurvedAnimation feed;

  void dispose() {
    feed.dispose();
    controller.dispose();
  }
}

/// Receipt printer (ADR-0019), after a design by Aakash Mehra: a thermal printer seen from above, its paper slot
/// facing up the screen.
///
/// Press the red PRINT button and the receipt of the order rises out of the slot, header first. The paper is one
/// continuous strip: press PRINT mid-print and it stops where it is; press it again (or after it finishes) and
/// another copy prints on, joined to what is already out. Pull the strip up or sideways and it tears off along a
/// zigzag edge and flies away. The phone has no sound synthesiser, so the motor is felt as small vibrations.
class ReceiptPrinter extends StatefulWidget {
  const ReceiptPrinter({super.key, required this.receipt, this.onPrint, this.notice});
  final Receipt receipt;

  /// A copy started printing (the first one is when the receipt is saved).
  final VoidCallback? onPrint;

  /// Shown under the printer in place of the usual hint, e.g. when saving failed.
  final String? notice;

  @override
  State<ReceiptPrinter> createState() => _ReceiptPrinterState();
}

class _ReceiptPrinterState extends State<ReceiptPrinter> with TickerProviderStateMixin {
  // The paper is one continuous strip: every print joins a new copy onto the end of it.
  final List<_Copy> _strip = [];
  List<_Copy>? _flying;
  Offset _flyFrom = Offset.zero;
  Offset _flyVelocity = Offset.zero;
  late final AnimationController _fly = AnimationController(vsync: this, duration: const Duration(milliseconds: 850))
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) setState(_dropFlying);
    });
  late final AnimationController _blink = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  late final AnimationController _spring = AnimationController(vsync: this, duration: const Duration(milliseconds: 450))
    ..addListener(() => setState(() => _pull = Offset.lerp(_springFrom, Offset.zero, Curves.elasticOut.transform(_spring.value))!));
  Offset _pull = Offset.zero;
  Offset _springFrom = Offset.zero;
  Offset _drag = Offset.zero;
  _Phase _phase = _Phase.idle;
  bool _pressed = false;
  bool _quiet = false;
  int _nextId = 0;
  Timer? _chatter;

  bool get _reduceMotion => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void dispose() {
    _chatter?.cancel();
    for (final c in [..._strip, ...?_flying]) {
      c.dispose();
    }
    _fly.dispose();
    _blink.dispose();
    _spring.dispose();
    super.dispose();
  }

  void _dropFlying() {
    for (final c in _flying ?? const <_Copy>[]) {
      c.dispose();
    }
    _flying = null;
  }

  void _feel(Future<void> Function() haptic) {
    if (!_quiet) haptic();
  }

  void _stopChatter() {
    _chatter?.cancel();
    _chatter = null;
    _blink
      ..stop()
      ..value = 0;
  }

  /// Print a whole new copy onto the end of the strip.
  void _printOne() {
    final r = widget.receipt;
    // roughly how long one receipt takes
    final rows = 18 + r.lines.fold<int>(0, (n, l) => n + 1 + l.details.length) + r.charges.length + r.summary.length;
    final seconds = math.min(0.9 + rows * 0.1, 5.5);
    final controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _reduceMotion ? 1 : (seconds * 1000).round()),
    );
    controller.addStatusListener((status) {
      if (status != AnimationStatus.completed || !mounted) return;
      _stopChatter();
      setState(() => _phase = _Phase.stopped);
      _feel(HapticFeedback.lightImpact);
    });
    setState(() {
      _strip.add(_Copy(_nextId++, controller));
      _phase = _Phase.printing;
    });
    widget.onPrint?.call();
    controller.forward();
    _blink.repeat(reverse: true);
    // The feed motor, felt instead of heard: a quick run of ticks while the paper moves.
    _chatter?.cancel();
    _chatter = Timer.periodic(const Duration(milliseconds: 110), (_) => _feel(HapticFeedback.selectionClick));
  }

  void _stopFeed() {
    if (_strip.isNotEmpty) _strip.last.controller.stop();
    _stopChatter();
    setState(() => _phase = _Phase.stopped);
  }

  /// PRINT: stops the feed if it is running, otherwise prints another copy onto the strip.
  void _pressPrint() {
    _feel(HapticFeedback.mediumImpact);
    if (!_quiet) SystemSound.play(SystemSoundType.click);
    setState(() => _pressed = true);
    Future<void>.delayed(const Duration(milliseconds: 140), () {
      if (mounted) setState(() => _pressed = false);
    });
    if (_phase == _Phase.printing) {
      _stopFeed();
    } else {
      Future<void>.delayed(const Duration(milliseconds: 160), () {
        if (mounted && _phase != _Phase.printing) _printOne();
      });
    }
  }

  /// Rip the whole strip off at the slot; it flies away with the given velocity.
  void _tear(Offset velocity) {
    if (_strip.isEmpty) return;
    for (final c in _strip) {
      c.controller.stop();
    }
    _stopChatter();
    _spring.stop();
    _feel(HapticFeedback.heavyImpact);
    setState(() {
      _dropFlying();
      _flying = List.of(_strip);
      _strip.clear();
      _flyFrom = _pull;
      _flyVelocity = velocity;
      _pull = Offset.zero;
      _phase = _Phase.idle;
      if (_reduceMotion) _dropFlying();
    });
    if (!_reduceMotion) _fly.forward(from: 0);
  }

  // Pulling the strip: it gives a little (it is still attached), then rips.
  void _onPull(DragUpdateDetails d) {
    _drag += d.delta;
    final dx = _drag.dx;
    final dy = math.min(0.0, _drag.dy); // pushing it back into the printer does nothing
    if (Offset(dx, dy).distance > 80) {
      _tear(Offset(dx * 8, math.min(_drag.dy * 8, -300)));
    } else {
      setState(() => _pull = Offset(dx * 0.3, dy * 0.3));
    }
  }

  void _onPullEnd(DragEndDetails _) {
    if (_strip.isEmpty || _pull == Offset.zero) return;
    _springFrom = _pull;
    _spring.forward(from: 0);
  }

  String get _hint =>
      widget.notice ??
      switch (_phase) {
        _Phase.printing => 'Printing your receipt… press PRINT to stop',
        _ when _strip.isNotEmpty => 'Pull the receipt to tear it off, or press PRINT for another copy',
        _ => 'Press the red PRINT button to print your receipt',
      };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // 76 px of the height is kept free so the hint under the printer never runs off a short screen.
      final u = math.max(0.2, math.min((constraints.maxWidth - 32) / _stageW, (constraints.maxHeight - 76) / _stageH));
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3),
            radius: 0.9,
            colors: [Color(0xFFE9E6DF), Color(0xFFDCD8CF), Color(0xFFCDC8BD)],
            stops: [0, 0.55, 1],
          ),
        ),
        child: Stack(children: [
          Center(
            child: SizedBox(
              width: _stageW * u,
              height: _stageH * u,
              child: Stack(clipBehavior: Clip.none, children: [
                _printer(u),
                _paper(u),
                _tearBar(u),
                if (_flying != null) _flyingStrip(u),
              ]),
            ),
          ),
          // What to do next, at the bottom of the screen; the side space keeps it clear of the round button.
          Positioned(left: 64, right: 64, bottom: 10, child: _hintPill()),
          Positioned(right: 16, bottom: 16, child: _quietButton()),
        ]),
      );
    });
  }

  /// The strip, rising out of the slot; clipped at the slot so it comes from inside, free to run off the top.
  Widget _paper(double u) {
    return Positioned(
      left: (_paperX - 40) * u,
      width: (_paperW + 80) * u,
      top: -3000 * u,
      height: (_slotY + 3000) * u,
      child: ClipRect(
        child: Stack(children: [
          if (_strip.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 40 * u,
              width: _paperW * u,
              child: Transform.translate(
                offset: _pull,
                child: Transform.rotate(
                  angle: _pull.dx * 0.04 * math.pi / 180,
                  alignment: Alignment.bottomCenter,
                  child: Semantics(
                    button: true,
                    label: 'Receipt. Pull it up, or double tap, to tear it off.',
                    onTap: () => _tear(const Offset(0, -900)),
                    child: GestureDetector(
                      key: const ValueKey('receipt-strip'),
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (_) {
                        _spring.stop();
                        _drag = Offset.zero;
                      },
                      onPanUpdate: _onPull,
                      onPanEnd: _onPullEnd,
                      child: _stripOf(_strip, u),
                    ),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  /// Copies joined end to end, each shown as far as it has printed.
  Widget _stripOf(List<_Copy> copies, double u) {
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: const Color(0x59282319), blurRadius: 24 * u, spreadRadius: -6 * u, offset: Offset(0, 10 * u))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final (i, copy) in copies.indexed)
          AnimatedBuilder(
            animation: copy.feed,
            // only the printed part exists yet; as it grows, everything above it rises out of the slot
            builder: (_, child) => ClipRect(
              child: Align(alignment: Alignment.topCenter, heightFactor: copy.feed.value.clamp(0.0, 1.0), child: child),
            ),
            child: ReceiptPaper(receipt: widget.receipt, u: u, first: i == 0),
          ),
      ]),
    );
  }

  /// The strip that got torn off.
  Widget _flyingStrip(double u) {
    return Positioned(
      left: _paperX * u,
      width: _paperW * u,
      bottom: (_stageH - _slotY) * u,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _fly,
          builder: (_, child) {
            final t = const Cubic(0.2, 0.7, 0.3, 1).transform(_fly.value);
            final lean = _flyFrom.dx * 0.04 + (_flyVelocity.dx * 0.03 + (_flyVelocity.dx >= 0 ? 14 : -14)) * t;
            return Opacity(
              opacity: 1 - Curves.easeIn.transform(_fly.value),
              child: Transform.translate(
                offset: _flyFrom + Offset(_flyVelocity.dx * 0.55 * t, (_flyVelocity.dy * 0.55 - 120) * t),
                child: Transform.rotate(angle: lean * math.pi / 180, alignment: Alignment.bottomCenter, child: child),
              ),
            );
          },
          child: ClipPath(clipper: _TornEdge(12 * u), child: _stripOf(_flying!, u)),
        ),
      ),
    );
  }

  /// The printer, from above.
  Widget _printer(double u) {
    return Positioned(
      left: 20 * u,
      top: 640 * u,
      width: 400 * u,
      height: 240 * u,
      child: Stack(clipBehavior: Clip.none, children: [
        // body
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40 * u),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF6F4EF), Color(0xFFEBE8E1), Color(0xFFDEDAD1)],
                stops: [0, 0.55, 1],
              ),
              border: Border(top: BorderSide(color: const Color(0xE6FFFFFF), width: math.max(1, 1.5 * u))),
              boxShadow: [
                BoxShadow(color: const Color(0x2E3C3228), blurRadius: 3 * u, offset: Offset(0, 2 * u)),
                BoxShadow(color: const Color(0x663C3228), blurRadius: 40 * u, spreadRadius: -8 * u, offset: Offset(10 * u, 26 * u)),
              ],
            ),
          ),
        ),
        // lid seam
        Positioned(
          left: 24 * u,
          right: 24 * u,
          top: 92 * u,
          height: 2 * u,
          child: const DecoratedBox(decoration: BoxDecoration(color: Color(0x40786E5F))),
        ),
        // paper slot
        Positioned(
          left: (_paperX - 20 - 18) * u,
          width: (_paperW + 36) * u,
          top: (_slotY - 640 - 7) * u,
          height: 14 * u,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7 * u),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1B1A18), Color(0xFF3A3833)],
              ),
            ),
          ),
        ),
        // paper lip waiting in the slot
        if (_strip.isEmpty)
          Positioned(
            left: (_paperX - 20) * u,
            width: _paperW * u,
            top: (_slotY - 640 - 9) * u,
            height: 9 * u,
            child: ClipPath(clipper: _Teeth(12 * u), child: const ColoredBox(color: Color(0xFFFBFAF6))),
          ),
        // status light
        Positioned(
          left: 250 * u,
          top: 132 * u,
          child: AnimatedBuilder(
            animation: _blink,
            builder: (_, _) {
              final printing = _phase == _Phase.printing;
              final color = printing ? Color.lerp(const Color(0xFFFFB340), const Color(0xFF7A5310), _blink.value)! : const Color(0xFF4FD27A);
              return Container(
                width: 9 * u,
                height: 9 * u,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [BoxShadow(color: color.withValues(alpha: printing ? 1 - _blink.value : 0.8), blurRadius: 8 * u)],
                ),
              );
            },
          ),
        ),
        // PRINT button
        Positioned(
          left: 300 * u,
          top: 104 * u,
          width: 72 * u,
          height: 72 * u,
          child: Semantics(
            button: true,
            label: 'Print receipt',
            onTap: _pressPrint,
            excludeSemantics: true,
            child: GestureDetector(
              key: const ValueKey('receipt-print'),
              behavior: HitTestBehavior.opaque,
              onTap: _pressPrint,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(center: Alignment(0, -0.1), colors: [Color(0xFF2F2D29), Color(0xFF1A1917)]),
                ),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: 60 * u,
                    height: 60 * u,
                    alignment: Alignment.center,
                    transformAlignment: Alignment.center,
                    transform: _pressed ? (Matrix4.diagonal3Values(0.96, 0.96, 1)..setTranslationRaw(0, 2 * u, 0)) : Matrix4.identity(),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        center: Alignment(-0.24, -0.4),
                        radius: 0.75,
                        colors: [Color(0xFFFF8A7A), Color(0xFFF2392C), Color(0xFFC81D13), Color(0xFF9C140D)],
                        stops: [0, 0.38, 0.75, 1],
                      ),
                      boxShadow: _pressed ? null : [BoxShadow(color: const Color(0x73000000), blurRadius: 6 * u, offset: Offset(0, 4 * u))],
                    ),
                    child: Text(
                      'PRINT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11 * u,
                        letterSpacing: 1.54 * u,
                        height: 1,
                        shadows: [Shadow(color: const Color(0x99640000), blurRadius: u, offset: Offset(0, u))],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // maker's mark
        Positioned(
          left: 34 * u,
          top: 182 * u,
          child: ExcludeSemantics(
            child: Stack(children: [
              Transform.translate(offset: Offset(0, u), child: Text('Yummy Chops', style: _mark(u, const Color(0xE6FFFFFF)))),
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF6B6B70), Color(0xFF1C1C1F), Color(0xFF000000), Color(0xFF0B0B0D), Color(0xFF2A2A2E)],
                  stops: [0, 0.42, 0.5, 0.78, 1],
                ).createShader(bounds),
                child: Text('Yummy Chops', style: _mark(u, Colors.black)),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  TextStyle _mark(double u, Color color) =>
      TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18 * u, letterSpacing: -0.36 * u, height: 1.2);

  /// Serrated tear bar over the slot, above the paper.
  Widget _tearBar(double u) {
    return Positioned(
      left: (_paperX - 22) * u,
      width: (_paperW + 44) * u,
      top: (_slotY - 12) * u,
      height: 7 * u,
      child: IgnorePointer(
        child: ClipPath(
          clipper: _Teeth(6 * u),
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF4F5F7), Color(0xFFA9ADB5), Color(0xFF7C8089)],
                stops: [0, 0.6, 1],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// What to do next: large and dark, so it is easy to see under the printer.
  Widget _hintPill() {
    final hint = _hint;
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: Container(
          key: ValueKey(hint),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF2B2A27),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 16, spreadRadius: -6, offset: Offset(0, 6))],
          ),
          child: Semantics(
            liveRegion: true,
            child: Text(
              hint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5, height: 1.2),
            ),
          ),
        ),
      ),
    );
  }

  /// Sound and vibration on or off.
  Widget _quietButton() {
    return Semantics(
      button: true,
      label: _quiet ? 'Turn sound and vibration on' : 'Turn sound and vibration off',
      child: Material(
        color: const Color(0xB3FFFFFF),
        shape: const CircleBorder(side: BorderSide(color: Color(0x0D000000))),
        elevation: 2,
        child: InkWell(
          key: const ValueKey('receipt-quiet'),
          customBorder: const CircleBorder(),
          onTap: () {
            setState(() => _quiet = !_quiet);
            if (!_quiet) {
              HapticFeedback.mediumImpact();
              SystemSound.play(SystemSoundType.click);
            }
          },
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(_quiet ? Icons.volume_off_rounded : Icons.volume_up_rounded, size: 18, color: const Color(0xFF2B2A27)),
          ),
        ),
      ),
    );
  }
}

/// The whole receipt on thermal paper: printed by [ReceiptPrinter], and shown still under "My receipts".
class ReceiptPaper extends StatelessWidget {
  const ReceiptPaper({super.key, required this.receipt, this.u = 1.12, this.first = false});
  final Receipt receipt;

  /// The size of one design unit in logical pixels (the paper is 300 units wide).
  final double u;

  /// The top end of the strip curls a touch.
  final bool first;

  /// Bars that look like a barcode and are the same every time for the same receipt number.
  static List<int> barsFor(String number) {
    var seed = 7;
    for (final unit in number.codeUnits) {
      seed = (seed * 31 + unit) % 104729;
    }
    return [for (var i = 0; i < 46; i++) ((seed * (i + 7) * 31 + i * i) % 3) + 1];
  }

  @override
  Widget build(BuildContext context) {
    final r = receipt;
    // thermal print is never quite black
    final base = TextStyle(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Courier New', 'Courier', 'Roboto Mono'],
      color: const Color(0xE0262624),
      fontSize: 11.5 * u,
      height: 1.55,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final strong = base.copyWith(fontWeight: FontWeight.w700, fontSize: 14 * u);
    final small = base.copyWith(fontSize: 10 * u, color: const Color(0xB3262624));

    Widget row(String left, [String right = '', TextStyle? style]) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(left, style: style)),
            if (right.isNotEmpty) Padding(padding: EdgeInsets.only(left: 12 * u), child: Text(right, style: style)),
          ],
        );
    final rule = Padding(
      padding: EdgeInsets.symmetric(vertical: 9 * u),
      child: SizedBox(height: 1, width: double.infinity, child: CustomPaint(painter: _Dashes(u))),
    );

    return SizedBox(
      width: _paperW * u,
      child: Stack(children: [
        Container(
          padding: EdgeInsets.fromLTRB(22 * u, 22 * u, 22 * u, 30 * u),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF1F0EB), Color(0xFFFDFDFA), Color(0xFFFDFDFA), Color(0xFFEEEDE8)],
              stops: [0, 0.06, 0.94, 1],
            ),
          ),
          child: DefaultTextStyle(
            style: base,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
              Text(
                r.seller.toUpperCase(),
                textAlign: TextAlign.center,
                style: base.copyWith(fontWeight: FontWeight.w700, fontSize: 17 * u, letterSpacing: 1.36 * u, height: 1.3),
              ),
              if (r.sellerAddress.isNotEmpty) Text(r.sellerAddress, textAlign: TextAlign.center, style: base.copyWith(fontSize: 10.5 * u)),
              rule,
              row('Receipt ${r.number}'),
              row('Order #${r.orderCode}', r.serviceName),
              row(formatLagosDateTime(r.paidAt ?? r.orderedAt)),
              if (r.customerName != null) row(r.customerName!),
              for (final line in r.summary) row(line),
              rule,
              for (final line in r.lines) ...[
                row('${line.quantity} x ${line.name}', formatNaira(line.amountKobo)),
                for (final detail in line.details) Padding(padding: EdgeInsets.only(left: 14 * u), child: Text(detail, style: small)),
              ],
              if (r.lines.isNotEmpty) rule,
              for (final c in r.charges) row(c.label, formatNaira(c.amountKobo)),
              SizedBox(height: 6 * u),
              row('Total paid', formatNaira(r.totalKobo), strong),
              rule,
              row('Paid with'),
              row(r.paidWith),
              if (r.paymentReference != null) row('Ref ${r.paymentReference}'),
              if (r.refundedKobo > 0) row('Refunded', formatNaira(r.refundedKobo)),
              if (r.savingsKobo > 0) row('Saved with Yummy Chops Plus', formatNaira(r.savingsKobo)),
              SizedBox(height: 14 * u),
              SizedBox(
                height: 46 * u,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  for (final (i, w) in barsFor(r.number).indexed)
                    Container(
                      width: w * 1.4 * u,
                      margin: EdgeInsets.symmetric(horizontal: 0.75 * u),
                      color: Color(i % 5 == 0 ? 0xD9262624 : 0xFF262624),
                    ),
                ]),
              ),
              SizedBox(height: 4 * u),
              Text(r.number, textAlign: TextAlign.center, style: base.copyWith(fontSize: 9.5 * u, letterSpacing: 2.85 * u)),
              SizedBox(height: 14 * u),
              Text('THANK YOU', textAlign: TextAlign.center, style: base.copyWith(fontWeight: FontWeight.w700, fontSize: 12 * u, letterSpacing: 2.4 * u)),
              Text('Yummy Chops', textAlign: TextAlign.center, style: base.copyWith(fontSize: 10 * u)),
            ]),
          ),
        ),
        if (first)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 26 * u,
            child: const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x12000000), Color(0x00000000)]),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

/// A row of teeth pointing up (the paper lip in the slot, the serrated tear bar).
class _Teeth extends CustomClipper<Path> {
  const _Teeth(this.tooth);
  final double tooth;

  @override
  Path getClip(Size size) {
    final path = Path()..moveTo(0, size.height);
    for (var x = 0.0; x < size.width; x += tooth) {
      path
        ..lineTo(x + tooth / 2, 0)
        ..lineTo(x + tooth, size.height);
    }
    return path..close();
  }

  @override
  bool shouldReclip(_Teeth old) => old.tooth != tooth;
}

/// Paper torn across the bar: a zigzag bottom edge.
class _TornEdge extends CustomClipper<Path> {
  const _TornEdge(this.tooth);
  final double tooth;

  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - tooth / 2);
    for (var x = size.width; x > 0; x -= tooth) {
      path
        ..lineTo(x - tooth / 2, size.height)
        ..lineTo(x - tooth, size.height - tooth / 2);
    }
    return path..close();
  }

  @override
  bool shouldReclip(_TornEdge old) => old.tooth != tooth;
}

/// A dashed rule between the parts of a receipt.
class _Dashes extends CustomPainter {
  const _Dashes(this.u);
  final double u;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x802A2A2A)
      ..strokeWidth = 1;
    final dash = math.max(2.0, 4 * u);
    for (var x = 0.0; x < size.width; x += dash * 2) {
      canvas.drawLine(Offset(x, 0), Offset(math.min(x + dash, size.width), 0), paint);
    }
  }

  @override
  bool shouldRepaint(_Dashes old) => old.u != u;
}
