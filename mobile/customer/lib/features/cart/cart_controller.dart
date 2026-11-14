import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

/// Display-only cart. Prices shown here are estimates; the server quote is authoritative.
class CartItem {
  const CartItem({
    required this.itemId,
    required this.name,
    required this.unitPriceKobo,
    required this.quantity,
    this.selections = const [],
    this.selectionLabels = const [],
    this.notes,
  });

  final String itemId;
  final String name;
  final int unitPriceKobo;
  final int quantity;
  final List<OptionSelection> selections;
  final List<String> selectionLabels;
  final String? notes;

  String get key {
    final sel = selections.map((s) => '${s.groupId}:${([...s.choiceIds]..sort()).join(',')}').toList()..sort();
    return '$itemId#${sel.join('|')}#${notes ?? ''}';
  }

  CartItem copyWith({int? quantity}) => CartItem(
        itemId: itemId,
        name: name,
        unitPriceKobo: unitPriceKobo,
        quantity: quantity ?? this.quantity,
        selections: selections,
        selectionLabels: selectionLabels,
        notes: notes,
      );
}

class CartState {
  const CartState({this.restaurantId, this.restaurantName, this.items = const []});
  final String? restaurantId;
  final String? restaurantName;
  final List<CartItem> items;

  int get count => items.fold(0, (n, i) => n + i.quantity);
  int get subtotalKobo => items.fold(0, (n, i) => n + i.unitPriceKobo * i.quantity);
  bool get isEmpty => items.isEmpty;

  List<CartLine> toLines() => [
        for (final i in items) CartLine(itemId: i.itemId, quantity: i.quantity, selections: i.selections, notes: i.notes),
      ];
}

class CartController extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  /// Returns false when the item belongs to another restaurant and [replace] was not set.
  bool add(String restaurantId, String restaurantName, CartItem item, {bool replace = false}) {
    if (state.restaurantId != null && state.restaurantId != restaurantId && !state.isEmpty && !replace) return false;
    final base = state.restaurantId == restaurantId ? state.items : <CartItem>[];
    final idx = base.indexWhere((i) => i.key == item.key);
    final items = [...base];
    if (idx >= 0) {
      items[idx] = items[idx].copyWith(quantity: (items[idx].quantity + item.quantity).clamp(1, 50));
    } else {
      items.add(item);
    }
    state = CartState(restaurantId: restaurantId, restaurantName: restaurantName, items: items);
    return true;
  }

  void setQuantity(String key, int quantity) {
    final items = [
      for (final i in state.items)
        if (i.key != key) i else if (quantity > 0) i.copyWith(quantity: quantity.clamp(1, 50)),
    ];
    state = items.isEmpty ? const CartState() : CartState(restaurantId: state.restaurantId, restaurantName: state.restaurantName, items: items);
  }

  void clear() => state = const CartState();
}

final cartProvider = NotifierProvider<CartController, CartState>(CartController.new);
