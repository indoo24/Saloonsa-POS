class ServiceModel {
  final String name;
  final double price;
  final String category;
  String? barber;

  ServiceModel({
    required this.name,
    required this.price,
    required this.category,
    this.barber,
  });

  get employeeName => null;
}
