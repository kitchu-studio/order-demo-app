import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../orders/order_screen.dart';
import '../orders/orders_providers.dart';
import 'cart_controller.dart';
import 'qty_control.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, required this.products});

  final Map<int, Product> products;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _note = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _place(Map<int, int> cart) async {
    setState(() => _saving = true);
    final note = _note.text.trim();
    try {
      final res = await ref.read(dioProvider).post<Map<String, dynamic>>(
        '/api/v1/orders',
        data: {
          'items': [
            for (final e in cart.entries)
              {'product_id': e.key, 'qty': e.value},
          ],
          if (note.isNotEmpty) 'note': note,
        },
      );
      final order = Order.fromJson(res.data!);
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(myOrdersProvider);
      if (!mounted) return;
      // Replace this screen with the order, so "back" returns to the menu with an empty basket.
      final nav = Navigator.of(context);
      nav.pushReplacement(
        MaterialPageRoute(builder: (_) => OrderScreen(initial: order)),
        result: true, // tells the menu to switch to "my orders"
      );
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);

    final lines = [
      for (final e in cart.entries)
        if (widget.products[e.key] != null) (widget.products[e.key]!, e.value),
    ];
    final total = lines.fold<int>(0, (s, l) => s + l.$1.priceBaht * l.$2);

    // Emptied the basket here: nothing left to order.
    if (lines.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('ตะกร้า')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ตะกร้าว่าง', style: text.titleLarge),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('กลับไปเลือกเมนู'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('ตะกร้า')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                for (final (p, qty) in lines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: text.titleMedium),
                              Text(baht(p.priceBaht),
                                  style: figures(size: 15, color: Palette.steel)),
                            ],
                          ),
                        ),
                        QtyControl(
                          qty: qty,
                          onAdd: () => notifier.add(p.id),
                          onRemove: () => notifier.remove(p.id),
                        ),
                      ],
                    ),
                  ),
                const Divider(),
                const SizedBox(height: 16),
                TextField(
                  controller: _note,
                  maxLength: 300,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'หมายเหตุถึงร้าน (ไม่บังคับ)',
                    hintText: 'เช่น หวานน้อย ไม่ใส่น้ำแข็ง',
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Palette.rule)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text('รวม', style: text.titleMedium),
                      const Spacer(),
                      Text(baht(total), style: figures(size: 26)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _saving ? null : () => _place(cart),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('สั่งและจ่ายเงิน'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
