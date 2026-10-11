import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import 'orders_providers.dart';

/// One order: where it is now, and the receipt (with the PromptPay QR while unpaid).
class OrderScreen extends ConsumerStatefulWidget {
  const OrderScreen({super.key, required this.initial});

  final Order initial;

  @override
  ConsumerState<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends ConsumerState<OrderScreen> {
  Timer? _timer;

  int get _id => widget.initial.id;

  @override
  void initState() {
    super.initState();
    // The shop confirms payment on their side, so keep asking until the order is finished.
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      final latest = ref.read(orderProvider(_id)).valueOrNull;
      if (latest == null || latest.isOpen) {
        ref.invalidate(orderProvider(_id));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยกเลิกออเดอร์นี้?'),
        content: const Text('ถ้าโอนเงินไปแล้ว กรุณาแจ้งร้านก่อนยกเลิก'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('เก็บไว้'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ยกเลิกออเดอร์'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ref
          .read(dioProvider)
          .post<Map<String, dynamic>>('/api/v1/orders/$_id/cancel');
      ref.invalidate(orderProvider(_id));
      ref.invalidate(myOrdersProvider);
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(orderProvider(_id), (prev, next) {
      final before = prev?.valueOrNull?.status;
      final after = next.valueOrNull?.status;
      if (after != null && before != after) ref.invalidate(myOrdersProvider);
    });

    final order = ref.watch(orderProvider(_id)).valueOrNull ?? widget.initial;

    return Scaffold(
      appBar: AppBar(title: Text('ออเดอร์ #${order.id}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _StatusHeader(order: order),
          const SizedBox(height: 24),
          _Receipt(order: order),
          if (order.status == OrderStatus.pendingPayment) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _cancel,
                child: const Text('ยกเลิกออเดอร์'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.order});

  final Order order;

  static const _short = ['รอจ่าย', 'รับเงิน', 'กำลังทำ', 'พร้อมรับ'];

  String get _hint => switch (order.status) {
        OrderStatus.pendingPayment => 'สแกน QR ด้านล่างเพื่อจ่ายเงิน',
        OrderStatus.paid => 'ร้านได้รับเงินแล้ว กำลังเตรียมให้',
        OrderStatus.preparing => 'บาริสต้ากำลังทำให้คุณ',
        OrderStatus.ready => 'มารับที่เคาน์เตอร์ได้เลย บอกหมายเลข #${order.id}',
        OrderStatus.completed => 'รับของเรียบร้อยแล้ว ขอบคุณที่อุดหนุน',
        _ => 'ออเดอร์นี้ถูกยกเลิก',
      };

  Color get _stampColor => switch (order.status) {
        OrderStatus.pendingPayment => Palette.stamp,
        OrderStatus.cancelled || OrderStatus.completed => Palette.steel,
        _ => Palette.pen,
      };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final current = OrderStatus.steps.indexOf(order.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Transform.rotate(
          angle: -0.07,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: _stampColor, width: 3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              OrderStatus.label(order.status),
              style: text.headlineMedium?.copyWith(
                color: _stampColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(_hint, style: text.bodyMedium?.copyWith(color: Palette.steel)),
        if (current >= 0) ...[
          const SizedBox(height: 16),
          // Four words in order; the current one is circled in pen.
          Row(
            children: [
              for (var i = 0; i < _short.length; i++) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: i == current
                      ? BoxDecoration(
                          border: Border.all(color: Palette.pen, width: 1.8),
                          borderRadius: BorderRadius.circular(14),
                        )
                      : null,
                  child: Text(
                    _short[i],
                    style: text.bodyMedium?.copyWith(
                      color: i == current
                          ? Palette.pen
                          : (i < current ? Palette.ink : Palette.steel),
                      fontWeight:
                          i == current ? FontWeight.w700 : FontWeight.w400,
                      decoration:
                          i < current ? TextDecoration.lineThrough : null,
                      decorationColor: Palette.steel,
                    ),
                  ),
                ),
                if (i < _short.length - 1) const SizedBox(width: 2),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// The one printed-looking thing in the app: a till receipt with a torn edge.
class _Receipt extends StatelessWidget {
  const _Receipt({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final payment = order.payment;
    final nums = figures(size: 17);

    return ClipPath(
      clipper: TornEdgeClipper(),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 34),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppConfig.shopName, style: text.titleLarge),
            const SizedBox(height: 2),
            Text(
              'ใบสั่ง #${order.id}   ${dateTimeThai(order.createdAt)}',
              style: text.bodySmall?.copyWith(color: Palette.steel),
            ),
            const SizedBox(height: 14),
            const DashedRule(),
            const SizedBox(height: 10),
            for (final it in order.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 36, child: Text('${it.qty}×', style: nums)),
                    Expanded(child: Text(it.name, style: text.bodyLarge)),
                    Text(baht(it.lineTotal), style: nums),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            const DashedRule(),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('รวม', style: text.titleMedium),
                const Spacer(),
                Text(baht(order.totalBaht), style: figures(size: 26)),
              ],
            ),
            if (order.note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'หมายเหตุ: ${order.note}',
                style: text.bodySmall?.copyWith(color: Palette.steel),
              ),
            ],
            if (payment != null) ...[
              const SizedBox(height: 18),
              const DashedRule(),
              const SizedBox(height: 18),
              Text('จ่ายด้วย PromptPay',
                  textAlign: TextAlign.center, style: text.titleMedium),
              const SizedBox(height: 14),
              Center(
                child: QrImageView(
                  data: payment.payload,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                baht(payment.amountBaht),
                textAlign: TextAlign.center,
                style: figures(size: 30),
              ),
              const SizedBox(height: 6),
              Text(
                'เปิดแอปธนาคารแล้วสแกน จ่ายเสร็จรอสักครู่\nหน้านี้จะอัปเดตเมื่อร้านรับเงินแล้ว',
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: Palette.steel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
