import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import '../../ui/plates.dart';

// ================================================================================================
// Dish Orbit Carousel: a Flutter port of the "dish orbit" kitchen-display carousel (React + GSAP).
// The plated dish sits centre stage; changing dish swings it out over the top on a wide orbit while
// the next plate swings in from the other side. The two-weight title wipes out and back in (thin line
// from the right, heavy line from the left), the kitchen card and its coloured rating badge
// cross-fade, and a pastel arc behind the scene stretches along the orbit and takes the dish's colour.
// Swipes, the side pager, arrow keys and a gentle auto-play move it; reduced motion swaps instantly.
// Timings and eases mirror the original timeline (GSAP power2 = cubic, power3 = quartic).
// ================================================================================================

// ------------------------------------------------------------------ pure helpers (unit tested)
int wrapIndex(int i, int n) => n <= 0 ? 0 : ((i % n) + n) % n;

/// Which way to swing when jumping from one dish to another: the shorter way round (1 = forwards).
int stepDirection(int from, int to, int n) {
  if (n <= 0) return 1;
  final forward = ((to - from) % n + n) % n;
  return forward <= n - forward ? 1 : -1;
}

/// Title font size so a line of [chars] characters fits [width] at [em] average glyph width.
double fitSize(int chars, double max, double width, double em) => math.min(max, width / (math.max(1, chars) * em));

/// The pastel band: a thick stroke along the plates' orbit circle, tapering at both ends.
/// Angles in degrees, screen space (0 = right, 90 = straight down).
Path arcPath(double a0, double a1, double cx, double cy, double r, double w, {int steps = 48}) {
  final outer = <Offset>[];
  final inner = <Offset>[];
  for (var i = 0; i <= steps; i++) {
    final t = i / steps;
    final a = (a0 + (a1 - a0) * t) * math.pi / 180;
    final h = (w / 2) * math.pow(math.sin(math.pi * t), 0.45).toDouble();
    final cs = math.cos(a);
    final sn = math.sin(a);
    outer.add(Offset(cx + cs * (r + h), cy + sn * (r + h)));
    inner.add(Offset(cx + cs * (r - h), cy + sn * (r - h)));
  }
  final p = Path()..moveTo(outer.first.dx, outer.first.dy);
  for (final o in outer.skip(1)) {
    p.lineTo(o.dx, o.dy);
  }
  for (final o in inner.reversed) {
    p.lineTo(o.dx, o.dy);
  }
  return p..close();
}

/// Where the band rests for each dish, as [start, end] angles along the orbit.
const arcRestAngles = <List<double>>[
  [50, 98],
  [46, 124],
  [60, 126],
  [40, 100],
];
List<double> arcRest(int index) => arcRestAngles[wrapIndex(index, arcRestAngles.length)];

/// The band mid-swap: it stretches to trail between the outgoing and incoming plate.
const arcSweep = <double>[38, 146];

/// Pastel accents for the rating badge and the band, one per dish position.
const dishAccents = [Color(0xFFF6A37C), Color(0xFFF2A6C6), Color(0xFFBCD98E), Color(0xFFF5D26A), Color(0xFF9FCBE8)];
Color accentFor(int index) => dishAccents[wrapIndex(index, dishAccents.length)];

/// Splits a dish name into the thin first line and the heavy second line ("PARTY" / "JOLLOF RICE").
/// Drops portion notes in brackets, balances the two lines, never starts the heavy line with "&".
({String thin, String heavy}) splitTitle(String name) {
  final clean = name.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
  final words = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.length < 2) return (thin: '', heavy: clean);
  const connectors = {'&', 'and', 'with', '+', 'n'};
  String? thin;
  String? heavy;
  var best = 1 << 30;
  for (var k = 1; k < words.length; k++) {
    if (connectors.contains(words[k].toLowerCase())) continue;
    final a = words.sublist(0, k).join(' ').replaceAll(RegExp(r',$'), '');
    final b = words.sublist(k).join(' ');
    final score = math.max(a.length, b.length);
    if (score <= best) {
      // ties go to the later split: a shorter heavy line reads bigger
      best = score;
      thin = a;
      heavy = b;
    }
  }
  return (thin: thin ?? words.first, heavy: heavy ?? words.skip(1).join(' '));
}

