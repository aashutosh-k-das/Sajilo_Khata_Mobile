import 'dart:convert';

class InventoryItem {
  final int? id;
  final String name;
  final String category;
  final int stockQty;
  final double buyingPrice;
  final double sellingPrice;
  final int minThreshold;

  InventoryItem({
    this.id,
    required this.name,
    required this.category,
    required this.stockQty,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.minThreshold,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category': category,
      'stockQty': stockQty,
      'buyingPrice': buyingPrice,
      'sellingPrice': sellingPrice,
      'minThreshold': minThreshold,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      stockQty: map['stockQty'] as int,
      buyingPrice: (map['buyingPrice'] as num).toDouble(),
      sellingPrice: (map['sellingPrice'] as num).toDouble(),
      minThreshold: map['minThreshold'] as int,
    );
  }
}

class Customer {
  final int? id;
  final String name;
  final String phone;
  final double balance; // Outstanding credit balance

  Customer({
    this.id,
    required this.name,
    required this.phone,
    this.balance = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'balance': balance,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String,
      balance: (map['balance'] as num).toDouble(),
    );
  }
}

class CartItem {
  final String name;
  final int qty;
  final double price;

  CartItem({
    required this.name,
    required this.qty,
    required this.price,
  });

  double get total => qty * price;

  Map<String, dynamic> toMap() => {'name': name, 'qty': qty, 'price': price};
  factory CartItem.fromMap(Map<String, dynamic> map) => CartItem(
    name: map['name'] as String,
    qty: map['qty'] as int,
    price: (map['price'] as num).toDouble(),
  );
}

class Bill {
  final int? id;
  final int? customerId;
  final String customerName;
  final List<CartItem> items;
  final double subtotal;
  final double vat;
  final double total;
  final DateTime date;
  final String paymentMethod; // 'cash', 'credit', 'online'
  final int syncStatus; // 0 = unsynced, 1 = synced

  Bill({
    this.id,
    this.customerId,
    required this.customerName,
    required this.items,
    required this.subtotal,
    required this.vat,
    required this.total,
    required this.date,
    required this.paymentMethod,
    this.syncStatus = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'customerId': customerId?.toString(),
      'customerName': customerName,
      'itemsJson': jsonEncode(items.map((e) => e.toMap()).toList()),
      'subtotal': subtotal,
      'vat': vat,
      'total': total,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod,
      'syncStatus': syncStatus,
    };
  }

  factory Bill.fromMap(Map<String, dynamic> map) {
    final list = jsonDecode(map['itemsJson'] as String) as List;
    final items = list.map((e) => CartItem.fromMap(e as Map<String, dynamic>)).toList();
    
    return Bill(
      id: map['id'] as int?,
      customerId: map['customerId'] != null ? int.tryParse(map['customerId']) : null,
      customerName: map['customerName'] as String,
      items: items,
      subtotal: (map['subtotal'] as num).toDouble(),
      vat: (map['vat'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      paymentMethod: map['paymentMethod'] as String,
      syncStatus: map['syncStatus'] as int,
    );
  }
}

class KhataTransaction {
  final int? id;
  final int customerId;
  final String type; // 'credit' or 'payment'
  final double amount;
  final String description;
  final DateTime date;
  final int syncStatus;

  KhataTransaction({
    this.id,
    required this.customerId,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    this.syncStatus = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'customerId': customerId,
      'type': type,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'syncStatus': syncStatus,
    };
  }

  factory KhataTransaction.fromMap(Map<String, dynamic> map) {
    return KhataTransaction(
      id: map['id'] as int?,
      customerId: map['customerId'] as int,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      date: DateTime.parse(map['date'] as String),
      syncStatus: map['syncStatus'] as int,
    );
  }
}
