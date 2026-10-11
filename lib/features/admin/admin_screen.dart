import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/product_photo.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../menu/menu_screen.dart';

final adminOrdersProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  final res =
      await ref.watch(dioProvider).get<List<dynamic>>('/api/v1/admin/orders');
  return res.data!
      .map((e) => Order.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// The shop's side: the queue of open orders, and which menu items are sold out.
class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  int _view = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (_view == 0) ref.invalidate(adminOrdersProvider);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    Widget toggle(int value, String label) {
      final on = _view == value;
      return InkWell(
        onTap: () => setState(() => _view = value),
        child: Container(
          padding: const EdgeInsets.only(bottom: 4),
          margin: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: on ? Palette.pen : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Text(
            label,
            style: text.titleMedium?.copyWith(
              color: on ? Palette.pen : Palette.steel,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              toggle(0, 'คิวออเดอร์'),
              toggle(1, 'เมนูหมด/มี'),
            ],
          ),
        ),
        Expanded(child: _view == 0 ? const _Queue() : const _MenuSwitches()),
      ],
    );
  }
}

class _Queue extends ConsumerWidget {
  const _Queue();

  Future<void> _move(
    BuildContext context,
    WidgetRef ref,
    Order o,
    String status,
  ) async {
    try {
      await ref.read(dioProvider).post<Map<String, dynamic>>(
        '/api/v1/admin/orders/${o.id}/status',
        data: {'status': status},
      );
      ref.invalidate(adminOrdersProvider);
    } on DioException catch (e) {
      if (!context.mounted) return;
      ref.invalidate(adminOrdersProvider);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final orders = ref.watch(adminOrdersProvider);
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
                  onPressed: () => ref.invalidate(adminOrdersProvider),
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
        child: Text('ไม่มีออเดอร์ค้าง',
            style: text.titleMedium?.copyWith(color: Palette.steel)),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.refresh(adminOrdersProvider.future),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          final o = list[i];
          final next = o.nextStep;
          final unpaid = o.status == OrderStatus.pendingPayment;

          // A ticket on the rail: printed slip, torn edge, the big number first.
          return ClipPath(
            clipper: TornEdgeClipper(),
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('#${o.id}',
                          style: figures(size: 34, weight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(o.customer,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodyMedium
                                  ?.copyWith(color: Palette.steel)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '${OrderStatus.label(o.status)}  ${timeHm(o.createdAt)}',
                          style: text.bodyMedium?.copyWith(
                            color: unpaid ? Palette.stamp : Palette.steel,
                            fontWeight:
                                unpaid ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const DashedRule(),
                  const SizedBox(height: 10),
                  for (final it in o.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          SizedBox(
                            width: 40,
                            child: Text('${it.qty}×',
                                style: figures(size: 20)),
                          ),
                          Expanded(
                            child: Text(it.name, style: text.titleMedium),
                          ),
                        ],
                      ),
                    ),
                  if (o.note.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('หมายเหตุ: ${o.note}',
                        style: text.bodyMedium?.copyWith(
                          color: Palette.stamp,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                  const SizedBox(height: 10),
                  const DashedRule(),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('รวม', style: text.bodyMedium),
                      const Spacer(),
                      Text(baht(o.totalBaht), style: figures(size: 20)),
                    ],
                  ),
                  if (next != null) ...[
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => _move(context, ref, o, next.$1),
                      child: Text(next.$2),
                    ),
                    if (o.shopCanCancel)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Palette.stamp,
                          ),
                          onPressed: () =>
                              _move(context, ref, o, OrderStatus.cancelled),
                          child: const Text('ยกเลิกออเดอร์'),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MenuSwitches extends ConsumerWidget {
  const _MenuSwitches();

  Future<void> _set(
    BuildContext context,
    WidgetRef ref,
    Product p,
    bool available,
  ) async {
    try {
      await ref.read(dioProvider).patch<Map<String, dynamic>>(
        '/api/v1/admin/products/${p.id}',
        data: {'available': available},
      );
      ref.invalidate(productsProvider);
    } on DioException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  Future<void> _pickPhoto(BuildContext context, WidgetRef ref, Product p) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked == null) return;
      final form = FormData.fromMap({
        'image': await MultipartFile.fromFile(picked.path,
            filename: picked.name),
      });
      await ref
          .read(dioProvider)
          .post<Map<String, dynamic>>('/api/v1/admin/products/${p.id}/image',
              data: form);
      ref.invalidate(productsProvider);
      messenger.showSnackBar(SnackBar(content: Text('อัปโหลดรูป ${p.name} แล้ว')));
    } on DioException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final list = products.valueOrNull;

    if (list == null) {
      return products.hasError
          ? Center(child: Text(apiErrorMessage(products.error!)))
          : const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final p in list)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 8, 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Palette.rule)),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => _pickPhoto(context, ref, p),
                  child: ProductPhoto(url: p.imageUrl, size: 56),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 28),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          alignment: Alignment.centerLeft,
                        ),
                        onPressed: () => _pickPhoto(context, ref, p),
                        child: Text(
                            p.imageUrl.isEmpty ? 'เพิ่มรูป' : 'เปลี่ยนรูป'),
                      ),
                    ],
                  ),
                ),
                Text(p.available ? 'มีขาย' : 'หมด',
                    style: Theme.of(context).textTheme.bodySmall),
                Switch(
                  value: p.available,
                  activeThumbColor: Colors.white,
                  activeTrackColor: Palette.pen,
                  onChanged: (v) => _set(context, ref, p, v),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
