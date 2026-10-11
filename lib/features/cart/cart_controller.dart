import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The basket: product id -> quantity. Lives only on the phone until the order is placed.
class CartController extends Notifier<Map<int, int>> {
  static const maxPerItem = 20;

  @override
  Map<int, int> build() => const {};

  void add(int productId) {
    final qty = state[productId] ?? 0;
    if (qty >= maxPerItem) return;
    state = {...state, productId: qty + 1};
  }

  void remove(int productId) {
    final qty = state[productId] ?? 0;
    if (qty <= 1) {
      state = {...state}..remove(productId);
    } else {
      state = {...state, productId: qty - 1};
    }
  }

  void clear() => state = const {};
}

final cartProvider =
    NotifierProvider<CartController, Map<int, int>>(CartController.new);
