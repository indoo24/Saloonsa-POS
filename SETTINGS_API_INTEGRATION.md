# Settings API Integration Guide

## Overview
The Settings API provides access to salon configuration and settings data. This includes site information, contact details, tax settings, and other configurable parameters.

---

## Base URL
```
http://localhost:8000/api
```

---

## Authentication
All endpoints require authentication using Laravel Sanctum Bearer token.

```
Authorization: Bearer {token}
```

Get token from `/api/auth/login` endpoint.

---

## Endpoints

### 1. Get All Settings
Retrieve all settings from the database.

**Endpoint:** `GET /api/settings`

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Site Name",
      "key": "SiteName",
      "value": "صالون الشباب",
      "subscription_expires_at": null
    },
    {
      "id": 2,
      "name": "Address",
      "key": "Address",
      "value": "المدينة المنورة",
      "subscription_expires_at": null
    },
    {
      "id": 3,
      "name": "Mobile",
      "key": "mobile",
      "value": "05656565656",
      "subscription_expires_at": null
    }
    // ... more settings
  ]
}
```

---

### 2. Get Salon Settings (Formatted)
Retrieve commonly used salon settings in a clean, formatted structure.

**Endpoint:** `GET /api/settings/salon`

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "site_name": "صالون الشباب",
    "site_name_en": "Youth Salon",
    "address": "المدينة المنورة",
    "address_en": "Medina",
    "mobile": "05656565656",
    "email": "info@salon.com",
    "logo": "http://localhost:8000/storage/logo.png",
    "subdomain": "saloonsa1,test1",
    "tax_number": "310123456789003",
    "currency": "SAR",
    "timezone": "Asia/Riyadh",
    "subscription_expires_at": "2025-12-31 23:59:59"
  }
}
```

---

### 3. Get Setting by Key
Retrieve a specific setting by its key.

**Endpoint:** `GET /api/settings/{key}`

**Path Parameters:**
- `key` (string, required) - The setting key (e.g., "SiteName", "mobile", "tax_number")

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Example Request:**
```
GET /api/settings/SiteName
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Site Name",
    "key": "SiteName",
    "value": "صالون الشباب",
    "subscription_expires_at": null
  }
}
```

**Error Response:** `404 Not Found`
```json
{
  "success": false,
  "message": "Setting not found"
}
```

---

### 4. Create Setting
Create a new setting.

**Endpoint:** `POST /api/settings`

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "key": "custom_setting",
  "value": "Custom value",
  "name": "Custom Setting Name"
}
```

**Validation Rules:**
- `key` (required, string, max:255, unique)
- `value` (required, string)
- `name` (optional, string, max:255)

**Response:** `201 Created`
```json
{
  "success": true,
  "message": "Setting created successfully",
  "data": {
    "id": 44,
    "name": "Custom Setting Name",
    "key": "custom_setting",
    "value": "Custom value",
    "subscription_expires_at": null
  }
}
```

**Error Response:** `422 Unprocessable Entity`
```json
{
  "success": false,
  "message": "Validation Error",
  "errors": {
    "key": ["The key has already been taken."]
  }
}
```

---

### 5. Update Setting
Update an existing setting by key.

**Endpoint:** `PUT /api/settings/{key}`

**Path Parameters:**
- `key` (string, required) - The setting key to update

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "value": "Updated value",
  "name": "Updated Name"
}
```

**Validation Rules:**
- `value` (required, string)
- `name` (optional, string, max:255)

**Example Request:**
```
PUT /api/settings/mobile
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Setting updated successfully",
  "data": {
    "id": 3,
    "name": "Mobile Number",
    "key": "mobile",
    "value": "0599999999",
    "subscription_expires_at": null
  }
}
```

**Error Response:** `404 Not Found`
```json
{
  "success": false,
  "message": "Setting not found"
}
```

---

### 6. Delete Setting
Delete a setting by key.

**Endpoint:** `DELETE /api/settings/{key}`

**Path Parameters:**
- `key` (string, required) - The setting key to delete

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Example Request:**
```
DELETE /api/settings/custom_setting
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Setting deleted successfully"
}
```

**Error Response:** `404 Not Found`
```json
{
  "success": false,
  "message": "Setting not found"
}
```

---

## Common Setting Keys

Here are the most commonly used setting keys in the system:

