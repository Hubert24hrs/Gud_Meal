import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'illustrations.dart';

/// Gudy's face: the blue robot, blinking every few seconds (static when reduced motion is requested).
class GudyAvatar extends StatefulWidget {
  const GudyAvatar({super.key, this.size = 56, this.pulse = false});
  final double size;
  final bool pulse;

  @override
  State<GudyAvatar> createState() => _GudyAvatarState();
}

class _GudyAvatarState extends State<GudyAvatar> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600));
  bool _reduce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_reduce) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Gudy, your Gud Meal assistant',
      image: true,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          // blink twice per cycle, quickly
          final blink = (t > .46 && t < .5) || (t > .9 && t < .94) ? .1 : 1.0;
          final ring = widget.pulse && !_reduce ? (t * 2) % 1 : 0.0;
          return CustomPaint(size: Size.square(widget.size), painter: RobotPainter(eyeOpen: blink, ring: ring));
        },
      ),
    );
  }
}

/// Floating, draggable Gudy button shown on every tab. Snaps to the nearest side when released.
class GudyFab extends StatefulWidget {
  const GudyFab({super.key, required this.onOpen, required this.bounds, this.bottomInset = 12});
  final VoidCallback onOpen;

  /// The area the button may move in (the tab content above the bottom bar).
  final Size bounds;
  final double bottomInset;

  @override
  State<GudyFab> createState() => _GudyFabState();
}

class _GudyFabState extends State<GudyFab> with SingleTickerProviderStateMixin {
  static const _size = 62.0;
  Offset? _pos;
  late final AnimationController _snap = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  Animation<Offset>? _anim;
  bool _dragging = false;
  bool _hint = true;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    _snap.addListener(() => setState(() => _pos = _anim?.value ?? _pos));
    _hintTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _hint = false);
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _snap.dispose();
    super.dispose();
  }

  Offset _clamp(Offset p, Size s, EdgeInsets pad) => Offset(
        p.dx.clamp(8, math.max(8, s.width - _size - 8)).toDouble(),
        p.dy.clamp(pad.top + 8, math.max(pad.top + 8, s.height - _size - widget.bottomInset)).toDouble(),
      );

  void _settle(Size s, EdgeInsets pad) {
    final p = _pos!;
    final toLeft = p.dx + _size / 2 < s.width / 2;
    final end = _clamp(Offset(toLeft ? 12 : s.width - _size - 12, p.dy), s, pad);
    _anim = Tween(begin: p, end: end).animate(CurvedAnimation(parent: _snap, curve: Curves.easeOutBack));
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      setState(() => _pos = end);
    } else {
      _snap.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = widget.bounds;
    final pos = _pos ??= Offset(size.width - _size - 14, size.height - _size - widget.bottomInset - 16);
    final onRight = pos.dx > size.width / 2;
    final hint = Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(14),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text('Hi, I’m Gudy!', maxLines: 1, softWrap: false, style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF202521))),
      ),
    );
    // The button stays exactly at [pos]; the greeting floats beside it (towards the middle of the screen).
    return Positioned(
      left: pos.dx,
      top: pos.dy,
      width: _size,
      height: _size,
      child: Stack(clipBehavior: Clip.none, children: [
        if (_hint && !_dragging)
          Positioned(
            top: 12,
            right: onRight ? _size + 8 : null,
            left: onRight ? null : _size + 8,
            child: IgnorePointer(child: hint),
          ),
        GestureDetector(
          key: const ValueKey('gudy-fab'),
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onOpen();
          },
          onPanStart: (_) {
            _snap.stop();
            setState(() {
              _dragging = true;
              _hint = false;
            });
          },
          onPanUpdate: (d) => setState(() => _pos = _clamp(_pos! + d.delta, size, mq.padding)),
          onPanEnd: (_) {
            setState(() => _dragging = false);
            _settle(size, mq.padding);
          },
          child: Tooltip(
            message: 'Chat with Gudy',
            child: AnimatedScale(
              scale: _dragging ? 1.12 : 1,
              duration: const Duration(milliseconds: 160),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: RobotPainter.blue.withValues(alpha: .35), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: const GudyAvatar(size: _size, pulse: true),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