// The plates' orbit, in the 960 × 520 design canvas of the original (pivot far above the canvas).
const _orbitX = 299.0;
const _orbitY = -450.0;
const _orbitR = 650.0;
const _bandWidth = 118.0;
const _swingDegrees = 50.0;

/// CSS `transform-origin: 69% -217%` as a Flutter alignment (the pivot sits ~2 plates above).
const _pivot = Alignment(0.38, -5.34);

/// Timeline length in seconds (the last tween ends at 1.45 s).
const _timeline = 1.45;

double _seg(double t, double start, double duration, Curve curve) =>
    curve.transform(((t - start) / duration).clamp(0.0, 1.0));

// ------------------------------------------------------------------------------------- widget
class DishOrbitCarousel extends StatefulWidget {
  const DishOrbitCarousel({
    super.key,
    required this.dishes,
    this.onOrder,
    this.onAskGudy,
    this.onChanged,
    this.autoPlay = const Duration(seconds: 6),
  });

  final List<DiscoverDish> dishes;

  /// "Order food" (and tapping the plate).
  final ValueChanged<DiscoverDish>? onOrder;

  /// "Ask Yummy" about this dish.
  final ValueChanged<DiscoverDish>? onAskGudy;
  final ValueChanged<int>? onChanged;

  /// Moves to the next dish on its own every so often; null turns it off. Pauses after a touch.
  final Duration? autoPlay;

  @override
  State<DishOrbitCarousel> createState() => DishOrbitCarouselState();
}

typedef _Shown = ({DiscoverDish dish, int position});

