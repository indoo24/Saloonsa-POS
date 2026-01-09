/// Customer model for API integration (Persons endpoint)
class CustomerModel {
  final int id;
  final String name;
  final String type; // client, supplier, or sales
  final String? mobile;
  final String? mobile2;
  final String? address;
  final int? regionId;
  final int? areaId;
  final Map<String, dynamic>? region; // Region object from API
  final Map<String, dynamic>? area; // Area object from API
  final String? taxNumber;
  final String? birthdate;
  final String? eventDate;
  final double? balance;

  CustomerModel({
    required this.id,
    required this.name,
    this.type = 'client',
    this.mobile,
    this.mobile2,
    this.address,
    this.regionId,
    this.areaId,
    this.region,
    this.area,
    this.taxNumber,
    this.birthdate,
    this.eventDate,
    this.balance,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    // Handle potential null or numeric types for id
    final id = json['id'];
    final parsedId = id is int ? id : (id is String ? int.tryParse(id) : null);

    if (parsedId == null) {
      throw Exception('Customer ID is required and must be a valid integer');
    }

    return CustomerModel(
      id: parsedId,
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'client',
      mobile: json['mobile']?.toString(),
      mobile2: json['mobile2']?.toString(),
      address: json['address']?.toString(),
      regionId: json['region_id'] is int ? json['region_id'] as int : null,
      areaId: json['area_id'] is int ? json['area_id'] as int : null,
      region: json['region'] is Map
          ? json['region'] as Map<String, dynamic>?
          : null,
      area: json['area'] is Map ? json['area'] as Map<String, dynamic>? : null,
      taxNumber: json['taxnumber']?.toString(),
      birthdate: json['birthdate']?.toString(),
      eventDate: json['eventdate']?.toString(),
      balance: json['balance'] != null
          ? (json['balance'] is int
                ? (json['balance'] as int).toDouble()
                : json['balance'] is double
                ? json['balance'] as double
                : double.tryParse(json['balance'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'mobile': mobile,
      'mobile2': mobile2,
      'address': address,
      'region_id': regionId,
      'area_id': areaId,
      'region': region,
      'area': area,
      'taxnumber': taxNumber,
      'birthdate': birthdate,
      'eventdate': eventDate,
      'balance': balance,
    };
  }

  /// Convert to Customer (for backward compatibility with existing code)
  dynamic toCustomer() {
    // This will work with the existing Customer class
    return {'id': id, 'name': name, 'phone': mobile, 'customerId': 'CUST$id'};
  }

  @override
  String toString() => 'CustomerModel(id: $id, name: $name, mobile: $mobile)';
}
