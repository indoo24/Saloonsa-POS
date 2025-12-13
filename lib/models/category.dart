/// Category model for API integration
class Category {
  final int id;
  final String name;
  final String? description;
  final String? image;
  final int? parentId;
  final int? order;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.image,
    this.parentId,
    this.order,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    // Handle potential null or numeric types for id
    final id = json['id'];
    final parsedId = id is int ? id : (id is String ? int.tryParse(id) : null);
    
    if (parsedId == null) {
      throw Exception('Category ID is required and must be a valid integer');
    }

    return Category(
      id: parsedId,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      image: json['image']?.toString(),
      parentId: json['parent_id'] is int ? json['parent_id'] as int : null,
      order: json['order'] is int ? json['order'] as int : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'parent_id': parentId,
      'order': order,
    };
  }

  @override
  String toString() => 'Category(id: $id, name: $name)';
}