class DishOrbitCarouselState extends State<DishOrbitCarousel> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: Duration(milliseconds: (_timeline * 1000).round()), value: 1);
  int _index = 0;
  _Shown? _out; // the dish swinging away, while a swap runs
  int _dir = 1;
  bool _ingredients = false;
  final _liked = <DiscoverDish>{};
  final _disliked = <DiscoverDish>{};
  Timer? _timer;
  DateTime _holdUntil = DateTime.fromMillisecondsSinceEpoch(0);
  double _dragDx = 0;
  List<double> _bandFrom = arcRest(0);
  Color _tintFrom = accentFor(0);
  bool _reduceMotion = false;
  bool _onScreen = true;

  int get index => _index;
  List<DiscoverDish> get _dishes => widget.dishes;
  DiscoverDish get _dish => _dishes[wrapIndex(_index, _dishes.length)];

  @override
  void initState() {
    super.initState();
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed && _out != null && mounted) setState(() => _out = null);
    });
    _restartTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _onScreen = TickerMode.valuesOf(context).enabled; // false while another bottom-bar tab is showing
  }

  @override
  void didUpdateWidget(covariant DishOrbitCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.autoPlay != widget.autoPlay) _restartTimer();
    if (listEquals(oldWidget.dishes, widget.dishes)) return;
    // A different list (another section): the current plate swings away and the new first dish swings in.
    final previous = oldWidget.dishes.isEmpty ? null : oldWidget.dishes[wrapIndex(_index, oldWidget.dishes.length)];
    final previousPosition = _index;
    _index = 0;
    if (previous == null || widget.dishes.isEmpty || previous == widget.dishes.first || _reduceMotion) {
      _out = null;
      _ctrl.value = 1;
      return;
    }
    _bandFrom = arcRest(previousPosition);
    _tintFrom = accentFor(previousPosition);
    _out = (dish: previous, position: previousPosition);
    _dir = 1;
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    final every = widget.autoPlay;
    if (every == null) return;
    _timer = Timer.periodic(every, (_) {
      if (!mounted || _reduceMotion || !_onScreen || _dishes.length < 2 || _ctrl.isAnimating) return;
      if (DateTime.now().isBefore(_holdUntil)) return;
      _swapTo(wrapIndex(_index + 1, _dishes.length), 1);
    });
  }

  /// A person touched the carousel: hold the auto-play for a while.
  void _hold() => _holdUntil = DateTime.now().add(const Duration(seconds: 12));

  /// Jump to dish [to] (wrapping), swinging the short way round unless [dir] says otherwise.
  void go(int to, {int? dir}) {
    final n = _dishes.length;
    if (n < 2) return;
    final next = wrapIndex(to, n);
    if (next == _index) return;
    _hold();
    _swapTo(next, dir ?? stepDirection(_index, next, n));
  }

  void step(int d) => go(_index + d, dir: d);

  void _swapTo(int next, int dir) {
    setState(() {
      // Like GSAP's progress(1).kill(): an interrupted swap snaps to its end before the next one starts.
      _bandFrom = arcRest(_index);
      _tintFrom = accentFor(_index);
      _out = (dish: _dish, position: _index);
      _index = next;
      _dir = dir;
      _ingredients = _ingredients && _dish.highlights.isNotEmpty;
    });
    widget.onChanged?.call(next);
    if (_reduceMotion) {
      _ctrl.value = 1;
      setState(() => _out = null);
    } else {
      _ctrl.forward(from: 0);
    }
  }

  ({double a0, double a1, Color tint}) _band(double t) {
    final rest = arcRest(_index);
    final to = accentFor(_index);
    if (_out == null) return (a0: rest[0], a1: rest[1], tint: to);
    final double a0;
    final double a1;
    if (t < 0.6) {
      final p = _seg(t, 0, 0.6, Curves.easeInOutCubic);
      a0 = lerpDouble(_bandFrom[0], arcSweep[0], p)!;
      a1 = lerpDouble(_bandFrom[1], arcSweep[1], p)!;
    } else {
      final p = _seg(t, 0.6, 0.85, Curves.easeOutQuart);
      a0 = lerpDouble(arcSweep[0], rest[0], p)!;
      a1 = lerpDouble(arcSweep[1], rest[1], p)!;
    }
    return (a0: a0, a1: a1, tint: Color.lerp(_tintFrom, to, _seg(t, 0.1, 1.1, Curves.easeInOutQuad))!);
  }

  @override
  Widget build(BuildContext context) {
    if (_dishes.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth.isFinite ? box.maxWidth : MediaQuery.sizeOf(context).width;
      final plate = (w * 0.52).clamp(150.0, 250.0);
      const plateTop = 40.0;
      return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowRight): () => step(1),
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () => step(-1),
        },
        child: Focus(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final t = _ctrl.value * _timeline;
              final band = _band(t);
              return Semantics(
                container: true,
                label: 'Featured dishes',
                child: ClipRect(
                  child: Stack(children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _BandPainter(
                          a0: band.a0,
                          a1: band.a1,
                          tint: band.tint,
                          // a pastel at 34% turns muddy on a dark background; it needs more body there
                          opacity: Theme.of(context).brightness == Brightness.dark ? .5 : .34,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, plateTop, 16, 18),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        _stage(plate, t),
                        const SizedBox(height: 10),
                        _heads(w - 72, t),
                        _actions(context, t),
                        const SizedBox(height: 12),
                        _card(context, t),
                        // announces the dish for screen readers without showing anything
                        Semantics(
                          liveRegion: true,
                          label: 'Dish ${_index + 1} of ${_dishes.length}: ${_dish.name} from ${_dish.restaurantName}',
                          child: const SizedBox.shrink(),
                        ),
                      ]),
                    ),
                    if (_dishes.length > 1) Positioned(left: 6, top: plateTop + plate / 2 - 8, child: _pager(context)),
                  ]),
                ),
              );
            },
          ),
        ),
      );
    });
  }

  // -------------------------------------------------------------------- plates on the orbit
  Widget _stage(double size, double t) {
    final out = _out;
    final plates = <Widget>[];
    if (out != null && t < 0.62) {
      final angle = _swingDegrees * _dir * _seg(t, 0, 0.62, Curves.easeInCubic);
      plates.add(_orbiting(out.dish, size, angle, key: const ValueKey('out')));
    }
    if (out == null || t >= 0.3) {
      final angle = out == null ? 0.0 : -_swingDegrees * _dir * (1 - _seg(t, 0.3, 0.95, Curves.easeOutQuart));
      plates.add(_orbiting(_dish, size, angle, key: const ValueKey('in')));
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onOrder == null ? null : () => widget.onOrder!(_dish),
      onHorizontalDragStart: (_) {
        _dragDx = 0;
        _hold();
      },
      onHorizontalDragUpdate: (d) => _dragDx += d.delta.dx,
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        final dx = _dragDx != 0 ? _dragDx : v;
        if (_dragDx.abs() > 40 || v.abs() > 450) step(dx < 0 ? 1 : -1);
      },
      child: SizedBox.square(
        dimension: size,
        child: Stack(clipBehavior: Clip.none, children: plates),
      ),
    );
  }

  Widget _orbiting(DiscoverDish dish, double size, double degrees, {required Key key}) => Transform.rotate(
        key: key,
        angle: degrees * math.pi / 180,
        alignment: _pivot,
        child: RepaintBoundary(child: DishPlate(dish: dish, size: size)),
      );

  // -------------------------------------------------------------------- two-weight title
  Widget _heads(double width, double t) {
    final out = _out;
    final showOut = out != null && t < 0.5;
    // Tall enough for both lines at full size; grows (never overflows) with large accessibility text.
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: double.infinity, minHeight: 122),
      child: Stack(alignment: Alignment.topCenter, children: [
        if (showOut)
          _head(
            out.dish,
            width,
            eyebrowOpacity: 1 - _seg(t, 0, 0.25, Curves.easeOutQuad),
            eyebrowDy: 0,
            thinHide: _seg(t, 0, 0.42, Curves.easeInCubic),
            heavyHide: _seg(t, 0.06, 0.42, Curves.easeInCubic),
          )
        else
          _head(
            _dish,
            width,
            eyebrowOpacity: out == null ? 1 : _seg(t, 0.55, 0.4, Curves.easeOutCubic),
            eyebrowDy: out == null ? 0 : 6 * (1 - _seg(t, 0.55, 0.4, Curves.easeOutCubic)),
            thinHide: out == null ? 0 : 1 - _seg(t, 0.55, 0.7, Curves.easeOutQuart),
            heavyHide: out == null ? 0 : 1 - _seg(t, 0.62, 0.7, Curves.easeOutQuart),
          ),
      ]),
    );
  }

  Widget _head(DiscoverDish dish, double width,
      {required double eyebrowOpacity, required double eyebrowDy, required double thinHide, required double heavyHide}) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final title = splitTitle(dish.name);
    final thin = title.thin.toUpperCase();
    final heavy = title.heavy.toUpperCase();
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Opacity(
        opacity: eyebrowOpacity,
        child: Transform.translate(
          offset: Offset(0, eyebrowDy),
          child: Text(dish.eyebrow, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: ink, letterSpacing: .1)),
        ),
      ),
      if (thin.isNotEmpty)
        // thin line: clips away to the right, wipes back in from the right
        ClipRect(
          clipper: _InsetClipper(left: thinHide),
          child: _fitted(width, thin, TextStyle(fontSize: fitSize(thin.length, 44, width, 0.6), fontWeight: FontWeight.w200, height: 1, letterSpacing: -.5, color: ink)),
        ),
      const SizedBox(height: 4),
      // heavy line: clips away to the left, wipes back in from the left
      ClipRect(
        clipper: _InsetClipper(right: heavyHide),
        child: _fitted(width, heavy, TextStyle(fontSize: fitSize(heavy.length, 48, width, 0.7), fontWeight: FontWeight.w800, height: 1, letterSpacing: -1, color: ink.withValues(alpha: .86))),
      ),
    ]);
  }

  Widget _fitted(double width, String text, TextStyle style) => SizedBox(
        width: width,
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(text, maxLines: 1, softWrap: false, style: style)),
      );

  // -------------------------------------------------------------------- actions
  /// The dish whose title is on screen: mid-swap the outgoing title stays up until 0.5 s.
  DiscoverDish _titled(double t) {
    final out = _out;
    return out != null && t < 0.5 ? out.dish : _dish;
  }

  Widget _actions(BuildContext context, double t) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final style = TextButton.styleFrom(
      foregroundColor: ink,
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );
    // The buttons (and the price) follow the title, so they always talk about the dish being shown.
    final dish = _titled(t);
    return Wrap(alignment: WrapAlignment.center, spacing: 28, children: [
      if (widget.onAskGudy != null)
        TextButton.icon(
          style: style,
          onPressed: () => widget.onAskGudy!(dish),
          icon: const Icon(Icons.auto_awesome_rounded, size: 16),
          label: const Text('Ask Yummy'),
        ),
      if (widget.onOrder != null)
        TextButton.icon(
          style: style,
          onPressed: () => widget.onOrder!(dish),
          icon: const Icon(Icons.eject_rounded, size: 18),
          label: Text('Order food · ${formatNaira(dish.priceKobo)}'),
        ),
    ]);
  }

  // -------------------------------------------------------------------- kitchen card
  Widget _card(BuildContext context, double t) {
    final theme = Theme.of(context);
    final out = _out;
    final outFade = out == null ? 1.0 : _seg(t, 0.05, 0.3, Curves.easeInQuad);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: .72),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: .06)),
              boxShadow: const [BoxShadow(color: Color(0x2E000000), blurRadius: 40, offset: Offset(0, 18), spreadRadius: -24)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _tabs(theme),
              const SizedBox(height: 14),
              Stack(children: [
                if (out != null && outFade < 1)
                  Opacity(
                    opacity: 1 - outFade,
                    child: Transform.translate(offset: Offset(0, -6 * outFade), child: _body(out.dish, out.position, 1)),
                  ),
                if (out == null || t >= 0.4) _body(_dish, _index, out == null ? null : t),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _tabs(ThemeData theme) {
    Widget tab(String label, bool selected, VoidCallback onTap) => Semantics(
          selected: selected,
          button: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Text(label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                  )),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        tab('Overview', !_ingredients, () => setState(() => _ingredients = false)),
        tab('Ingredients', _ingredients, () => setState(() => _ingredients = true)),
      ]),
    );
  }

  /// The card's rows; while a swap runs ([t] non-null) they rise in one after another.
  Widget _body(DiscoverDish dish, int position, double? t) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    Widget rise(int k, Widget child) {
      if (t == null) return child;
      final p = _seg(t, 0.4 + 0.06 * k, 0.5, Curves.easeOutCubic);
      return Opacity(opacity: p, child: Transform.translate(offset: Offset(0, 10 * (1 - p)), child: child));
    }

    final details = [
      if (dish.area.isNotEmpty) dish.area,
      if (!dish.isOpen) 'Closed now' else if (!dish.isAcceptingOrders) 'Paused',
      if (!dish.isAvailable) 'Sold out',
      if (dish.etaMinutes != null && dish.isOpen) '${dish.etaMinutes} min',
      if (dish.deliveryFeeKobo != null) '${formatNaira(dish.deliveryFeeKobo!)} delivery',
    ].join(' · ');
    final liked = _liked.contains(dish);
    final disliked = _disliked.contains(dish);
    final showIngredients = _ingredients && dish.highlights.isNotEmpty;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      rise(0, _RatingBadge(rating: dish.rating, accent: accentFor(position))),
      const SizedBox(height: 14),
      rise(1, Text(dish.restaurantName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -.2))),
      const SizedBox(height: 3),
      rise(2, Text(details, style: TextStyle(fontSize: 11.5, color: muted))),
      const SizedBox(height: 12),
      rise(
        3,
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: showIngredients
              ? Wrap(spacing: 5, runSpacing: 5, children: [
                  for (final h in dish.highlights)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(color: theme.colorScheme.onSurface.withValues(alpha: .07), borderRadius: BorderRadius.circular(99)),
                      child: Text(h, style: const TextStyle(fontSize: 11.5)),
                    ),
                ])
              : Text(
                  dish.description.isEmpty ? '${dish.name}, freshly made by ${dish.restaurantName}.' : dish.description,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, height: 1.38),
                ),
        ),
      ),
      const SizedBox(height: 16),
      rise(
        4,
        Row(children: [
          Semantics(
            button: true,
            toggled: liked,
            label: 'Like ${dish.name}',
            child: Material(
              color: theme.colorScheme.onSurface.withValues(alpha: .06),
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => setState(() {
                  if (!_liked.remove(dish)) _liked.add(dish);
                  _disliked.remove(dish);
                }),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(liked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined, size: 16),
                    const SizedBox(width: 8),
                    Text('${_compact(dish.likes + (liked ? 1 : 0))} orders', style: const TextStyle(fontSize: 11.5)),
                  ]),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            button: true,
            toggled: disliked,
            label: 'Not for me',
            child: Material(
              color: theme.colorScheme.onSurface.withValues(alpha: .06),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => setState(() {
                  if (!_disliked.remove(dish)) _disliked.add(dish);
                  _liked.remove(dish);
                }),
                child: Padding(
                  padding: const EdgeInsets.all(9),
                  child: Icon(disliked ? Icons.thumb_down_alt_rounded : Icons.thumb_down_alt_outlined, size: 16),
                ),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }

  // -------------------------------------------------------------------- side pager
  Widget _pager(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final morph = _reduceMotion ? Duration.zero : const Duration(milliseconds: 450);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < _dishes.length; i++)
        Semantics(
          button: true,
          selected: i == _index,
          label: 'Dish ${i + 1}: ${_dishes[i].name}',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => go(i),
            child: AnimatedContainer(
              duration: morph,
              curve: const Cubic(.3, .7, .2, 1),
              width: 20,
              height: i == _index ? 30 : 14,
              alignment: Alignment.center,
              child: AnimatedContainer(
                duration: morph,
                curve: const Cubic(.3, .7, .2, 1),
                width: 3,
                height: i == _index ? 22 : 3,
                decoration: BoxDecoration(color: ink.withValues(alpha: i == _index ? .9 : .45), borderRadius: BorderRadius.circular(3)),
              ),
            ),
          ),
        ),
    ]);
  }
}

