/// Payment method model
class PaymentMethod {
  final int id;
  final String name;
  final String nameAr;
  final String type;
  final bool enabled;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.type,
    required this.enabled,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as int,
      name: json['name'] as String,
      nameAr: json['name_ar'] as String,
      type: json['type'] as String,
      enabled: json['enabled'] == true || json['enabled'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_ar': nameAr,
      'type': type,
      'enabled': enabled,
    };
  }

  @override
  String toString() => 'PaymentMethod(id: $id, name: $name, type: $type)';
}
