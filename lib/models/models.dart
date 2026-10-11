class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.isAdmin,
  });

  final int id;
  final String email;
  final String name;
  final bool isAdmin;

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as int,
        email: j['email'] as String,
        name: (j['name'] as String?) ?? '',
        isAdmin: (j['is_admin'] as bool?) ?? false,
      );
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.priceBaht,
    required this.available,
    this.imageUrl = '',
  });

  final int id;
  final String name;
  final String description;
  final String category;
  final int priceBaht;
  final bool available;
  final String imageUrl;

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as int,
        name: j['name'] as String,
        description: (j['description'] as String?) ?? '',
        category: j['category'] as String,
        priceBaht: j['price_baht'] as int,
        available: (j['available'] as bool?) ?? true,
        imageUrl: (j['image_url'] as String?) ?? '',
      );
}

class OrderItem {
  const OrderItem({
    required this.productId,
    required this.name,
    required this.unitPriceBaht,
    required this.qty,
  });

  final int productId;
  final String name;
  final int unitPriceBaht;
  final int qty;

  int get lineTotal => unitPriceBaht * qty;

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        productId: j['product_id'] as int,
        name: j['name'] as String,
        unitPriceBaht: j['unit_price_baht'] as int,
        qty: j['qty'] as int,
      );
}

/// What the customer scans: the text to draw as a QR code, and the amount it carries.
class Payment {
  const Payment({required this.amountBaht, required this.payload});

  final int amountBaht;
  final String payload;

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
        amountBaht: j['amount_baht'] as int,
        payload: j['payload'] as String,
      );
}

class OrderStatus {
  OrderStatus._();

  static const pendingPayment = 'pending_payment';
  static const paid = 'paid';
  static const preparing = 'preparing';
  static const ready = 'ready';
  static const completed = 'completed';
  static const cancelled = 'cancelled';

  /// The four steps a customer watches, in order.
  static const steps = [pendingPayment, paid, preparing, ready];

  static String label(String s) => switch (s) {
        pendingPayment => 'รอชำระเงิน',
        paid => 'ร้านรับเงินแล้ว',
        preparing => 'กำลังทำ',
        ready => 'พร้อมรับ',
        completed => 'รับแล้ว',
        cancelled => 'ยกเลิกแล้ว',
        _ => s,
      };
}

class Order {
  const Order({
    required this.id,
    required this.status,
    required this.totalBaht,
    required this.note,
    required this.createdAt,
    required this.customer,
    required this.items,
    this.payment,
  });

  final int id;
  final String status;
  final int totalBaht;
  final String note;
  final DateTime createdAt;
  final String customer;
  final List<OrderItem> items;
  final Payment? payment;

  bool get isOpen =>
      status != OrderStatus.completed && status != OrderStatus.cancelled;

  /// Where the shop moves this order next, with the button text for it.
  /// Null once nothing is left to do.
  (String status, String label)? get nextStep => switch (status) {
        OrderStatus.pendingPayment => (OrderStatus.paid, 'รับเงินแล้ว'),
        OrderStatus.paid => (OrderStatus.preparing, 'เริ่มทำ'),
        OrderStatus.preparing => (OrderStatus.ready, 'ทำเสร็จ'),
        OrderStatus.ready => (OrderStatus.completed, 'ลูกค้ารับแล้ว'),
        _ => null,
      };

  bool get shopCanCancel =>
      status == OrderStatus.pendingPayment || status == OrderStatus.paid;

  /// "ลาเต้ร้อน ×2, ชาไทยเย็น"
  String get summary => items
      .map((i) => i.qty > 1 ? '${i.name} ×${i.qty}' : i.name)
      .join(', ');

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'] as int,
        status: j['status'] as String,
        totalBaht: j['total_baht'] as int,
        note: (j['note'] as String?) ?? '',
        createdAt: DateTime.parse(j['created_at'] as String),
        customer: (j['customer'] as String?) ?? '',
        items: (j['items'] as List<dynamic>)
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        payment: j['payment'] == null
            ? null
            : Payment.fromJson(j['payment'] as Map<String, dynamic>),
      );
}