String _compact(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1)}k' : '$n';

/// The coloured rating badge with the big number overlapping it.
class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating, required this.accent});
  final double rating;
  final Color accent;

  static const _badge = Rect.fromLTWH(6, 0, 46, 62);
  static const _darkInk = Color(0xFF1F1F1F);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final style = TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1.5, height: 1, color: ink);
    final number = rating.toStringAsFixed(1);
    return Semantics(
      label: 'Kitchen rated $number out of 5',
      excludeSemantics: true,
      child: SizedBox(
        height: 62,
        width: 120,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned.fromRect(
            rect: _badge,
            child: Container(
              decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(10)),
              alignment: const Alignment(0, .78),
              child: const Icon(Icons.star_rounded, size: 14, color: Color(0xCC1F1F1F)),
            ),
          ),
          Positioned(left: 16, top: 2, child: Text(number, style: style)),
          // Dark theme: light ink vanishes on the pastel badge, so redraw the number in dark ink where it
          // overlaps the badge (light over the card, dark over the badge).
          if (theme.brightness == Brightness.dark)
            Positioned.fill(
              child: ClipRect(
                clipper: const _RectClipper(_badge),
                child: Stack(clipBehavior: Clip.none, children: [
                  Positioned(left: 16, top: 2, child: Text(number, style: style.copyWith(color: _darkInk))),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}

/// Clips to a fixed rectangle in the child's coordinates.
class _RectClipper extends CustomClipper<Rect> {
  const _RectClipper(this.rect);
  final Rect rect;

  @override
  Rect getClip(Size size) => rect;

  @override
  bool shouldReclip(_RectClipper old) => old.rect != rect;
}

/// Clips [left] / [right] fractions away (CSS `clip-path: inset(...)`), for the title wipes.
class _InsetClipper extends CustomClipper<Rect> {
  const _InsetClipper({this.left = 0, this.right = 0});
  final double left;
  final double right;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(size.width * left, -8, size.width * (1 - right), size.height + 8);

  @override
  bool shouldReclip(_InsetClipper old) => old.left != left || old.right != right;
}

/// The pastel arc behind the plate, in the phone layout of the original: the 960 × 520 design canvas
/// drawn at twice the width, shifted 60% to the left and 30 px up.
class _BandPainter extends CustomPainter {
  const _BandPainter({required this.a0, required this.a1, required this.tint, this.opacity = .34});
  final double a0;
  final double a1;
  final Color tint;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    canvas.save();
    canvas.translate(-0.6 * w, -30);
    canvas.scale(2 * w / 960);
    canvas.drawPath(arcPath(a0, a1, _orbitX, _orbitY, _orbitR, _bandWidth), Paint()..color = tint.withValues(alpha: opacity));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BandPainter old) => old.a0 != a0 || old.a1 != a1 || old.tint != tint || old.opacity != opacity;
}
