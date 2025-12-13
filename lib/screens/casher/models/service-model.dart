class ServiceModel {
  final int id;
  final String name;
  final double price;
  final String category;
  final String image;
  String? barber;
  int? employeeId;
  DateTime? serviceDateTime;

  ServiceModel({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.image,
    this.barber,
    this.employeeId,
    this.serviceDateTime,
  });

  String? get employeeName => barber;

  // Copy with method for updating properties
  ServiceModel copyWith({
    int? id,
    String? name,
    double? price,
    String? category,
    String? image,
    String? barber,
    int? employeeId,
    DateTime? serviceDateTime,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      image: image ?? this.image,
      barber: barber ?? this.barber,
      employeeId: employeeId ?? this.employeeId,
      serviceDateTime: serviceDateTime ?? this.serviceDateTime,
    );
  }
}
