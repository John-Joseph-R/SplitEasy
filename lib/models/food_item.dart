class FoodItem {
  final String id;
  String name;
  double price;
  int qty;
  Set<String> assigned;
  String? roundNumber;        // Changed from int? to String?
  bool isRoundBased;

  FoodItem({
    required this.id,
    required this.name,
    required this.price,
    required this.qty,
    Set<String>? assigned,
    this.roundNumber,
    this.isRoundBased = false,
  }) : assigned = assigned ?? {};

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'qty': qty,
    'assigned': assigned.toList(),
    'roundNumber': roundNumber,
    'isRoundBased': isRoundBased,
  };

  factory FoodItem.fromJson(Map<String, dynamic> j) => FoodItem(
    id: j['id'],
    name: j['name'],
    price: (j['price'] as num).toDouble(),
    qty: j['qty'],
    assigned: (j['assigned'] as List<dynamic>).map((e) => e.toString()).toSet(),
    roundNumber: j['roundNumber'] as String?,
    isRoundBased: j['isRoundBased'] ?? false,
  );
}