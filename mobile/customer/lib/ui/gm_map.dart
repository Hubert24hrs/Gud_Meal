import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:gud_meal_core/gud_meal_core.dart';

/// Google map tiles are shown only in builds made with `--dart-define=MAPS_ENABLED=true` and a restricted key:
/// the Android/iOS app key from the platform config, or `--dart-define=MAPS_BROWSER_KEY=...` on the web (see
/// docs/GOOGLE_MAPS.md). Otherwise the same pins and route are drawn as a schematic map, so every screen works
/// without a key.
const mapsEnabled = bool.fromEnvironment('MAPS_ENABLED');

/// Whether Google tiles can be drawn right now. On the web, main.dart sets it once the Maps script has loaded.
bool googleMapsReady = mapsEnabled && !kIsWeb;

enum PinKind { kitchen, home, rider, place, you }

class MapPin {
  const MapPin(this.point, this.kind, {this.id, this.label});
  final GeoPoint point;
  final PinKind kind;
  final String? id;
  final String? label;
}

IconData _icon(PinKind k) => switch (k) {
      PinKind.kitchen => Icons.storefront_rounded,
      PinKind.home => Icons.home_rounded,
      PinKind.rider => Icons.delivery_dining_rounded,
      PinKind.place => Icons.restaurant_rounded,
      PinKind.you => Icons.my_location_rounded,
    };

Color _color(PinKind k, ColorScheme c) => switch (k) {
      PinKind.kitchen || PinKind.place => c.primary,
      PinKind.home || PinKind.you => c.secondary,
      PinKind.rider => const Color(0xFF2D6AA6),
    };

String _kindName(PinKind k) => switch (k) {
      PinKind.kitchen => 'kitchen',
      PinKind.home => 'delivery address',
      PinKind.rider => 'rider',
      PinKind.place => 'place',
      PinKind.you => 'you',
    };

/// A map of pins and an optional route line.
class GmMap extends StatelessWidget {
  const GmMap({
    super.key,
    required this.pins,
    this.route = const [],
    this.height = 220,
    this.onPinTap,
    this.connectKitchenToHome = true,
    this.onPinMoved,
    this.selectedId,
  });

  final List<MapPin> pins;

  /// Decoded route (Google polyline). Without one, a dashed straight line joins kitchen and home.
  final List<GeoPoint> route;
  final double height;
  final ValueChanged<String>? onPinTap;
  final bool connectKitchenToHome;