| Key | Description | Example Value |
|-----|-------------|---------------|
| `SiteName` | Salon name (Arabic) | "صالون الشباب" |
| `SiteName_en` | Salon name (English) | "Youth Salon" |
| `Address` | Address (Arabic) | "المدينة المنورة" |
| `Address_en` | Address (English) | "Medina" |
| `mobile` | Contact phone number | "05656565656" |
| `email` | Contact email | "info@salon.com" |
| `logo` | Logo image URL | "http://..." |
| `subdomain` | Salon subdomain(s) | "saloonsa1,test1" |
| `tax_number` | VAT/Tax registration number | "310123456789003" |
| `currency` | Currency code | "SAR" |
| `timezone` | Timezone | "Asia/Riyadh" |
| `show_cost_price` | Show cost price (1/0) | "1" |
| `canChangePrice` | Can change price (1/0) | "1" |
| `subscription_expires_at` | Subscription expiry date | "2025-12-31 23:59:59" |

---

## Flutter Integration Example

### Data Model

```dart
// models/setting.dart
class Setting {
  final int id;
  final String name;
  final String key;
  final String value;
  final DateTime? subscriptionExpiresAt;

  Setting({
    required this.id,
    required this.name,
    required this.key,
    required this.value,
    this.subscriptionExpiresAt,
  });

  factory Setting.fromJson(Map<String, dynamic> json) {
    return Setting(
      id: json['id'],
      name: json['name'] ?? '',
      key: json['key'],
      value: json['value'] ?? '',
      subscriptionExpiresAt: json['subscription_expires_at'] != null
          ? DateTime.parse(json['subscription_expires_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'key': key,
      'value': value,
      'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
    };
  }
}

// models/salon_settings.dart
class SalonSettings {
  final String siteName;
  final String siteNameEn;
  final String address;
  final String addressEn;
  final String mobile;
  final String email;
  final String logo;
  final String subdomain;
  final String taxNumber;
  final String currency;
  final String timezone;
  final DateTime? subscriptionExpiresAt;

  SalonSettings({
    required this.siteName,
    required this.siteNameEn,
    required this.address,
    required this.addressEn,
    required this.mobile,
    required this.email,
    required this.logo,
    required this.subdomain,
    required this.taxNumber,
    required this.currency,
    required this.timezone,
    this.subscriptionExpiresAt,
  });

  factory SalonSettings.fromJson(Map<String, dynamic> json) {
    return SalonSettings(
      siteName: json['site_name'] ?? '',
      siteNameEn: json['site_name_en'] ?? '',
      address: json['address'] ?? '',
      addressEn: json['address_en'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      logo: json['logo'] ?? '',
      subdomain: json['subdomain'] ?? '',
      taxNumber: json['tax_number'] ?? '',
      currency: json['currency'] ?? 'SAR',
      timezone: json['timezone'] ?? 'Asia/Riyadh',
      subscriptionExpiresAt: json['subscription_expires_at'] != null
          ? DateTime.parse(json['subscription_expires_at'])
          : null,
    );
  }
}
```

### Service Class

```dart
// services/settings_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/setting.dart';
import '../models/salon_settings.dart';

class SettingsService {
  final String baseUrl;
  final String token;

  SettingsService({required this.baseUrl, required this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // Get all settings
  Future<List<Setting>> getAllSettings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/settings'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return (data['data'] as List)
            .map((item) => Setting.fromJson(item))
            .toList();
      }
      throw Exception(data['message'] ?? 'Failed to load settings');
    }
    throw Exception('Failed to load settings');
  }

  // Get salon settings (formatted)
  Future<SalonSettings> getSalonSettings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/settings/salon'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return SalonSettings.fromJson(data['data']);
      }
      throw Exception(data['message'] ?? 'Failed to load salon settings');
    }
    throw Exception('Failed to load salon settings');
  }

  // Get setting by key
  Future<Setting> getSettingByKey(String key) async {
    final response = await http.get(
      Uri.parse('$baseUrl/settings/$key'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return Setting.fromJson(data['data']);
      }
      throw Exception(data['message'] ?? 'Setting not found');
    }
    throw Exception('Failed to load setting');
  }

  // Create setting
  Future<Setting> createSetting({
    required String key,
    required String value,
    String? name,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/settings'),
      headers: _headers,
      body: json.encode({
        'key': key,
        'value': value,
        if (name != null) 'name': name,
      }),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      if (data['success']) {
        return Setting.fromJson(data['data']);
      }
      throw Exception(data['message'] ?? 'Failed to create setting');
    }
    throw Exception('Failed to create setting');
  }

  // Update setting
  Future<Setting> updateSetting({
    required String key,
    required String value,
    String? name,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/settings/$key'),
      headers: _headers,
      body: json.encode({
        'value': value,
        if (name != null) 'name': name,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return Setting.fromJson(data['data']);
      }
      throw Exception(data['message'] ?? 'Failed to update setting');
    }
    throw Exception('Failed to update setting');
  }

  // Delete setting
  Future<bool> deleteSetting(String key) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/settings/$key'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'] ?? false;
    }
    return false;
  }
}
```

### Usage Example

