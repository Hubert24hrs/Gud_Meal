import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

import '../../providers.dart';
import '../../ui/gm_map.dart';
import '../../widgets.dart';

/// Restaurants or shops around the customer's area, closest first. Uses the free local estimates (no Google
/// call per view); checkout prices the exact delivery fee and time.
final nearbyPlacesProvider = FutureProvider.autoDispose.family<List<MapPlace>, String>((ref, vertical) {
  final area = ref.watch(areaProvider);
  return ref.watch(apiProvider).nearbyOnMap(near: area.location, vertical: vertical);
});

class NearbyMapScreen extends ConsumerStatefulWidget {
  const NearbyMapScreen({super.key, this.vertical = 'food'});
  final String vertical;

  @override
  ConsumerState<NearbyMapScreen> createState() => _NearbyMapScreenState();
}

class _NearbyMapScreenState extends ConsumerState<NearbyMapScreen> {
  String? _selected;
  bool _openOnly = false;

  @override
  Widget build(BuildContext context) {
    final area = ref.watch(areaProvider);
    final places = ref.watch(nearbyPlacesProvider(widget.vertical));
    final theme = Theme.of(context);
    final noun = widget.vertical == 'beauty' ? 'shops' : 'restaurants';
    return Scaffold(
      appBar: AppBar(title: Text('${noun[0].toUpperCase()}${noun.substring(1)} near ${area.name}')),
      body: places.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(nearbyPlacesProvider(widget.vertical))),
        data: (all) {
          final list = _openOnly ? all.where((p) => p.isOpen).toList() : all;
          final pins = [
            MapPin(area.location, PinKind.you, label: area.name),
            for (final p in list) MapPin(p.location, PinKind.place, id: p.id, label: p.name),
          ];
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: GmMap(
                height: 260,
                pins: pins,
                connectKitchenToHome: false,
                selectedId: _selected,
                onPinTap: (id) => setState(() => _selected = id),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: [
                FilterChip(
                  label: const Text('Open now'),
                  selected: _openOnly,
                  onSelected: (v) => setState(() => _openOnly = v),
                ),
                const Spacer(),
                Text('${list.length} $noun', style: theme.textTheme.bodySmall),
              ]),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(child: Text('No $noun ${_openOnly ? 'open ' : ''}near ${area.name} right now.'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
                      itemCount: list.length + 1,
                      itemBuilder: (context, i) {
                        if (i == list.length) {
                          return Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              'Distances and times are estimates. Checkout shows the exact delivery fee and arrival time.',
                              style: theme.textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        final p = list[i];
                        final selected = p.id == _selected;
                        return Card(
                          color: selected ? theme.colorScheme.primaryContainer : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              child: Text('${i + 1}'),
                            ),
                            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text([
                              p.area,
                              if (p.cuisines.isNotEmpty) p.cuisines.take(2).join(', '),
                              if (p.rating > 0) '★ ${p.rating.toStringAsFixed(1)}',
                              if (!p.isOpen) 'Closed now',
                              if (p.deliversHere == false) 'Pickup only here',
                            ].join(' · ')),
                            trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                              if (p.etaMinutes != null) Text('~${p.etaMinutes} min', style: const TextStyle(fontWeight: FontWeight.w800)),
                              if (p.distanceKm != null) Text('${p.distanceKm!.toStringAsFixed(1)} km', style: theme.textTheme.bodySmall),
                            ]),
                            onTap: () => context.push('/restaurants/${p.id}'),
                            onLongPress: () => setState(() => _selected = p.id),
                          ),
                        );
                      },
                    ),
            ),
          ]);
        },
      ),
    );
  }
}
