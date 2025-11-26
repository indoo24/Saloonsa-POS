# Salon Management System - API Documentation

## Table of Contents
1. [Overview](#overview)
2. [Authentication](#authentication)
3. [Base URL](#base-url)
4. [Response Format](#response-format)
5. [Endpoints](#endpoints)
   - [Authentication](#authentication-endpoints)
   - [Salons](#salon-endpoints)
   - [Services](#service-endpoints)
   - [Service Categories](#service-category-endpoints)
   - [Customers](#customer-endpoints)
   - [Payment Methods](#payment-method-endpoints)
   - [Invoices](#invoice-endpoints)

---

## Overview

This API provides endpoints for managing a salon management system including authentication, services, customers, and invoicing functionality.

**API Version:** 1.0  
**Last Updated:** November 25, 2025

---

## Authentication

This API uses **Laravel Sanctum** for authentication. Most endpoints require authentication via Bearer token.

### How to authenticate:
1. Call the `/api/auth/login` endpoint to obtain a token
2. Include the token in subsequent requests using the `Authorization` header:
   ```
   Authorization: Bearer YOUR_TOKEN_HERE
   ```

---

## Base URL

```
http://10.0.2.2:8000/api
```

All endpoints listed below should be prefixed with the base URL.

---

## Response Format

All API responses follow a consistent JSON format:

### Success Response
```json
{
  "success": true,
  "message": "Operation successful",
  "data": {
    // Response data here
  }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error description",
  "error": "Detailed error message"
}
```

### Validation Error Response
```json
{
  "success": false,
  "message": "Validation Error",
  "errors": {
    "field_name": ["Error message 1", "Error message 2"]
  }
}
```

---

## Endpoints

## Authentication Endpoints

### 1. Login

Authenticate a user and receive an access token.

**Endpoint:** `POST /api/auth/login`

**Authentication Required:** No

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Request Parameters:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| email | string | Yes | User's email address |
| password | string | Yes | User's password (minimum 6 characters) |

**Success Response (200):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "user@example.com",
      "mobile": "+1234567890"
    },
    "token": "1|abcdefghijklmnopqrstuvwxyz1234567890"
  }
}
```

**Error Response (401):**
```json
{
  "success": false,
  "message": "Invalid email or password"
}
```

**Error Response (422):**
```json
{
  "success": false,
  "message": "Validation Error",
  "errors": {
    "email": ["The email field is required."],
    "password": ["The password field is required."]
  }
}
```

---

### 2. Logout

Revoke the current user's access token.

**Endpoint:** `POST /api/auth/logout`

**Authentication Required:** Yes

**Request Headers:**
```
Authorization: Bearer YOUR_TOKEN_HERE
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

**Error Response (500):**
```json
{
  "success": false,
  "message": "Logout failed",
  "error": "Error details"
}
```

---

### 3. Get Current User

Retrieve the authenticated user's information.

**Endpoint:** `GET /api/user`

**Authentication Required:** Yes

**Request Headers:**
```
Authorization: Bearer YOUR_TOKEN_HERE
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "John Doe",
    "email": "user@example.com",
    "mobile": "+1234567890"
  }
}
```

---

## Salon Endpoints

### 1. Get Salon by Subdomain

Retrieve salon information by subdomain.

**Endpoint:** `GET /api/salons/by-domain/{subdomain}`

**Authentication Required:** No

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| subdomain | string | Yes | Salon subdomain identifier |

**Example Request:**
```
GET /api/salons/by-domain/mysalon
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "My Salon",
    "mobile": "+1234567890",
    "note": "Premium salon services",
    "subdomain": "mysalon",
    "created_at": "2025-01-15 10:30:00"
  }
}
```

**Error Response (404):**
```json
{
  "success": false,
  "message": "Salon not found"
}
```

---

## Service Endpoints

### 1. Get All Services

Retrieve all services for a specific salon.

**Endpoint:** `GET /api/services`

**Authentication Required:** Yes

**Request Headers:**
```
Authorization: Bearer YOUR_TOKEN_HERE
```

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| salon_id | integer | Yes | ID of the salon |

**Example Request:**
```
GET /api/services?salon_id=1
```

**Success Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Haircut",
      "description": "Professional haircut service",
      "code": "SRV001",
      "main_category_id": 1,
      "main_category_name": "Hair Services",
      "sub_category_id": 2,
      "sub_category_name": "Cutting",
      "image": "https://example.com/storage/services/haircut.jpg"
    },
    {
      "id": 2,
      "name": "Hair Coloring",
      "description": "Professional hair coloring service",
      "code": "SRV002",
      "main_category_id": 1,
      "main_category_name": "Hair Services",
      "sub_category_id": 3,
      "sub_category_name": "Coloring",
      "image": null
    }
  ]
}
```

**Error Response (422):**
```json
{
  "success": false,
  "message": "Validation Error",
  "errors": {
    "salon_id": ["The salon id field is required."]
  }
}
```

---

### 2. Get Single Service

Retrieve details of a specific service by ID.

**Endpoint:** `GET /api/services/{id}`

**Authentication Required:** Yes

**Request Headers:**
```
Authorization: Bearer YOUR_TOKEN_HERE
```

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | integer | Yes | Service ID |

**Example Request:**
```
GET /api/services/1
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Haircut",
    "description": "Professional haircut service",
    "code": "SRV001",
    "main_category_id": 1,
    "main_category_name": "Hair Services",
    "sub_category_id": 2,
    "sub_category_name": "Cutting",
    "image": "https://example.com/storage/services/haircut.jpg"
  }
}
```

**Error Response (404):**
```json
{
  "success": false,
  "message": "Service not found"
}
```

---

## Service Category Endpoints

### 1. Get Service Categories

Retrieve all service categories for a specific salon.

**Endpoint:** `GET /api/service-categories`

**Authentication Required:** Yes

**Request Headers:**
```
Authorization: Bearer YOUR_TOKEN_HERE
```

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| salon_id | integer | Yes | ID of the salon |

**Example Request:**
```
GET /api/service-categories?salon_id=1
```

**Success Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Hair Services",
      "type": "service",
      "percentage": 10.5,
      "percentage2": 5.0,
      "percentage3": 2.5,
      "half_percentage": 5.25,
      "services_count": 15
    },
    {
      "id": 2,
      "name": "Nail Services",
      "type": "service",
      "percentage": 12.0,
      "percentage2": 6.0,
      "percentage3": 3.0,
      "half_percentage": 6.0,
      "services_count": 8
    }
  ]
}
```

**Error Response (422):**
```json
{
  "success": false,
  "message": "Validation Error",
  "errors": {
    "salon_id": ["The salon id field is required."]
  }
}
```

---

## Customer Endpoints

### 1. Get All Customers

Retrieve all customers for a specific salon.

**Endpoint:** `GET /api/customers`

**Authentication Required:** Yes

**Request Headers:**
```
Authorization: Bearer YOUR_TOKEN_HERE
```

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| salon_id | integer | Yes | ID of the salon |

**Example Request:**
```
GET /api/customers?salon_id=1
```

**Success Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Jane Smith",
      "mobile": "+1234567890",
      "mobile2": "+0987654321",
      "address": "123 Main Street",
      "region_id": 1,
      "area_id": 5,
      "taxnumber": "TAX123456",
      "birthdate": "1990-05-15",
      "eventdate": "2025-06-20",
      "balance": 150.50
    },
    {
      "id": 2,
      "name": "Mike Johnson",
      "mobile": "+1122334455",
      "mobile2": null,
      "address": "456 Oak Avenue",
      "region_id": 2,
      "area_id": 8,
      "taxnumber": null,
      "birthdate": "1985-03-22",
      "eventdate": null,
      "balance": -50.00
    }
  ]
}
```

**Error Response (422):**
```json
{
  "success": false,
  "message": "Validation Error",
  "errors": {
    "salon_id": ["The salon id field is required."]
  }
}
```

---

### 2. Create Customer

Add a new customer to the system.

**Endpoint:** `POST /api/customers`

**Authentication Required:** Yes

**Request Headers:**
```
Authorization: Bearer YOUR_TOKEN_HERE
Content-Type: application/json
```

**Request Body:**
```json
{
  "name": "Jane Smith",
  "mobile": "+1234567890",
  "mobile2": "+0987654321",
  "address": "123 Main Street",
  "region_id": 1,
  "area_id": 5,
  "taxnumber": "TAX123456",
  "birthdate": "1990-05-15",
  "eventdate": "2025-06-20"
}
```

**Request Parameters:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | string | Yes | Customer's full name (max 255 characters) |
| mobile | string | Yes | Primary mobile number (max 20 characters) |
| mobile2 | string | No | Secondary mobile number (max 20 characters) |
| address | string | No | Customer's address (max 500 characters) |
| region_id | integer | No | Region ID (must exist in regions table) |
| area_id | integer | No | Area ID (must exist in areas table) |
| taxnumber | string | No | Tax identification number (max 50 characters) |
| birthdate | date | No | Customer's birth date (format: YYYY-MM-DD) |
| eventdate | date | No | Special event date (format: YYYY-MM-DD) |

**Success Response (201):**
```json
{
  "success": true,
  "message": "Customer created successfully",
  "data": {
    "id": 3,
    "name": "Jane Smith",
    "mobile": "+1234567890",
    "mobile2": "+0987654321",
    "address": "123 Main Street",
    "region_id": 1,
    "area_id": 5,
    "taxnumber": "TAX123456",
    "birthdate": "1990-05-15",
    "eventdate": "2025-06-20"
  }
}
```

**Error Response (422):**
```json
{
  "success": false,
  "message": "Validation Error",
  "errors": {
    "name": ["The name field is required."],
    "mobile": ["The mobile field is required."]
  }
}
```

---

### 3. Get Single Customer

Retrieve details of a specific customer by ID.

**Endpoint:** `GET /api/customers/{id}`

**Authentication Required:** Yes

**Request Headers:**
```
Authorization: Bearer YOUR_TOKEN_HERE
```

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | integer | Yes | Customer ID |

**Example Request:**
```
GET /api/customers/1
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Jane Smith",
    "mobile": "+1234567890",
    "mobile2": "+0987654321",
    "address": "123 Main Street",
    "region_id": 1,
    "area_id": 5,
    "taxnumber": "TAX123456",
    "birthdate": "1990-05-15",
    "eventdate": "2025-06-20",
    "balance": 150.50
  }
}
```

**Error Response (404):**
```json
{
  "success": false,
  "message": "Customer not found"
}
```

---

## Payment Method Endpoints

### 1. Get Payment Methods

Retrieve all available payment methods.

**Endpoint:** `GET /api/payments/methods`

**Authentication Required:** Yes

**Request Headers:**
```
Authorization: Bearer YOUR_TOKEN_HERE
```

**Success Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Cash",
      "name_ar": "نقدي",
      "type": "cash",
      "enabled": true
    },
    {
      "id": 2,
      "name": "Credit Card",
      "name_ar": "بطاقة ائتمان",
      "type": "credit_card",
      "enabled": true
    },
    {
      "id": 3,
      "name": "Debit Card",
      "name_ar": "بطاقة خصم",
      "type": "debit_card",
      "enabled": true
    },
    {
      "id": 4,
      "name": "Bank Transfer",
      "name_ar": "تحويل بنكي",
      "type": "bank_transfer",
      "enabled": true
    },
    {
      "id": 5,
      "name": "Split Payment",
      "name_ar": "دفع مقسم",
      "type": "split",
      "enabled": true
    },
    {
      "id": 6,
      "name": "Credit",
      "name_ar": "آجل",
      "type": "credit",
      "enabled": true
    }
  ]
}
```

