# API Response and Error Logging - Quick Reference

## 📊 Log Output Examples

This guide shows you what to expect in the console logs for different API operations.

---

## 🔐 Authentication Logs

### Successful Login

```
🔐 AUTH: Attempting login
Data: {username: admin@salon.com, subdomain: mysalon}

🌐 API REQUEST: GET /salons/by-domain/mysalon

✅ API RESPONSE: /salons/by-domain/mysalon
Status: 200
Data: {
  success: true,
  data: {
    id: 1,
    name: My Salon,
    subdomain: mysalon,
    mobile: +1234567890
  }
}

🌐 API REQUEST: POST /auth/login
Data: {email: admin@salon.com, password: ********}

✅ API RESPONSE: /auth/login
Status: 200
Data: {
  success: true,
  message: Login successful,
  data: {
    user: {
      id: 1,
      name: Admin User,
      email: admin@salon.com
    },
    token: 1|abcdef...
  }
}

🔐 AUTH: Token stored

🔐 AUTH: Login successful
Data: {userId: 1, userName: Admin User, salonId: 1}
```

### Failed Login (Invalid Credentials)

```
🔐 AUTH: Attempting login
Data: {username: wrong@email.com, subdomain: mysalon}

🌐 API REQUEST: POST /auth/login
Data: {email: wrong@email.com, password: ********}

❌ API ERROR: /auth/login
Error: ApiException: غير مصرح: Invalid email or password

🔐 AUTH: Login failed
Error: Exception: Invalid email or password
```

### Failed Login (Salon Not Found)

```
🔐 AUTH: Attempting login
Data: {username: admin@salon.com, subdomain: wrongsalon}

🌐 API REQUEST: GET /salons/by-domain/wrongsalon

❌ API ERROR: /salons/by-domain/wrongsalon
Error: ApiException: غير موجود: Salon not found

🔐 AUTH: Login failed
Error: Exception: فشل في العثور على الصالون
```

### Logout

```
🔐 AUTH: Attempting logout

🌐 API REQUEST: POST /auth/logout

✅ API RESPONSE: /auth/logout
Status: 200
Data: {success: true, message: Logged out successfully}

🔐 AUTH: Auth data cleared

🔐 AUTH: Logout successful
```

---

## 👥 Customer Operations

### Fetch All Customers

```
Fetching customers from API

🌐 API REQUEST: GET /customers?salon_id=1

✅ API RESPONSE: /customers
Status: 200
Data: {
  success: true,
  data: [
    {
      id: 1,
      name: John Doe,
      mobile: +1234567890,
      balance: 150.50
    },
    {
      id: 2,
      name: Jane Smith,
      mobile: +0987654321,
      balance: -50.00
    }
  ]
}

Customers fetched successfully
Data: {count: 2}
```

### Add New Customer

```
Adding new customer
Data: {name: New Customer, phone: +1234567890}

🌐 API REQUEST: POST /customers
Data: {name: New Customer, mobile: +1234567890}

✅ API RESPONSE: /customers
Status: 201
Data: {
  success: true,
  message: Customer created successfully,
  data: {
    id: 3,
    name: New Customer,
    mobile: +1234567890
  }
}

Customer added successfully
Data: Customer(id: 3, name: New Customer)
```

### Add Customer - Validation Error

```
Adding new customer
Data: {name: , phone: }

🌐 API REQUEST: POST /customers
Data: {name: , mobile: }

❌ API ERROR: /customers
Error: ValidationException: Validation Error
Status: 422
Response: {
  success: false,
  message: Validation Error,
  errors: {
    name: [The name field is required.]
  }
}

Failed to add customer via API
Error: ValidationException: The name field is required.
```

---

## 🧾 Invoice Operations

### Submit Invoice

```
🧾 INVOICE: Submitting invoice from cubit
Data: {
  cartItems: 2,
  total: 150.0,
  customer: John Doe,
  paymentType: cash
}

🧾 INVOICE: Submitting invoice
Data: {
  customer: John Doe,
  serviceCount: 2,
  total: 150.0,
  paymentType: cash
}

🌐 API REQUEST: POST /invoices
Data: {
  salon_id: 1,
  client_id: 1,
  payment_type: cash,
  items: [
    {
      service_id: 1,
      employee_id: 1,
      quantity: 1,
      price: 50.0,
      discount: 0
    },
    {
      service_id: 2,
      employee_id: 2,
      quantity: 1,
      price: 100.0,
      discount: 0
    }
  ],
  tax: 0,
  discount: 0,
  discount_type: fixed,
  paid: 150.0
}

✅ API RESPONSE: /invoices
Status: 201
Data: {
  success: true,
  message: Invoice created successfully,
  data: {
    id: 10,
    invoice_number: 1010,
    total: 150.0,
    paid: 150.0,
    due: 0.0,
    status: completed,
    created_at: 2025-11-26 10:30:00
  }
}

🧾 INVOICE: Invoice submitted successfully
Data: {invoiceId: 10, invoiceNumber: 1010}
```

### Fetch Invoices