  /// Google maps only: lets the user drag the home pin to their exact door.
  final ValueChanged<GeoPoint>? onPinMoved;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final label = 'Map showing ${pins.map((p) => p.label ?? _kindName(p.kind)).join(', ')}';
    return Semantics(
      label: label,
      container: true,
      child: SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: googleMapsReady
              ? _GoogleMapView(pins: pins, route: route, onPinTap: onPinTap, onPinMoved: onPinMoved)
              : SchematicMap(
                  pins: pins,
                  route: route,
                  onPinTap: onPinTap,
                  connectKitchenToHome: connectKitchenToHome,
                  selectedId: selectedId,
                ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------------------------------ Google tiles
class _GoogleMapView extends StatefulWidget {
  const _GoogleMapView({required this.pins, required this.route, this.onPinTap, this.onPinMoved});
  final List<MapPin> pins;
  final List<GeoPoint> route;
  final ValueChanged<String>? onPinTap;
  final ValueChanged<GeoPoint>? onPinMoved;

  @override
  State<_GoogleMapView> createState() => _GoogleMapViewState();
}

class _GoogleMapViewState extends State<_GoogleMapView> {
  gm.GoogleMapController? _controller;

  static gm.LatLng _ll(GeoPoint p) => gm.LatLng(p.lat, p.lng);

  double _hue(PinKind k) => switch (k) {
        PinKind.kitchen || PinKind.place => gm.BitmapDescriptor.hueOrange,
        PinKind.home || PinKind.you => gm.BitmapDescriptor.hueGreen,
        PinKind.rider => gm.BitmapDescriptor.hueAzure,
      };

  void _fit() {
    final points = [...widget.pins.map((p) => p.point), ...widget.route];
    if (_controller == null || points.isEmpty) return;
    if (points.length == 1) {
      _controller!.moveCamera(gm.CameraUpdate.newLatLngZoom(_ll(points.first), 15.5));
      return;
    }
    final b = _bounds(points);
    _controller!.moveCamera(gm.CameraUpdate.newLatLngBounds(
      gm.LatLngBounds(southwest: gm.LatLng(b.minLat, b.minLng), northeast: gm.LatLng(b.maxLat, b.maxLng)),
      48,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final first = widget.pins.isNotEmpty ? widget.pins.first.point : const GeoPoint(lat: 6.5244, lng: 3.3792);
    return gm.GoogleMap(
      initialCameraPosition: gm.CameraPosition(target: _ll(first), zoom: 13),
      onMapCreated: (c) {
        _controller = c;
        WidgetsBinding.instance.addPostFrameCallback((_) => _fit());
      },
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      markers: {
        for (final (i, p) in widget.pins.indexed)
          gm.Marker(
            markerId: gm.MarkerId(p.id ?? '${p.kind.name}-$i'),
            position: _ll(p.point),
            infoWindow: gm.InfoWindow(title: p.label ?? _kindName(p.kind)),
            icon: gm.BitmapDescriptor.defaultMarkerWithHue(_hue(p.kind)),
            draggable: widget.onPinMoved != null && p.kind == PinKind.home,
            onDragEnd: (ll) => widget.onPinMoved?.call(GeoPoint(lat: ll.latitude, lng: ll.longitude)),
            onTap: p.id == null ? null : () => widget.onPinTap?.call(p.id!),
          ),
      },
      polylines: {
        if (widget.route.length >= 2)
          gm.Polyline(
            polylineId: const gm.PolylineId('route'),
            points: [for (final p in widget.route) _ll(p)],
            width: 5,
            color: Theme.of(context).colorScheme.primary,
          ),
      },
    );
  }
}

// ------------------------------------------------------------------------------------------ schematic map
class _Bounds {
  const _Bounds(this.minLat, this.maxLat, this.minLng, this.maxLng);
  final double minLat, maxLat, minLng, maxLng;
}

_Bounds _bounds(List<GeoPoint> points) {
  var minLat = points.first.lat, maxLat = minLat, minLng = points.first.lng, maxLng = minLng;
  for (final p in points) {
    minLat = math.min(minLat, p.lat);
    maxLat = math.max(maxLat, p.lat);
    minLng = math.min(minLng, p.lng);
    maxLng = math.max(maxLng, p.lng);
  }
  return _Bounds(minLat, maxLat, minLng, maxLng);
}

/// Projects coordinates into a box (equirectangular, north up, aspect kept). Not to scale between screens.
class MapProjection {
  MapProjection(List<GeoPoint> points, Size size, {double padding = 36}) {
    final b = _bounds(points.isEmpty ? const [GeoPoint(lat: 6.5244, lng: 3.3792)] : points);
    _midLat = (b.minLat + b.maxLat) / 2;
    final k = math.cos(_midLat * math.pi / 180);
    // At least ~1.2 km across so single pins and close pairs don't fill the whole box.
    final spanX = math.max((b.maxLng - b.minLng) * k, 0.011);
    final spanY = math.max(b.maxLat - b.minLat, 0.011);
    final w = math.max(size.width - padding * 2, 1.0), h = math.max(size.height - padding * 2, 1.0);
    _scale = math.min(w / spanX, h / spanY);
    _cx = ((b.minLng + b.maxLng) / 2) * k;
    _cy = (b.minLat + b.maxLat) / 2;
    _k = k;
    _center = Offset(size.width / 2, size.height / 2);
  }

  late final double _midLat, _scale, _cx, _cy, _k;
  late final Offset _center;

  Offset toScreen(GeoPoint p) => _center + Offset((p.lng * _k - _cx) * _scale, -(p.lat - _cy) * _scale);
}

class SchematicMap extends StatelessWidget {
  const SchematicMap({
    super.key,
    required this.pins,
    this.route = const [],
    this.onPinTap,
    this.connectKitchenToHome = true,
    this.selectedId,
  });

  final List<MapPin> pins;
  final List<GeoPoint> route;
  final ValueChanged<String>? onPinTap;
  final bool connectKitchenToHome;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, box) {
      final size = Size(box.maxWidth, box.maxHeight);
      final projection = MapProjection([...pins.map((p) => p.point), ...route], size);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: onPinTap == null
            ? null
            : (d) {
                MapPin? best;
                var bestDist = 28.0;
                for (final p in pins) {
                  if (p.id == null) continue;
                  final dist = (projection.toScreen(p.point) - d.localPosition).distance;
                  if (dist < bestDist) {
                    best = p;
                    bestDist = dist;
                  }
                }
                if (best != null) onPinTap!(best.id!);
              },
        child: Stack(children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _SchematicPainter(
                pins: pins,
                route: route,
                projection: projection,
                scheme: scheme,
                connect: connectKitchenToHome,
                selectedId: selectedId,
                textDirection: Directionality.of(context),
              ),
            ),
          ),
          Positioned(
            left: 10,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: scheme.surface.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(8)),
              child: Text('Map preview · not to scale', style: Theme.of(context).textTheme.labelSmall),
            ),
          ),
        ]),
      );
    });
  }
}

