/// App Settings Model
/// Stores business information, invoice settings, and tax configuration
class AppSettings {
  // Business Information
  final String businessName;
  final String address;
  final String phoneNumber;
  final String taxNumber;

  // Invoice / Receipt Settings
  final String invoiceNotes;

  // Tax Settings
  final double taxValue; // Tax percentage (e.g., 15 for 15%)
  final bool pricesIncludeTax; // Whether displayed prices include tax

  const AppSettings({
    this.businessName = 'صالون الشباب',
    this.address = 'المدينة المنورة، حي النخيل',
    this.phoneNumber = '0565656565',
    this.taxNumber = '',
    this.invoiceNotes = 'شكراً لزيارتكم',
    this.taxValue = 15.0,
    this.pricesIncludeTax = false,
  });

  /// Create settings from JSON (for SharedPreferences)
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      businessName: json['businessName'] as String? ?? 'صالون الشباب',
      address: json['address'] as String? ?? 'المدينة المنورة، حي النخيل',
      phoneNumber: json['phoneNumber'] as String? ?? '0565656565',
      taxNumber: json['taxNumber'] as String? ?? '',
      invoiceNotes: json['invoiceNotes'] as String? ?? 'شكراً لزيارتكم',
      taxValue: (json['taxValue'] as num?)?.toDouble() ?? 15.0,
      pricesIncludeTax: json['pricesIncludeTax'] as bool? ?? false,
    );
  }

  /// Convert settings to JSON (for SharedPreferences)
  Map<String, dynamic> toJson() {
    return {
      'businessName': businessName,
      'address': address,
      'phoneNumber': phoneNumber,
      'taxNumber': taxNumber,
      'invoiceNotes': invoiceNotes,
      'taxValue': taxValue,
      'pricesIncludeTax': pricesIncludeTax,
    };
  }

  /// Create a copy with optional parameter changes
  AppSettings copyWith({
    String? businessName,
    String? address,
    String? phoneNumber,
    String? taxNumber,
    String? invoiceNotes,
    double? taxValue,
    bool? pricesIncludeTax,
  }) {
    return AppSettings(
      businessName: businessName ?? this.businessName,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      taxNumber: taxNumber ?? this.taxNumber,
      invoiceNotes: invoiceNotes ?? this.invoiceNotes,
      taxValue: taxValue ?? this.taxValue,
      pricesIncludeTax: pricesIncludeTax ?? this.pricesIncludeTax,
    );
  }

  /// Calculate tax multiplier (for calculations)
  double get taxMultiplier => taxValue / 100;

  @override
  String toString() {
    return 'AppSettings(businessName: $businessName, taxValue: $taxValue%, pricesIncludeTax: $pricesIncludeTax)';
  }
}
