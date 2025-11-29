# Fix for "validation.exists" Error

## Problem
When creating an invoice, you're getting: `ValidationException: validation.exists, validation.exists, validation.exists`

This means the API is rejecting the `service_id` and `employee_id` values because they don't exist in your database.

## Root Cause
The app is sending `service_id: 1` and `employee_id: 1` for all invoice items, but these IDs don't exist in your database's `products` and `persons` tables.

## Solution Steps

### Step 1: Check Your Database
Run these SQL queries on your backend database to see what IDs actually exist:

```sql
-- Check which services exist
SELECT id, name FROM products WHERE store_id = 1 LIMIT 10;

-- Check which employees exist  
SELECT id, name, type FROM persons WHERE type = 'employee' LIMIT 10;
```

### Step 2: Update the App to Use Valid IDs

Once you know which IDs exist, you have three options:

#### **Option A: Use One Valid Service ID for All (Quick Fix)**
If you just want invoices to work, pick ANY valid service_id and employee_id from your database:

Edit `lib/repositories/cashier_repository.dart` line ~230:

```dart
return {
  'service_id': 5, // ← Replace with ANY valid ID from your products table
  'employee_id': 2, // ← Replace with ANY valid ID from your persons table
  'quantity': 1,
  'price': service.price,
  'discount': 0,
};
```

#### **Option B: Ask Backend to Make IDs Optional (Recommended)**
Contact your backend developer and ask them to make `service_id` and `employee_id` optional in the invoice API. This way, you can still track the service name and price without needing valid IDs.

#### **Option C: Fetch Services from API (Best Long-term)**
Ask your backend team to create these endpoints:

```
GET /api/services - Returns list of all services with IDs
GET /api/employees - Returns list of all employees with IDs
```

Then update the app to fetch and use real IDs.

### Step 3: Test the Fix

1. Run the app
2. Create an invoice with multiple services
3. Check the logs - you should see:
   ```
   🌐 API REQUEST: POST /invoices
   📦 Data: {...}
   POST Request JSON: {"json": "..."}
   Invoice Request Body: {...}
   ```
4. The invoice should save successfully

### Step 4: Verify the API Response

After a successful invoice creation, check that the response shows different service names:

```json
{
  "items": [
    {"service_name": "حلاقة شعر", "employee_name": "خالد"},
    {"service_name": "حلاقة لحية", "employee_name": "أحمد"}
  ]
}
```

## Current App Changes Made

✅ Added detailed logging to see exactly what's being sent to the API
✅ Added service `id` and `employeeId` fields to `ServiceModel`
✅ Updated error handling to show which fields are failing validation
✅ Currently using `service_id: 1` and `employee_id: 1` (needs database verification)

## Next Steps

**YOU NEED TO:**
1. Check your database for valid service and employee IDs
2. Update line ~230 in `cashier_repository.dart` with valid IDs
3. Test invoice creation

**OR ASK YOUR BACKEND TEAM TO:**
1. Create GET /services and GET /employees endpoints
2. Make service_id and employee_id optional in POST /invoices
3. Add a `service_name` field that can be sent instead of service_id