---

## Invoice Endpoints

### 1. Get All Invoices

Retrieve all invoices with optional filters.

**Endpoint:** `GET /api/invoices`

**Authentication Required:** Yes

**Request Headers:**
```
Authorization: Bearer YOUR_TOKEN_HERE
```

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| salon_id | integer | No | Filter by salon ID |
| client_id | integer | No | Filter by customer/client ID |
| from_date | date | No | Filter from date (format: YYYY-MM-DD) |
| to_date | date | No | Filter to date (format: YYYY-MM-DD) |

**Example Request:**
```
GET /api/invoices?salon_id=1&from_date=2025-11-01&to_date=2025-11-30
```

**Success Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "invoice_number": 1001,
      "date": "2025-11-20 14:30:00",
      "client_name": "Jane Smith",
      "salon_name": "My Salon",
      "total": 150.00,
      "paid": 150.00,
      "due": 0.00,
      "status": "completed",
      "payment_type": "cash"
    },
    {
      "id": 2,
      "invoice_number": 1002,
      "date": "2025-11-21 10:15:00",
      "client_name": "Mike Johnson",
      "salon_name": "My Salon",
      "total": 200.00,
      "paid": 100.00,
      "due": 100.00,
      "status": "completed",
      "payment_type": "credit"
    }
  ]
}
```

---

### 2. Create Invoice

Create a new invoice/order for services.

**Endpoint:** `POST /api/invoices`

**Authentication Required:** Yes

**Request Headers:**
```
Authorization: Bearer YOUR_TOKEN_HERE
Content-Type: application/json
```

**Request Body:**
```json
{
  "salon_id": 1,
  "client_id": 1,
  "payment_type": "cash",
  "items": [
    {
      "service_id": 1,
      "employee_id": 5,
      "quantity": 1,
      "price": 50.00,
      "discount": 5.00
    },
    {
      "service_id": 2,
      "employee_id": 6,
      "quantity": 1,
      "price": 100.00,
      "discount": 0
    }
  ],
  "tax": 7.50,
  "discount": 10.00,
  "discount_type": "fixed",
  "paid": 142.50
}
```

**Request Parameters:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| salon_id | integer | Yes | Salon ID (must exist in stores table) |
| client_id | integer | Yes | Customer ID (must exist in persons table) |
| payment_type | string | Yes | One of: cash, credit_card, debit_card, bank_transfer, split, credit |
| items | array | Yes | Array of invoice items (minimum 1 item) |
| items[].service_id | integer | Yes | Service/Product ID (must exist in products table) |
| items[].employee_id | integer | No | Employee ID who performed the service |
| items[].quantity | number | Yes | Quantity (minimum 0.01) |
| items[].price | number | Yes | Price per unit (minimum 0) |
| items[].discount | number | No | Item-level discount amount (minimum 0) |
| tax | number | No | Tax amount (minimum 0) |
| discount | number | No | Invoice-level discount (minimum 0) |
| discount_type | string | No | One of: fixed, percentage (default: fixed) |
| paid | number | Yes | Amount paid (minimum 0) |

**Success Response (201):**
```json
{
  "success": true,
  "message": "Invoice created successfully",
  "data": {
    "id": 3,
    "invoice_number": 1003,
    "total": 142.50,
    "paid": 142.50,
    "due": 0.00,
    "status": "completed",
    "created_at": "2025-11-25 16:45:00"
  }
}
```

**Error Response (422):**
```json
{
  "success": false,
  "message": "Validation Error",
  "errors": {
    "salon_id": ["The salon id field is required."],
    "items": ["The items field must have at least 1 items."]
  }
}
```

**Calculation Logic:**
1. Subtotal = Sum of (item quantity × item price - item discount) for all items
2. Invoice Discount = If discount_type is 'percentage': (Subtotal × discount / 100), else: discount
3. Total = Subtotal - Invoice Discount + Tax
4. Due = Total - Paid

---

### 3. Get Invoice Details

Retrieve detailed information about a specific invoice.

**Endpoint:** `GET /api/invoices/{id}`

**Authentication Required:** Yes

**Request Headers:**
```
Authorization: Bearer YOUR_TOKEN_HERE
```

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | integer | Yes | Invoice ID |

**Example Request:**
```
GET /api/invoices/1
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "invoice_number": 1001,
    "date": "2025-11-20 14:30:00",
    "status": "completed",
    "client": {
      "id": 1,
      "name": "Jane Smith",
      "mobile": "+1234567890"
    },
    "salon": {
      "id": 1,
      "name": "My Salon"
    },
    "items": [
      {
        "id": 1,
        "service_name": "Haircut",
        "employee_name": "John Stylist",
        "quantity": 1,
        "price": 50.00,
        "discount": 5.00,
        "total": 45.00
      },
      {
        "id": 2,
        "service_name": "Hair Coloring",
        "employee_name": "Sarah Colorist",
        "quantity": 1,
        "price": 100.00,
        "discount": 0,
        "total": 100.00
      }
    ],
    "subtotal": 145.00,
    "discount": 10.00,
    "discount_type": "fixed",
    "tax": 7.50,
    "total": 142.50,
    "paid": 142.50,
    "due": 0.00,
    "payment_type": "cash"
  }
}
```

**Error Response (404):**
```json
{
  "success": false,
  "message": "Invoice not found"
}
```

---

### 4. Print Invoice

Get invoice data formatted for printing.

**Endpoint:** `POST /api/invoices/{id}/print`

**Authentication Required:** Yes

**Request Headers:**
```
Authorization: Bearer YOUR_TOKEN_HERE
```

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | integer | Yes | Invoice ID |

**Example Request:**
```
POST /api/invoices/1/print
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Invoice ready for printing",
  "data": {
    "invoice_number": 1001,
    "date": "2025-11-20 14:30:00",
    "salon_name": "My Salon",
    "salon_mobile": "+1234567890",
    "client_name": "Jane Smith",
    "client_mobile": "+1234567890",
    "items": [
      {
        "service_name": "Haircut",
        "employee_name": "John Stylist",
        "quantity": 1,
        "price": 50.00,
        "total": 45.00
      },
      {
        "service_name": "Hair Coloring",
        "employee_name": "Sarah Colorist",
        "quantity": 1,
        "price": 100.00,
        "total": 100.00
      }
    ],
    "subtotal": 145.00,
    "discount": 10.00,
    "tax": 7.50,
    "total": 142.50,
    "paid": 142.50,
    "due": 0.00,
    "payment_type": "cash"
  }
}
```

**Notes:**
- This endpoint updates the invoice status to "printed" if it wasn't already
- The response is formatted specifically for printing/receipt generation

**Error Response (404):**
```json
{
  "success": false,
  "message": "Invoice not found"
}
```

---

## Error Codes

| HTTP Status Code | Description |
|------------------|-------------|
| 200 | Success - Request completed successfully |
| 201 | Created - Resource created successfully |
| 401 | Unauthorized - Authentication required or invalid credentials |
| 404 | Not Found - Requested resource does not exist |
| 422 | Unprocessable Entity - Validation error |
| 500 | Internal Server Error - Server-side error |

---

## Pagination

Currently, the API returns all results without pagination. For large datasets, consider implementing pagination by adding these query parameters:

| Parameter | Type | Description |
|-----------|------|-------------|
| page | integer | Page number (default: 1) |
| per_page | integer | Items per page (default: 15) |

*Note: Pagination is not yet implemented in the current version.*

---

## Rate Limiting

*Note: Rate limiting information should be added based on your server configuration.*

---

## Best Practices

1. **Always include the Authorization header** for protected endpoints
2. **Validate data on the client side** before sending requests to reduce validation errors
3. **Handle errors gracefully** by checking the `success` field in responses
4. **Store the authentication token securely** (e.g., in secure storage, not localStorage for web apps)
5. **Implement proper error handling** for network failures and server errors
6. **Use HTTPS** in production to secure data transmission

---

## Example Usage

### JavaScript (Fetch API)

#### Login Example
```javascript
const login = async (email, password) => {
  try {
    const response = await fetch('http://your-domain.com/api/auth/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ email, password }),
    });
    
    const data = await response.json();
    
    if (data.success) {
      // Store token securely
      localStorage.setItem('token', data.data.token);
      return data.data;
    } else {
      throw new Error(data.message);
    }
  } catch (error) {
    console.error('Login failed:', error);
    throw error;
  }
};
```

#### Get Services Example
```javascript
const getServices = async (salonId) => {
  try {
    const token = localStorage.getItem('token');
    const response = await fetch(`http://your-domain.com/api/services?salon_id=${salonId}`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
    });
    
    const data = await response.json();
    
    if (data.success) {
      return data.data;
    } else {
      throw new Error(data.message);
    }
  } catch (error) {
    console.error('Failed to fetch services:', error);
    throw error;
  }
};
```

#### Create Invoice Example
```javascript
const createInvoice = async (invoiceData) => {
  try {
    const token = localStorage.getItem('token');
    const response = await fetch('http://your-domain.com/api/invoices', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(invoiceData),
    });
    
    const data = await response.json();
    
    if (data.success) {
      return data.data;
    } else {
      throw new Error(data.message);
    }
  } catch (error) {
    console.error('Failed to create invoice:', error);
    throw error;
  }
};

