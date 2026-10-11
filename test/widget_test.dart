import 'package:flutter_test/flutter_test.dart';

import 'package:order_demo_app/models/models.dart';

void main() {
  test('Order parses items, payment and the next shop step', () {
    final o = Order.fromJson({
      'id': 7,
      'status': 'pending_payment',
      'total_baht': 150,
      'note': '',
      'created_at': '2026-10-12T03:00:00Z',
      'customer': 'ต้น',
      'items': [
        {'product_id': 2, 'name': 'ลาเต้ร้อน', 'unit_price_baht': 75, 'qty': 2},
      ],
      'payment': {'method': 'promptpay', 'amount_baht': 150, 'payload': '0002'},
    });
    expect(o.items.single.lineTotal, 150);
    expect(o.summary, 'ลาเต้ร้อน ×2');
    expect(o.payment?.amountBaht, 150);
    expect(o.nextStep?.$1, OrderStatus.paid);
    expect(o.shopCanCancel, isTrue);
    expect(o.isOpen, isTrue);
  });

  test('A finished order has no next step', () {
    final o = Order.fromJson({
      'id': 8,
      'status': 'completed',
      'total_baht': 60,
      'created_at': '2026-10-12T03:00:00Z',
      'items': <dynamic>[],
    });
    expect(o.nextStep, isNull);
    expect(o.isOpen, isFalse);
  });

  test('AppUser defaults to a customer', () {
    final u = AppUser.fromJson({'id': 1, 'email': 'a@b.co'});
    expect(u.isAdmin, isFalse);
  });
}
