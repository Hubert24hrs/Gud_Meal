import 'package:flutter/material.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key, this.label});
  final String status;

  /// Overrides the generic status wording (e.g. "Finding a rider" for a package).
  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = orderStatusLabels[status]?.$2 ?? StatusTone.neutral;
    final (bg, fg) = switch (tone) {
      StatusTone.success => (scheme.secondaryContainer, scheme.secondary),
      StatusTone.progress => (scheme.primaryContainer, scheme.onPrimaryContainer),
      StatusTone.warning => (scheme.tertiary.withValues(alpha: .2), scheme.onSurface),
      StatusTone.danger => (scheme.error.withValues(alpha: .12), scheme.error),
      _ => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(GmRadius.pill)),
      child: Text(label ?? statusLabel(status), style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

/// Branded duotone art used until a restaurant uploads photos.
class RestaurantArt extends StatelessWidget {
  const RestaurantArt({super.key, required this.restaurant, this.height = 140});
  final RestaurantCard restaurant;
  final double height;

  static const _palettes = [
    [Color(0xFFE0040B), Color(0xFFF5A21A)],
    [Color(0xFF2E8B1E), Color(0xFFA8D98E)],
    [Color(0xFFB4442A), Color(0xFFF28C5B)],
    [Color(0xFF6B2410), Color(0xFFE8C468)],
  ];

  @override
  Widget build(BuildContext context) {
    if (restaurant.coverUrl != null) {
      return Image.network(restaurant.coverUrl!, height: height, width: double.infinity, fit: BoxFit.cover);
    }
    final idx = restaurant.id.codeUnits.fold(0, (a, c) => a + c) % _palettes.length;
    final colors = _palettes[idx];
    final initials = restaurant.name.split(RegExp(r'\s+')).take(2).map((w) => w.isEmpty ? '' : w[0]).join();
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(gradient: RadialGradient(center: Alignment.topRight, radius: 1.4, colors: [colors[1], colors[0]])),
      padding: const EdgeInsets.all(12),
      alignment: Alignment.bottomLeft,
      child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700)),
    );
  }
}

class RestaurantTile extends StatelessWidget {
  const RestaurantTile({super.key, required this.restaurant, required this.onTap});
  final RestaurantCard restaurant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = restaurant;
    final available = r.isOpen && r.isAcceptingOrders;
    return Semantics(
      button: true,
      label: '${r.name}, rated ${r.rating.toStringAsFixed(1)}${available ? '' : ', closed'}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Opacity(
            opacity: available ? 1 : .6,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Stack(children: [
                RestaurantArt(restaurant: r),
                if (!available)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black45,
                      alignment: Alignment.center,
                      child: Text(r.isOpen ? 'Not taking orders' : 'Closed now',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
              ]),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(r.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                    Icon(Icons.star_rounded, size: 18, color: theme.colorScheme.tertiary),
                    Text(r.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 2),
                  Text('${r.cuisines.join(' · ')} · ${r.area}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Text(
                    [
                      if (r.etaMinutes != null) '${r.etaMinutes} min',
                      if (r.deliversToLocation == false) 'Pickup only here' else if (r.deliveryFeeKobo != null) '${formatNaira(r.deliveryFeeKobo)} delivery',
                    ].join('  ·  '),
                    style: theme.textTheme.bodySmall,
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_off_rounded, size: 40),
            const SizedBox(height: 12),
            Text('$error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ]),
        ),
      );
}
