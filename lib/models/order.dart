class Order {
  final String item;
  final String itemName;
  final double price;
  final String currency;
  final int quantity;

  Order({
    required this.item,
    required this.itemName,
    required this.price,
    required this.currency,
    required this.quantity,
  });

  // Factory constructor to create Order from JSON
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      item: json['Item'] ?? '',
      itemName: json['ItemName'] ?? '',
      price: (json['Price'] is int) ? (json['Price'] as int).toDouble() : (json['Price'] as double),
      currency: json['Currency'] ?? '',
      quantity: json['Quantity'] ?? 0,
    );
  }

  // Convert Order to JSON
  Map<String, dynamic> toJson() {
    return {
      'Item': item,
      'ItemName': itemName,
      'Price': price,
      'Currency': currency,
      'Quantity': quantity,
    };
  }

  // Create a copy of Order with updated values
  Order copyWith({
    String? item,
    String? itemName,
    double? price,
    String? currency,
    int? quantity,
  }) {
    return Order(
      item: item ?? this.item,
      itemName: itemName ?? this.itemName,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  String toString() {
    return 'Order(item: $item, itemName: $itemName, price: $price, currency: $currency, quantity: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order &&
        other.item == item &&
        other.itemName == itemName &&
        other.price == price &&
        other.currency == currency &&
        other.quantity == quantity;
  }

  @override
  int get hashCode {
    return item.hashCode ^
        itemName.hashCode ^
        price.hashCode ^
        currency.hashCode ^
        quantity.hashCode;
  }
} 