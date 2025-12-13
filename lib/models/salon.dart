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
    // Handle potential null or numeric types for id
    final id = json['id'];
    final parsedId = id is int ? id : (id is String ? int.tryParse(id) : null);
    
    if (parsedId == null) {
      throw Exception('Salon ID is required and must be a valid integer');
    }

    return Salon(
      id: parsedId,
      name: json['name']?.toString() ?? '',
      mobile: json['mobile']?.toString(),
      note: json['note']?.toString(),
      subdomain: json['subdomain']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
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
