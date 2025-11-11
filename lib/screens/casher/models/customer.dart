class Customer {
  final int id;
  final String name;
  final String? phone;
  final String? customerId;

  Customer({required this.id, required this.name, this.phone, this.customerId});

  @override
  String toString() {
    return name;
  }
}
