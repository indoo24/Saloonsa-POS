# API Endpoint: Employees

## 📋 Overview

This document describes the Employee API endpoints for managing salon employees/staff members.

---

## 🔗 Endpoints

### Base URL
```
http://127.0.0.1:8000/api
```

All endpoints require authentication except where noted.

---

## 1️⃣ Get All Employees

**Endpoint:** `GET /api/employees`  
**Authentication:** ✅ Required (Bearer Token)

### Request Headers
```http
Content-Type: application/json
Accept: application/json
Authorization: Bearer {your_token_here}
```

### Success Response (200 OK)
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Ahmed Mohamed",
      "mobile": "01234567890",
      "salary": 3000,
      "day_salary": 100,
      "working_days": 26,
      "type": "normal",
      "percent": 5,
      "manager_id": null,
      "target": 10000,
      "note": "Senior stylist",
      "is_active": true
    },
    {
      "id": 2,
      "name": "Sara Ali",
      "mobile": "01098765432",
      "salary": 2500,
      "day_salary": 85,
      "working_days": 26,
      "type": "normal",
      "percent": 3,
      "manager_id": null,
      "target": 8000,
      "note": null,
      "is_active": true
    }
  ]
}
```

### Error Response (401 Unauthorized)
```json
{
  "message": "Unauthenticated."
}
```

### Error Response (500 Server Error)
```json
{
  "success": false,
  "message": "Failed to retrieve employees",
  "error": "Error details"
}
```

---

## 2️⃣ Get Single Employee

**Endpoint:** `GET /api/employees/{id}`  
**Authentication:** ✅ Required (Bearer Token)

### URL Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | integer | Yes | Employee ID |

### Example Request
```
GET http://127.0.0.1:8000/api/employees/1
```

### Request Headers
```http
Content-Type: application/json
Accept: application/json
Authorization: Bearer {your_token_here}
```

### Success Response (200 OK)
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Ahmed Mohamed",
    "mobile": "01234567890",
    "salary": 3000,
    "day_salary": 100,
    "working_days": 26,
    "type": "normal",
    "percent": 5,
    "manager_id": null,
    "target": 10000,
    "note": "Senior stylist",
    "is_active": true
  }
}
```

### Error Response (404 Not Found)
```json
{
  "success": false,
  "message": "Employee not found"
}
```

---

## 3️⃣ Create Employee

**Endpoint:** `POST /api/employees`  
**Authentication:** ✅ Required (Bearer Token)

### Request Headers
```http
Content-Type: application/json
Accept: application/json
Authorization: Bearer {your_token_here}
```

### Request Body
```json
{
  "name": "Ahmed Mohamed",
  "mobile": "01234567890",
  "salary": 3000,
  "day_salary": 100,
  "working_days": 26,
  "type": "normal",
  "percent": 5,
  "manager_id": null,
  "target": 10000,
  "note": "Senior stylist"
}
```

### Request Parameters

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | string | ✅ Yes | Employee name (max 255 characters) |
| mobile | string | No | Mobile number (max 20 characters) |
| salary | number | No | Monthly salary (default: 0) |
| day_salary | number | No | Daily salary (default: 0) |
| working_days | integer | No | Working days per month (default: 0) |
| type | string | No | Employee type: normal, manager, admin (default: normal) |
| percent | number | No | Commission percentage 0-100 (default: 0) |
| manager_id | integer | No | Manager's employee ID |
| target | number | No | Sales target (default: 0) |
| note | string | No | Notes about employee (max 500 characters) |

### Success Response (201 Created)
```json
{
  "success": true,
  "message": "Employee created successfully",
  "data": {
    "id": 3,
    "name": "Ahmed Mohamed",
    "mobile": "01234567890",
    "salary": 3000,
    "day_salary": 100,
    "working_days": 26,
    "type": "normal",
    "percent": 5,
    "manager_id": null,
    "target": 10000,
    "note": "Senior stylist",
    "is_active": true
  }
}
```

### Error Response (422 Validation Error)
```json
{
  "success": false,
  "message": "Validation Error",
  "errors": {
    "name": ["The name field is required."],
    "type": ["The selected type is invalid."]
  }
}
```

---

