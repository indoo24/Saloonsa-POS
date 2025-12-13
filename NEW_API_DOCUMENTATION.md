# Salon Management System - REST API Documentation

## Base URL
```
http://your-domain.com/api
```

## Authentication
This API uses Laravel Sanctum for authentication. After logging in, include the Bearer token in all protected requests:

```
Authorization: Bearer {your-token-here}
```

---

## Table of Contents
1. [Authentication](#authentication-endpoints)
2. [Products (Services)](#products-endpoints)
3. [Categories](#categories-endpoints)
4. [Persons (Customers/Suppliers)](#persons-endpoints)
5. [Employees](#employees-endpoints)
6. [Orders (Invoices)](#orders-endpoints)
7. [Payment Methods](#payment-methods-endpoints)

---

## Authentication Endpoints

### 1. Login
**POST** `/api/auth/login`

**Request Body:**
```json
{
  "email": "أشرف",
  "password": "Mai@1010"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": 1,
      "name": "أشرف",
      "email": "أشرف",
      "mobile": null
    },
    "token": "1|abc123..."
  }
}
```

### 2. Logout
**POST** `/api/auth/logout`
- Requires authentication

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

### 3. Get Current User
**GET** `/api/auth/user`
- Requires authentication

---

## Products Endpoints

Products can be services or physical products. Use `is_service=1` to filter for services only.

### 1. Get All Products
**GET** `/api/products`
- Requires authentication

**Query Parameters:**
- `is_service` (boolean): Filter by service type (0 or 1)
- `category_id` (integer): Filter by category
- `search` (string): Search by product name
- `per_page` (integer): Items per page (default: 15)

**Example:** `/api/products?is_service=1&per_page=20`

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "current_page": 1,
    "data": [
      {
        "id": 1,
        "name": "Haircut Service",
        "code": "SRV001",
        "description": "Professional haircut",
        "is_service": 1,
        "main_category_id": 1,
        "category": {
          "id": 1,
          "name": "Hair Services"
        }
      }
    ],
    "per_page": 15,
    "total": 50
  }
}
```

### 2. Create Product
**POST** `/api/products`
- Requires authentication

**Request Body:**
```json
{
  "name": "Haircut Service",
  "code": "SRV001",
  "description": "Professional haircut",
  "is_service": 1,
  "main_category_id": 1
}
```

### 3. Get Single Product
**GET** `/api/products/{id}`
- Requires authentication

### 4. Update Product
**PUT** `/api/products/{id}`
- Requires authentication

### 5. Delete Product
**DELETE** `/api/products/{id}`
- Requires authentication

---

## Categories Endpoints

### 1. Get All Categories
**GET** `/api/categories`
- Requires authentication

**Query Parameters:**
- `search` (string): Search by category name
- `per_page` (integer): Items per page

### 2. Create Category
**POST** `/api/categories`
- Requires authentication

**Request Body:**
```json
{
  "name": "Hair Services",
  "description": "All hair-related services"
}
```

### 3. Get Single Category
**GET** `/api/categories/{id}`
- Requires authentication

---

## Persons Endpoints

Persons represent customers, suppliers, or sales representatives.

### 1. Get All Persons
**GET** `/api/persons`
- Requires authentication

**Query Parameters:**
- `type` (string): Filter by type (`client`, `supplier`, `sales`)
- `search` (string): Search by name or mobile
- `per_page` (integer): Items per page

**Example:** `/api/persons?type=client&search=ahmed`

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "current_page": 1,
    "data": [
      {
        "id": 1,
        "name": "Ahmed Ali",
        "type": "client",
        "mobile": "0123456789",
        "mobile2": null,
        "address": "123 Main St",
        "taxnumber": null,
        "birthdate": "1990-01-15",
        "eventdate": null,
        "region": {
          "id": 1,
          "name": "Cairo"
        },
        "area": {
          "id": 1,
          "name": "Nasr City"
        }
      }
    ]
  }
}
```

### 2. Create Person
**POST** `/api/persons`
- Requires authentication

**Request Body:**
```json
{
  "name": "Ahmed Ali",
  "type": "client",
  "mobile": "0123456789",
  "mobile2": "0198765432",
  "address": "123 Main St",
  "region_id": 1,
  "area_id": 1,
  "taxnumber": "TAX123",
  "birthdate": "1990-01-15",
  "eventdate": "2024-12-25"
}
```

### 3. Get Single Person
**GET** `/api/persons/{id}`
- Requires authentication

### 4. Update Person
**PUT** `/api/persons/{id}`
- Requires authentication

### 5. Delete Person
**DELETE** `/api/persons/{id}`
- Requires authentication

---

## Employees Endpoints

### 1. Get All Employees
**GET** `/api/employees`
- Requires authentication

**Query Parameters:**
- `type` (string): Filter by employee type
- `manager_id` (integer): Filter by manager
- `search` (string): Search by name or mobile
- `per_page` (integer): Items per page

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "current_page": 1,
    "data": [
      {
        "id": 1,
        "name": "Mohamed Hassan",
        "mobile": "0123456789",
        "salary": 5000,
        "day_salary": 200,
        "working_days": 26,
        "type": "normal",
        "percent": 10,
        "manager_id": null,
        "target": 50000,
        "note": "Senior stylist",
        "manger": null
      }
    ]
  }
}
```

### 2. Create Employee
**POST** `/api/employees`
- Requires authentication

**Request Body:**
```json
{
  "name": "Mohamed Hassan",
  "mobile": "0123456789",
  "salary": 5000,
  "day_salary": 200,
  "working_days": 26,
  "type": "normal",
  "percent": 10,
  "manager_id": null,
  "target": 50000,
  "note": "Senior stylist"
}
```

### 3. Get Single Employee
**GET** `/api/employees/{id}`
- Requires authentication
- Includes: manager, subordinates, punishments, rewards, expenses

### 4. Update Employee
**PUT** `/api/employees/{id}`
- Requires authentication

### 5. Delete Employee
**DELETE** `/api/employees/{id}`
- Requires authentication

---

## Orders Endpoints

Orders represent invoices/bookings.

### 1. Get All Orders
**GET** `/api/orders`
- Requires authentication

**Query Parameters:**
- `person_id` (integer): Filter by customer
- `sale_id` (integer): Filter by employee
- `from_date` (date): Filter from date (YYYY-MM-DD)
- `to_date` (date): Filter to date (YYYY-MM-DD)
- `per_page` (integer): Items per page

**Example:** `/api/orders?person_id=1&from_date=2024-01-01&to_date=2024-12-31`

### 2. Create Order
**POST** `/api/orders`
- Requires authentication

**Request Body:**
```json
{
  "person_id": 1,
  "sale_id": 2,
  "discount": 10,
  "tax_value": 15,
  "paid": 100,
  "note": "Customer requested specific stylist",
  "items": [
    {
      "product_id": 1,
      "qty": 1,
      "price": 50,
      "employee_id": 3
    },
    {
      "product_id": 2,
      "qty": 1,
      "price": 75,
      "employee_id": 3
    }
  ]
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Order created successfully",
  "data": {
    "id": 1,
    "person_id": 1,
    "sale_id": 2,
    "discount": 10,
    "tax_value": 15,
    "total": 130,
    "paid": 100,
    "note": "Customer requested specific stylist",
    "person": {
      "id": 1,
      "name": "Ahmed Ali"
    },
    "sale": {
      "id": 2,
      "name": "Mohamed Hassan"
    },
    "details": [
      {
        "id": 1,
        "product_id": 1,
        "qty": 1,
        "price": 50,
        "total": 50,
        "product": {
          "id": 1,
          "name": "Haircut Service"
        },
        "employee": {
          "id": 3,
          "name": "Stylist Name"
        }
      }
    ]
  }
}
```

### 3. Get Single Order
**GET** `/api/orders/{id}`
- Requires authentication

### 4. Print Order
**POST** `/api/orders/{id}/print`
- Requires authentication
- Returns formatted data for printing

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "order_id": 1,
    "date": "2024-12-11 10:30:00",
    "customer": {
      "name": "Ahmed Ali",
      "mobile": "0123456789",
      "address": "123 Main St"
    },
    "employee": {
      "name": "Mohamed Hassan",
      "mobile": "0123456789"
    },
    "items": [
      {
        "product_name": "Haircut Service",
        "employee_name": "Stylist Name",
        "qty": 1,
        "price": 50,
        "total": 50
      }
    ],
    "subtotal": 125,
    "discount": 10,
    "tax": 15,
    "total": 130,
    "paid": 100,
    "remaining": 30,
    "note": "Customer requested specific stylist"
  }
}
```

---

## Payment Methods Endpoints

### Get All Payment Methods
**GET** `/api/payments/methods`
- Requires authentication

---

## Error Responses

All endpoints return standardized error responses:

### Validation Error (422):
```json
{
  "success": false,
  "message": "Validation error",
  "errors": {
    "name": ["The name field is required."]
  }
}
```

### Unauthorized (401):
```json
{
  "success": false,
  "message": "Unauthenticated"
}
```

### Not Found (404):
```json
{
  "success": false,
  "message": "Resource not found"
}
```

### Server Error (500):
```json
{
  "success": false,
  "message": "An error occurred",
  "error": "Error details..."
}
```

---

## Common Response Format

All successful responses follow this format:
```json
{
  "success": true,
  "message": "Optional success message",
  "data": {
    // Response data here
  }
}
```

---

## Testing the API

### Using cURL:

**Login:**
```bash
curl -X POST http://your-domain.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"أشرف","password":"Mai@1010"}'
```

**Get Products:**
```bash
curl -X GET http://your-domain.com/api/products?is_service=1 \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

### Using Postman:
1. Import the endpoints from this documentation
2. Set up environment variables for base URL and token
3. Use Bearer token authentication for protected routes

---

## Migration Notes

### Old API → New API Mappings:
- `/api/services` → `/api/products?is_service=1`
- `/api/service-categories` → `/api/categories`
- `/api/customers` → `/api/persons?type=client`
- `/api/invoices` → `/api/orders`
- **NEW:** `/api/employees` (complete CRUD operations)

---

## Support

For questions or issues, please contact the development team.