// Usage
const invoiceData = {
  salon_id: 1,
  client_id: 1,
  payment_type: 'cash',
  items: [
    {
      service_id: 1,
      employee_id: 5,
      quantity: 1,
      price: 50.00,
      discount: 5.00
    }
  ],
  tax: 7.50,
  discount: 10.00,
  discount_type: 'fixed',
  paid: 142.50
};

createInvoice(invoiceData);
```

### PHP (cURL)

#### Login Example
```php
<?php
$url = 'http://your-domain.com/api/auth/login';
$data = [
    'email' => 'user@example.com',
    'password' => 'password123'
];

$ch = curl_init($url);
curl_setopt($ch, CURLOPT_POST, 1);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json'
]);

$response = curl_exec($ch);
curl_close($ch);

$result = json_decode($response, true);

if ($result['success']) {
    $token = $result['data']['token'];
    // Store token for future requests
}
?>
```

### Python (Requests)

#### Login Example
```python
import requests

url = 'http://your-domain.com/api/auth/login'
data = {
    'email': 'user@example.com',
    'password': 'password123'
}

response = requests.post(url, json=data)
result = response.json()

if result['success']:
    token = result['data']['token']
    # Store token for future requests
```

#### Get Services Example
```python
import requests

url = 'http://your-domain.com/api/services'
params = {'salon_id': 1}
headers = {
    'Authorization': f'Bearer {token}',
    'Content-Type': 'application/json'
}

response = requests.get(url, params=params, headers=headers)
result = response.json()

if result['success']:
    services = result['data']
```

---

## Database Models

### Key Models Used

#### Person (Customer)
- Represents customers/clients
- Type: 'client'
- Contains personal information, contact details, and balance

#### Product (Service)
- Represents services offered
- is_service = 1 for services
- Linked to categories and stores

#### Order (Invoice)
- Represents invoices/sales orders
- Contains totals, payment info, and status

#### OrderDetail (Invoice Item)
- Individual line items in an invoice
- Links services, employees, quantities, and prices

#### Store (Salon)
- Represents salons/stores
- Contains salon information and settings

---

## Support

For additional support or questions about the API, please contact:
- Email: support@yourdomain.com
- Documentation Updates: Check this file regularly for updates

---

## Changelog

### Version 1.0 (November 25, 2025)
- Initial API documentation
- Authentication endpoints
- Salon management endpoints
- Service and category endpoints
- Customer management endpoints
- Payment method endpoints
- Invoice management endpoints

---

*Last Updated: November 25, 2025*
