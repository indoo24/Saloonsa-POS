/// Customer model for API integration
class CustomerModel {
  final int id;
  final String name;
  final String? mobile;
  final String? mobile2;
  final String? address;
  final int? regionId;
  final int? areaId;
  final String? taxNumber;
  final String? birthdate;
  final String? eventDate;
  final double? balance;

  CustomerModel({
    required this.id,
    required this.name,
    this.mobile,
    this.mobile2,
    this.address,
    this.regionId,
    this.areaId,
    this.taxNumber,
    this.birthdate,
    this.eventDate,
    this.balance,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as int,
      name: json['name'] as String,
      mobile: json['mobile'] as String?,
      mobile2: json['mobile2'] as String?,
      address: json['address'] as String?,
      regionId: json['region_id'] as int?,
      areaId: json['area_id'] as int?,
      taxNumber: json['taxnumber'] as String?,
      birthdate: json['birthdate'] as String?,
      eventDate: json['eventdate'] as String?,
      balance: json['balance'] != null 
          ? (json['balance'] is int 
              ? (json['balance'] as int).toDouble() 
              : json['balance'] as double)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'mobile2': mobile2,
      'address': address,
      'region_id': regionId,
      'area_id': areaId,
      'taxnumber': taxNumber,
      'birthdate': birthdate,
      'eventdate': eventDate,
      'balance': balance,
    };
  }

  /// Convert to Customer (for backward compatibility with existing code)
  dynamic toCustomer() {
    // This will work with the existing Customer class
    return {
      'id': id,
      'name': name,
      'phone': mobile,
      'customerId': 'CUST$id',
    };
  }

  @override
  String toString() => 'CustomerModel(id: $id, name: $name, mobile: $mobile)';
}
