import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import 'order_screen.dart';
import 'orders_providers.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key, required this.onGoMenu});

  final VoidCallback onGoMenu;

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      ref.invalidate(myOrdersProvider);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(myOrdersProvider);
    final text = Theme.of(context).textTheme;

    // Keep showing the list while a background refresh is running.
    final list = orders.valueOrNull;
    if (list == null) {
      if (orders.hasError) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(apiErrorMessage(orders.error!), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(myOrdersProvider),
                  child: const Text('ลองอีกครั้ง'),
                ),
              ],
            ),
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ยังไม่มีออเดอร์', style: text.titleLarge),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: widget.onGoMenu,
                child: const Text('เลือกเมนู'),
              ),
            ],
          ),
        ),
      );
    }

    final open = list.where((o) => o.isOpen).toList();
    final past = list.where((o) => !o.isOpen).toList();

    Widget heading(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
          child: Text(t, style: text.titleMedium),
        );

    return RefreshIndicator(
      onRefresh: () => ref.refresh(myOrdersProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (open.isNotEmpty) heading('กำลังดำเนินการ'),
          for (final o in open) _OrderRow(order: o),
          if (past.isNotEmpty) heading('ที่ผ่านมา'),
          for (final o in past) _OrderRow(order: o),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final o = order;

    final Color statusColor;
    final FontWeight statusWeight;
    switch (o.status) {
      case OrderStatus.pendingPayment:
        statusColor = Palette.stamp;
        statusWeight = FontWeight.w700;
      case OrderStatus.ready:
        statusColor = Palette.pen;
        statusWeight = FontWeight.w700;
      default:
        statusColor = o.isOpen ? Palette.ink : Palette.steel;
        statusWeight = FontWeight.w400;
    }

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OrderScreen(initial: o)),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Palette.rule)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 56,
              child: Text('#${o.id}', style: figures(size: 20)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyLarge),
                  const SizedBox(height: 2),
                  Text(
                    '${dateTimeThai(o.createdAt)}   ${baht(o.totalBaht)}',
                    style: text.bodySmall?.copyWith(color: Palette.steel),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              OrderStatus.label(o.status),
              style: text.bodyMedium
                  ?.copyWith(color: statusColor, fontWeight: statusWeight),
            ),
          ],
        ),
      ),
    );
  }
}