```dart
// Example: Display salon settings in app
import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../models/salon_settings.dart';

class SalonInfoScreen extends StatefulWidget {
  @override
  _SalonInfoScreenState createState() => _SalonInfoScreenState();
}

class _SalonInfoScreenState extends State<SalonInfoScreen> {
  late SettingsService _settingsService;
  SalonSettings? _salonSettings;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _settingsService = SettingsService(
      baseUrl: 'http://localhost:8000/api',
      token: 'your-auth-token-here',
    );
    _loadSalonSettings();
  }

  Future<void> _loadSalonSettings() async {
    try {
      final settings = await _settingsService.getSalonSettings();
      setState(() {
        _salonSettings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Salon Information')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Salon Information')),
        body: Center(child: Text('Error: $_error')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_salonSettings!.siteName),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            if (_salonSettings!.logo.isNotEmpty)
              Center(
                child: Image.network(
                  _salonSettings!.logo,
                  height: 100,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.store, size: 100);
                  },
                ),
              ),
            SizedBox(height: 20),

            // Salon Name
            _buildInfoCard(
              icon: Icons.store,
              title: 'Salon Name',
              value: _salonSettings!.siteName,
              subtitle: _salonSettings!.siteNameEn,
            ),

            // Address
            _buildInfoCard(
              icon: Icons.location_on,
              title: 'Address',
              value: _salonSettings!.address,
              subtitle: _salonSettings!.addressEn,
            ),

            // Contact
            _buildInfoCard(
              icon: Icons.phone,
              title: 'Mobile',
              value: _salonSettings!.mobile,
            ),

            _buildInfoCard(
              icon: Icons.email,
              title: 'Email',
              value: _salonSettings!.email,
            ),

            // Tax Number
            _buildInfoCard(
              icon: Icons.receipt,
              title: 'Tax Number',
              value: _salonSettings!.taxNumber,
            ),

            // Currency & Timezone
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.monetization_on,
                    title: 'Currency',
                    value: _salonSettings!.currency,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.access_time,
                    title: 'Timezone',
                    value: _salonSettings!.timezone,
                  ),
                ),
              ],
            ),

            // Subscription
            if (_salonSettings!.subscriptionExpiresAt != null)
              _buildInfoCard(
                icon: Icons.calendar_today,
                title: 'Subscription Expires',
                value: _salonSettings!.subscriptionExpiresAt!
                    .toString()
                    .split(' ')[0],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 16, color: Colors.black)),
            if (subtitle != null && subtitle.isNotEmpty)
              Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
```

---

## Error Handling

All endpoints return standardized error responses:

**400 Bad Request:**
```json
{
  "success": false,
  "message": "Invalid request data"
}
```

**401 Unauthorized:**
```json
{
  "success": false,
  "message": "Unauthenticated"
}
```

**404 Not Found:**
```json
{
  "success": false,
  "message": "Setting not found"
}
```

**422 Validation Error:**
```json
{
  "success": false,
  "message": "Validation Error",
  "errors": {
    "key": ["The key field is required."],
    "value": ["The value field is required."]
  }
}
```

**500 Internal Server Error:**
```json
{
  "success": false,
  "message": "Failed to retrieve settings",
  "error": "Detailed error message"
}
```

---

## Best Practices

1. **Cache Settings Locally**: Store salon settings in local storage/SharedPreferences after first fetch to reduce API calls

2. **Use Salon Settings Endpoint**: Use `/api/settings/salon` instead of `/api/settings` when you only need common salon information

3. **Handle Subscription Expiry**: Check `subscription_expires_at` to show warnings before subscription expires

4. **Validate Before Update**: Validate setting values on the client side before sending update requests

5. **Error Handling**: Always implement proper error handling for network failures and invalid responses

6. **Refresh Strategy**: Implement pull-to-refresh to update settings when needed

---

## Testing with cURL

```bash
# Login first
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"demo","password":"123456"}'

# Get all settings
curl -X GET http://localhost:8000/api/settings \
  -H "Authorization: Bearer YOUR_TOKEN"

# Get salon settings
curl -X GET http://localhost:8000/api/settings/salon \
  -H "Authorization: Bearer YOUR_TOKEN"

# Get specific setting
curl -X GET http://localhost:8000/api/settings/SiteName \
  -H "Authorization: Bearer YOUR_TOKEN"

# Update setting
curl -X PUT http://localhost:8000/api/settings/mobile \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"value":"0599999999"}'
```

---

## Notes

- All endpoints require authentication except public routes
- Settings with `key` values are unique in the database
- The `subscription_expires_at` field is nullable
- Logo and other file URLs are fully qualified URLs
- Currency defaults to "SAR" if not set
- Timezone defaults to "Asia/Riyadh" if not set
- The subdomain field can contain multiple comma-separated values

---

## Support

For issues or questions, please contact the development team or refer to the main API documentation.
