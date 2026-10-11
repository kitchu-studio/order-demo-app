import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../models/models.dart';

final myOrdersProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  final res =
      await ref.watch(dioProvider).get<List<dynamic>>('/api/v1/orders');
  return res.data!
      .map((e) => Order.fromJson(e as Map<String, dynamic>))
      .toList();
});

final orderProvider =
    FutureProvider.autoDispose.family<Order, int>((ref, id) async {
  final res = await ref
      .watch(dioProvider)
      .get<Map<String, dynamic>>('/api/v1/orders/$id');
  return Order.fromJson(res.data!);
});