class _SchematicPainter extends CustomPainter {
  _SchematicPainter({
    required this.pins,
    required this.route,
    required this.projection,
    required this.scheme,
    required this.connect,
    required this.textDirection,
    this.selectedId,
  });

  final List<MapPin> pins;
  final List<GeoPoint> route;
  final MapProjection projection;
  final ColorScheme scheme;
  final bool connect;
  final TextDirection textDirection;
  final String? selectedId;

  @override
  void paint(Canvas canvas, Size size) {
    // Background with a faint street grid.
    canvas.drawRect(Offset.zero & size, Paint()..color = scheme.surfaceContainerHighest);
    final grid = Paint()
      ..color = scheme.outlineVariant.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    for (var x = 24.0; x < size.width; x += 44) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 18.0; y < size.height; y += 44) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Route (measured line) or a dashed straight line between kitchen and home.
    if (route.length >= 2) {
      final path = Path()..moveTo(projection.toScreen(route.first).dx, projection.toScreen(route.first).dy);
      for (final p in route.skip(1)) {
        final o = projection.toScreen(p);
        path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = scheme.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    } else if (connect) {
      final kitchen = pins.where((p) => p.kind == PinKind.kitchen).firstOrNull;
      final home = pins.where((p) => p.kind == PinKind.home).firstOrNull;
      if (kitchen != null && home != null) {
        _dashed(canvas, projection.toScreen(kitchen.point), projection.toScreen(home.point),
            Paint()
              ..color = scheme.outline
              ..strokeWidth = 2.5
              ..strokeCap = StrokeCap.round);
      }
    }

    // Places first; the customer's own pins and the rider last so they sit on top.
    int rank(PinKind k) => switch (k) { PinKind.place || PinKind.kitchen => 0, PinKind.home => 1, PinKind.you => 2, PinKind.rider => 3 };
    final ordered = [...pins]..sort((a, b) => rank(a.kind) - rank(b.kind));
    for (final p in ordered) {
      final o = projection.toScreen(p.point);
      final selected = p.id != null && p.id == selectedId;
      final r = selected ? 17.0 : 14.0;
      final color = _color(p.kind, scheme);
      canvas.drawCircle(o + const Offset(0, 1.5), r + 1, Paint()..color = Colors.black.withValues(alpha: 0.18));
      canvas.drawCircle(o, r + 2.5, Paint()..color = Colors.white);
      canvas.drawCircle(o, r, Paint()..color = color);
      final icon = _icon(p.kind);
      final tp = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(fontSize: r * 1.15, fontFamily: icon.fontFamily, package: icon.fontPackage, color: Colors.white),
        ),
        textDirection: textDirection,
      )..layout();
      tp.paint(canvas, o - Offset(tp.width / 2, tp.height / 2));
      if (p.label != null && (selected || pins.length <= 4)) {
        final lp = TextPainter(
          text: TextSpan(
            text: p.label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: scheme.onSurface),
          ),
          textDirection: textDirection,
          maxLines: 1,
          ellipsis: '…',
        )..layout(maxWidth: 140);
        final at = o + Offset(-lp.width / 2, r + 5);
        final bg = RRect.fromRectAndRadius(Rect.fromLTWH(at.dx - 5, at.dy - 2, lp.width + 10, lp.height + 4), const Radius.circular(6));
        canvas.drawRRect(bg, Paint()..color = scheme.surface.withValues(alpha: 0.9));
        lp.paint(canvas, at);
      }
    }
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    final total = (b - a).distance;
    if (total == 0) return;
    final dir = (b - a) / total;
    for (var d = 0.0; d < total; d += 14) {
      canvas.drawLine(a + dir * d, a + dir * math.min(d + 7, total), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SchematicPainter old) =>
      old.pins != pins || old.route != route || old.scheme != scheme || old.selectedId != selectedId;
}
