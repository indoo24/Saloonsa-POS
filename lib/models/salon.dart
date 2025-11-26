/// Salon model representing a salon/store
class Salon {
  final int id;
  final String name;
  final String? mobile;
  final String? note;
  final String subdomain;
  final String? createdAt;

  Salon({
    required this.id,
    required this.name,
    this.mobile,
    this.note,
    required this.subdomain,
    this.createdAt,
  });

  factory Salon.fromJson(Map<String, dynamic> json) {
    return Salon(
      id: json['id'] as int,
      name: json['name'] as String,
      mobile: json['mobile'] as String?,
      note: json['note'] as String?,
      subdomain: json['subdomain'] as String,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'note': note,
      'subdomain': subdomain,
      'created_at': createdAt,
    };
  }

  @override
  String toString() => 'Salon(id: $id, name: $name, subdomain: $subdomain)';
}
