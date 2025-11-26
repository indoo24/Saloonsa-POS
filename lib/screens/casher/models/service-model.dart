class ServiceModel {
  final String name;
  final double price;
  final String category;
  String? barber;
  DateTime? serviceDateTime;

  ServiceModel({
    required this.name,
    required this.price,
    required this.category,
    this.barber,
    this.serviceDateTime,
  });

  get employeeName => null;
  
  // Copy with method for updating properties
  ServiceModel copyWith({
    String? name,
    double? price,
    String? category,
    String? barber,
    DateTime? serviceDateTime,
  }) {
    return ServiceModel(
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      barber: barber ?? this.barber,
      serviceDateTime: serviceDateTime ?? this.serviceDateTime,
    );
  }
}