## 4️⃣ Update Employee

**Endpoint:** `PUT /api/employees/{id}`  
**Authentication:** ✅ Required (Bearer Token)

### URL Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | integer | Yes | Employee ID |

### Example Request
```
PUT http://127.0.0.1:8000/api/employees/1
```

### Request Headers
```http
Content-Type: application/json
Accept: application/json
Authorization: Bearer {your_token_here}
```

### Request Body
```json
{
  "name": "Ahmed Mohamed Updated",
  "salary": 3500,
  "percent": 7
}
```

### Request Parameters
All fields are optional. Only send the fields you want to update.

| Field | Type | Description |
|-------|------|-------------|
| name | string | Employee name (max 255 characters) |
| mobile | string | Mobile number (max 20 characters) |
| salary | number | Monthly salary |
| day_salary | number | Daily salary |
| working_days | integer | Working days per month |
| type | string | Employee type: normal, manager, admin |
| percent | number | Commission percentage 0-100 |
| manager_id | integer | Manager's employee ID |
| target | number | Sales target |
| note | string | Notes about employee (max 500 characters) |

### Success Response (200 OK)
```json
{
  "success": true,
  "message": "Employee updated successfully",
  "data": {
    "id": 1,
    "name": "Ahmed Mohamed Updated",
    "mobile": "01234567890",
    "salary": 3500,
    "day_salary": 100,
    "working_days": 26,
    "type": "normal",
    "percent": 7,
    "manager_id": null,
    "target": 10000,
    "note": "Senior stylist",
    "is_active": true
  }
}
```

### Error Response (404 Not Found)
```json
{
  "success": false,
  "message": "Employee not found"
}
```

---

## 5️⃣ Delete Employee

**Endpoint:** `DELETE /api/employees/{id}`  
**Authentication:** ✅ Required (Bearer Token)

### URL Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | integer | Yes | Employee ID |

### Example Request
```
DELETE http://127.0.0.1:8000/api/employees/1
```

### Request Headers
```http
Content-Type: application/json
Accept: application/json
Authorization: Bearer {your_token_here}
```

### Success Response (200 OK)
```json
{
  "success": true,
  "message": "Employee deleted successfully"
}
```

### Error Response (404 Not Found)
```json
{
  "success": false,
  "message": "Employee not found"
}
```

**Note:** This is a soft delete. The employee is marked as deleted but remains in the database.

---

## 📱 Flutter/Dart Integration Example

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Employee {
  final int id;
  final String name;
  final String? mobile;
  final double salary;
  final double daySalary;
  final int workingDays;
  final String type;
  final double percent;
  final int? managerId;
  final double target;
  final String? note;
  final bool isActive;
  
  Employee({
    required this.id,
    required this.name,
    this.mobile,
    required this.salary,
    required this.daySalary,
    required this.workingDays,
    required this.type,
    required this.percent,
    this.managerId,
    required this.target,
    this.note,
    required this.isActive,
  });
  
  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      name: json['name'],
      mobile: json['mobile'],
      salary: (json['salary'] ?? 0).toDouble(),
      daySalary: (json['day_salary'] ?? 0).toDouble(),
      workingDays: json['working_days'] ?? 0,
      type: json['type'] ?? 'normal',
      percent: (json['percent'] ?? 0).toDouble(),
      managerId: json['manager_id'],
      target: (json['target'] ?? 0).toDouble(),
      note: json['note'],
      isActive: json['is_active'] ?? true,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mobile': mobile,
      'salary': salary,
      'day_salary': daySalary,
      'working_days': workingDays,
      'type': type,
      'percent': percent,
      'manager_id': managerId,
      'target': target,
      'note': note,
    };
  }
}

class EmployeeApiService {
  static const String BASE_URL = 'http://127.0.0.1:8000/api';
  