```
🧾 INVOICE: Fetching invoices
Data: {clientId: null, fromDate: 2025-11-01, toDate: 2025-11-30}

🌐 API REQUEST: GET /invoices?salon_id=1&from_date=2025-11-01&to_date=2025-11-30

✅ API RESPONSE: /invoices
Status: 200
Data: {
  success: true,
  data: [
    {
      id: 10,
      invoice_number: 1010,
      date: 2025-11-26 10:30:00,
      client_name: John Doe,
      total: 150.0,
      paid: 150.0,
      due: 0.0,
      status: completed,
      payment_type: cash
    }
  ]
}

🧾 INVOICE: Invoices fetched
Data: {count: 1}
```

### Get Invoice Details

```
🧾 INVOICE: Fetching invoice details
Data: {invoiceId: 10}

🌐 API REQUEST: GET /invoices/10

✅ API RESPONSE: /invoices/10
Status: 200
Data: {
  success: true,
  data: {
    id: 10,
    invoice_number: 1010,
    date: 2025-11-26 10:30:00,
    status: completed,
    client: {
      id: 1,
      name: John Doe,
      mobile: +1234567890
    },
    items: [
      {
        id: 1,
        service_name: Haircut,
        employee_name: Barber 1,
        quantity: 1,
        price: 50.0,
        discount: 0,
        total: 50.0
      }
    ],
    subtotal: 150.0,
    discount: 0,
    tax: 0,
    total: 150.0,
    paid: 150.0,
    due: 0.0,
    payment_type: cash
  }
}

🧾 INVOICE: Invoice fetched
Data: {invoiceNumber: 1010}
```

---

## 💳 Payment Methods

### Fetch Payment Methods

```
Fetching payment methods from API

🌐 API REQUEST: GET /payments/methods

✅ API RESPONSE: /payments/methods
Status: 200
Data: {
  success: true,
  data: [
    {
      id: 1,
      name: Cash,
      name_ar: نقدي,
      type: cash,
      enabled: true
    },
    {
      id: 2,
      name: Credit Card,
      name_ar: بطاقة ائتمان,
      type: credit_card,
      enabled: true
    }
  ]
}

Payment methods fetched
Data: {count: 2}
```

---

## 🛒 Cart Operations

### Add to Cart

```
🛒 CART: Adding service to cart
Data: {service: Haircut, price: 50.0, barber: Barber 1}
```

### Remove from Cart

```
🛒 CART: Removing service from cart
Data: {index: 0, service: Haircut}
```

### Save Cart

```
🛒 CART: Cart saved
Data: {itemCount: 2}
```

---

## ❌ Common Error Responses

### 401 Unauthorized

```
❌ API ERROR: /customers
Error: ApiException: غير مصرح: Unauthorized
Status: 401

🔐 AUTH: Auth data cleared
```
**Action:** User is automatically logged out, token cleared

### 404 Not Found

```
❌ API ERROR: /invoices/999
Error: ApiException: غير موجود: Invoice not found
Status: 404
```

### 422 Validation Error

```
❌ API ERROR: /customers
Error: ValidationException: Validation Error
Status: 422
Response: {
  success: false,
  message: Validation Error,
  errors: {
    name: [The name field is required.],
    mobile: [The mobile field is required.]
  }
}
```

### 500 Server Error

```
❌ API ERROR: /invoices
Error: ApiException: خطأ في الخادم: Internal Server Error
Status: 500
```

### Network Error

```
❌ API ERROR: /customers
Error: Network error: SocketException: Failed to connect
```

---

## 🔍 How to Filter Logs

### In VS Code / Android Studio

Use the Debug Console search/filter feature:

- **API Requests only:** Search for `🌐 API REQUEST`
- **API Responses only:** Search for `✅ API RESPONSE`
- **Errors only:** Search for `❌`
- **Auth operations:** Search for `🔐 AUTH`
- **Cart operations:** Search for `🛒 CART`
- **Invoice operations:** Search for `🧾 INVOICE`

### In Terminal

When running from terminal, you can pipe to grep:

```bash
flutter run | grep "API REQUEST"
flutter run | grep "ERROR"
flutter run | grep "INVOICE"
```

---

## 📝 Log Levels

The logger uses these levels (in order of importance):

1. **Error** (`.e`) - API errors, exceptions, crashes
2. **Warning** (`.w`) - Potential issues, missing data
3. **Info** (`.i`) - Important events (login, invoice creation)
4. **Debug** (`.d`) - API responses, detailed data

---

## 🎯 What to Look For

### When Debugging Login Issues

Look for:
- `🔐 AUTH: Attempting login`
- Check if salon is found: `API RESPONSE: /salons/by-domain/`
- Check if login succeeds: `API RESPONSE: /auth/login`
- Verify token is stored: `🔐 AUTH: Token stored`

### When Debugging Customer Issues

Look for:
- `Fetching customers from API`
- Check response: `API RESPONSE: /customers`
- Verify count: `Customers fetched successfully`

### When Debugging Invoice Issues

Look for:
- `🧾 INVOICE: Submitting invoice`
- Check request data structure
- Check response: `API RESPONSE: /invoices`
- Verify success: `Invoice submitted successfully`

---

## 💡 Tips

1. **Enable verbose logging** - All logs include request/response data
2. **Check timestamps** - Logger includes time since app start
3. **Stack traces** - Errors include full stack traces for debugging
4. **Copy logs** - You can copy entire log blocks for issue reports

---

*Last Updated: November 26, 2025*
