import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/product_photo.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../cart/cart_controller.dart';
import '../cart/qty_control.dart';
import '../cart/checkout_screen.dart';

final productsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final res =
      await ref.watch(dioProvider).get<List<dynamic>>('/api/v1/products');
  return res.data!
      .map((e) => Product.fromJson(e as Map<String, dynamic>))
      .toList();
});

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key, required this.onOrdered});

  /// Called after an order is placed and the customer comes back, to show "my orders".
  final VoidCallback onOrdered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final cart = ref.watch(cartProvider);

    return products.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(apiErrorMessage(e), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(productsProvider),
                child: const Text('ลองอีกครั้ง'),
              ),
            ],
          ),
        ),
      ),
      data: (list) {
        final byId = {for (final p in list) p.id: p};
        final count = cart.values.fold<int>(0, (a, b) => a + b);
        final total = cart.entries.fold<int>(
          0,
          (sum, e) => sum + (byId[e.key]?.priceBaht ?? 0) * e.value,
        );

        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.refresh(productsProvider.future),
                child: _MenuList(products: list),
              ),
            ),
            if (count > 0)
              _CartBar(
                count: count,
                total: total,
                onTap: () async {
                  final placed = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => CheckoutScreen(products: byId),
                    ),
                  );
                  if (placed == true) onOrdered();
                },
              ),
          ],
        );
      },
    );
  }
}

class _MenuList extends ConsumerWidget {
  const _MenuList({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);

    // Keep the shop's own order of categories.
    final categories = <String>[];
    for (final p in products) {
      if (!categories.contains(p.category)) categories.add(p.category);
    }

    return MarginLine(
      child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final category in categories) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(68, 22, 20, 6),
            child: Text(category, style: text.titleLarge),
          ),
          for (final p in products.where((p) => p.category == category))
            _ProductRow(
              product: p,
              qty: cart[p.id] ?? 0,
              onAdd: () => notifier.add(p.id),
              onRemove: () => notifier.remove(p.id),
            ),
        ],
      ],
    ));
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.qty,
    required this.onAdd,
    required this.onRemove,
  });

  final Product product;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final sold = !product.available;
    final muted = sold ? Palette.steel : Palette.ink;

    // Tapping anywhere on a line adds one, like ticking it on the pad.
    return InkWell(
      onTap: sold ? null : onAdd,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Palette.rule)),
        ),
        constraints: const BoxConstraints(minHeight: 80),
        child: Row(
          children: [
            // The margin column is where the customer's quantity gets written.
            SizedBox(
              width: 52,
              child: qty > 0
                  ? Center(child: Text('$qty', style: figures(size: 26)))
                  : null,
            ),
            const SizedBox(width: 12),
            ProductPhoto(
                url: product.imageUrl, size: 56, soldOut: sold),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        style: text.titleMedium?.copyWith(color: muted)),
                    if (product.description.isNotEmpty)
                      Text(
                        product.description,
                        style: text.bodySmall?.copyWith(color: Palette.steel),
                      ),
                  ],
                ),
              ),
            ),
            if (sold)
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Text('หมด',
                    style: figures(size: 18, color: Palette.stamp)),
              )
            else ...[
              if (qty > 0)
                IconButton(
                  tooltip: 'ลด',
                  onPressed: onRemove,
                  icon: const Icon(Icons.remove, size: 20, color: Palette.pen),
                  visualDensity: VisualDensity.compact,
                ),
              Padding(
                padding: EdgeInsets.only(right: qty > 0 ? 16 : 20),
                child: Text(baht(product.priceBaht),
                    style: figures(size: 18, color: Palette.pen)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CartBar extends StatelessWidget {
  const _CartBar({
    required this.count,
    required this.total,
    required this.onTap,
  });

  final int count;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: Palette.pen,
      child: InkWell(
        onTap: onTap,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Text('ใบสั่ง $count อย่าง',
                    style: text.titleMedium?.copyWith(color: Colors.white)),
                const Spacer(),
                Text(baht(total),
                    style: figures(size: 20, color: Colors.white)),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
