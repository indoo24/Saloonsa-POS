/// Service/Product model for API integration
/// Represents a service or product provided by the salon
class Service {
  final int id;
  final String name;
  final String? description;
  final String? code;
  final int isService; // 1 for service, 0 for product
  final int? mainCategoryId;
  final String? mainCategoryName;
  final Map<String, dynamic>? category; // Category object from API
  final String? image;
  final double? price;

  Service({
    required this.id,
    required this.name,
    this.description,
    this.code,
    this.isService = 1,
    this.mainCategoryId,
    this.mainCategoryName,
    this.category,
    this.image,
    this.price,
  });

  /// Get category name from either mainCategoryName or category object
  String? get categoryName {
    if (mainCategoryName != null) return mainCategoryName;
    if (category != null && category!['name'] != null) {
      return category!['name'] as String;
    }
    return null;
  }

  factory Service.fromJson(Map<String, dynamic> json) {
    // Handle potential null or numeric types for id
    final id = json['id'];
    final parsedId = id is int ? id : (id is String ? int.tryParse(id) : null);

    if (parsedId == null) {
      throw Exception('Service ID is required and must be a valid integer');
    }

    // Parse price safely - try multiple possible field names
    // Priority: customer_price > last_cost > sale_price > cost_price
    double? parsedPrice;
    final priceFields = [
      'customer_price',
      'last_cost',
      'sale_price',
      'cost_price',
      'price',
      'selling_price',
      'unit_price',
      'amount',
    ];
    for (final field in priceFields) {
      if (json[field] != null) {
        final priceValue = json[field];
        double? tempPrice;
        if (priceValue is num) {
          tempPrice = priceValue.toDouble();
        } else if (priceValue is String) {
          tempPrice = double.tryParse(priceValue);
        }
        // Only use non-zero prices
        if (tempPrice != null && tempPrice > 0) {
          parsedPrice = tempPrice;
          break;
        }
      }
    }

    // Parse image safely - try multiple possible field names
    // Priority: img is the actual field used by the API
    String? parsedImage;
    final imageFields = [
      'img',
      'image',
      'photo',
      'image_url',
      'picture',
      'thumbnail',
      'icon',
    ];
    for (final field in imageFields) {
      if (json[field] != null && json[field].toString().isNotEmpty) {
        String imageValue = json[field].toString();
        // Convert relative path to full URL if needed
        if (imageValue.startsWith('/storage/')) {
          imageValue = 'http://10.0.2.2:8000$imageValue';
        }
        parsedImage = imageValue;
        break;
      }
    }

    return Service(
      id: parsedId,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      code: json['code']?.toString(),
      isService: json['is_service'] is int ? json['is_service'] as int : 1,
      mainCategoryId: json['main_category_id'] is int
          ? json['main_category_id'] as int
          : null,
      mainCategoryName: json['main_category_name']?.toString(),
      category: json['category'] is Map
          ? json['category'] as Map<String, dynamic>?
          : null,
      image: parsedImage,
      price: parsedPrice,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'code': code,
      'is_service': isService,
      'main_category_id': mainCategoryId,
      'main_category_name': mainCategoryName,
      'category': category,
      'image': image,
      'price': price,
    };
  }
}