  // Get auth token
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  // Get all employees
  static Future<List<Employee>> getEmployees() async {
    final token = await _getToken();
    if (token == null) throw Exception('No authentication token found');
    
    final url = Uri.parse('$BASE_URL/employees');
    
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        List<Employee> employees = [];
        for (var employeeJson in data['data']) {
          employees.add(Employee.fromJson(employeeJson));
        }
        return employees;
      } else {
        throw Exception('Failed to parse employees');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - Please login again');
    } else {
      throw Exception('Failed to load employees: ${response.statusCode}');
    }
  }
  
  // Get single employee
  static Future<Employee> getEmployee(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No authentication token found');
    
    final url = Uri.parse('$BASE_URL/employees/$id');
    
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return Employee.fromJson(data['data']);
      } else {
        throw Exception('Failed to parse employee');
      }
    } else if (response.statusCode == 404) {
      throw Exception('Employee not found');
    } else {
      throw Exception('Failed to load employee: ${response.statusCode}');
    }
  }
  
  // Create employee
  static Future<Employee> createEmployee(Employee employee) async {
    final token = await _getToken();
    if (token == null) throw Exception('No authentication token found');
    
    final url = Uri.parse('$BASE_URL/employees');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(employee.toJson()),
    );
    
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return Employee.fromJson(data['data']);
      } else {
        throw Exception('Failed to parse employee');
      }
    } else if (response.statusCode == 422) {
      final data = jsonDecode(response.body);
      throw Exception('Validation error: ${data['message']}');
    } else {
      throw Exception('Failed to create employee: ${response.statusCode}');
    }
  }
  
  // Update employee
  static Future<Employee> updateEmployee(int id, Map<String, dynamic> updates) async {
    final token = await _getToken();
    if (token == null) throw Exception('No authentication token found');
    
    final url = Uri.parse('$BASE_URL/employees/$id');
    
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(updates),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return Employee.fromJson(data['data']);
      } else {
        throw Exception('Failed to parse employee');
      }
    } else if (response.statusCode == 404) {
      throw Exception('Employee not found');
    } else {
      throw Exception('Failed to update employee: ${response.statusCode}');
    }
  }
  
  // Delete employee
  static Future<void> deleteEmployee(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No authentication token found');
    
    final url = Uri.parse('$BASE_URL/employees/$id');
    
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 404) {
      throw Exception('Employee not found');
    } else {
      throw Exception('Failed to delete employee: ${response.statusCode}');
    }
  }
}

// Usage Example in Flutter Widget
class EmployeesScreen extends StatefulWidget {
  @override
  _EmployeesScreenState createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  List<Employee> _employees = [];
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }
  
  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final employees = await EmployeeApiService.getEmployees();
      setState(() {
        _employees = employees;
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
        appBar: AppBar(title: Text('Employees')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Employees')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadEmployees,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(title: Text('Employees')),
      body: ListView.builder(
        itemCount: _employees.length,
        itemBuilder: (context, index) {
          final employee = _employees[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text(employee.name[0]),
            ),
            title: Text(employee.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employee.mobile ?? 'No mobile'),
                Text('Salary: ${employee.salary} - Type: ${employee.type}'),
              ],
            ),
            trailing: employee.isActive 
                ? Icon(Icons.check_circle, color: Colors.green)
                : Icon(Icons.cancel, color: Colors.red),
            onTap: () {
              // Navigate to employee details
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmployeeDetailScreen(employeeId: employee.id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add employee screen
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
```

---

## ✅ Testing with Postman

### 1. Get All Employees
- **Method:** GET
- **URL:** `http://127.0.0.1:8000/api/employees`
- **Headers:**
  - `Accept: application/json`
  - `Content-Type: application/json`
  - `Authorization: Bearer {your_token}`

### 2. Create Employee
- **Method:** POST
- **URL:** `http://127.0.0.1:8000/api/employees`
- **Headers:**
  - `Accept: application/json`
  - `Content-Type: application/json`
  - `Authorization: Bearer {your_token}`
- **Body (raw JSON):**
```json
{
  "name": "Test Employee",
  "mobile": "01234567890",
  "salary": 3000,
  "type": "normal"
}
```

---

## 📝 Notes

- All endpoints require authentication (Bearer token from login)
- Employee deletion is soft delete (records remain in database)
- `is_active` indicates if employee is active (not deleted)
- Employee types: `normal`, `manager`, `admin`
- Commission `percent` should be between 0 and 100
- All numeric fields accept decimals
- Mobile field accepts strings to preserve leading zeros

---

*Last Updated: November 29, 2025*
