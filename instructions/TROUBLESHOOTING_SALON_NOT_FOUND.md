# Troubleshooting: Salon Not Found Error

## ❌ Error Message
```
ApiException: غير موجود: Salon not found (Status: 404)
```

## 🔍 What This Means

The error **"Salon not found"** means the subdomain you entered doesn't exist in the database. In your case, you tried to login with:

**Subdomain:** `man1saloonsa`

This subdomain is not registered in your backend database.

---

## ✅ How to Fix

### Option 1: Check the Correct Subdomain
1. Verify the correct subdomain name from your database
2. Make sure there are no typos
3. Check if the subdomain is spelled correctly

### Option 2: Add the Salon to Database

You need to add this salon to your Laravel backend database. Here's how:

#### Using Laravel Tinker:
```bash
php artisan tinker
```

Then run:
```php
\App\Models\Store::create([
    'name' => 'Man1 Saloon',
    'subdomain' => 'man1saloonsa',
    'mobile' => '+966501234567',
    'note' => 'Main branch',
]);
```

#### Using Database Seeder:
Create a seeder file:
```bash
php artisan make:seeder SalonSeeder
```

Edit `database/seeders/SalonSeeder.php`:
```php
<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Store;

class SalonSeeder extends Seeder
{
    public function run()
    {
        Store::create([
            'name' => 'Man1 Saloon',
            'subdomain' => 'man1saloonsa',
            'mobile' => '+966501234567',
            'note' => 'Main branch',
        ]);
    }
}
```

Run the seeder:
```bash
php artisan db:seed --class=SalonSeeder
```

#### Using SQL Directly:
```sql
INSERT INTO stores (name, subdomain, mobile, note, created_at, updated_at)
VALUES ('Man1 Saloon', 'man1saloonsa', '+966501234567', 'Main branch', NOW(), NOW());
```

---

## 🔄 Testing the Fix

After adding the salon to the database:

1. **Restart your Laravel server** (if needed):
   ```bash
   php artisan serve
   ```

2. **Clear any caches**:
   ```bash
   php artisan cache:clear
   php artisan config:clear
   ```

3. **Try logging in again** with:
   - Subdomain: `man1saloonsa`
   - Email: your email
   - Password: your password

---

## 📊 Verify Salon Exists

To check if a salon exists in your database:

### Using Laravel Tinker:
```bash
php artisan tinker
```

```php
\App\Models\Store::where('subdomain', 'man1saloonsa')->first();
```

### Using MySQL:
```sql
SELECT * FROM stores WHERE subdomain = 'man1saloonsa';
```

---

## ℹ️ API Endpoint Information

The app calls this endpoint to check if the salon exists:
```
GET http://10.0.2.2:8000/api/salons/by-domain/{subdomain}
```

**Example:**
```
GET http://10.0.2.2:8000/api/salons/by-domain/man1saloonsa
```

**Expected Response (Success):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Man1 Saloon",
    "subdomain": "man1saloonsa",
    "mobile": "+966501234567",
    "note": "Main branch"
  }
}
```

**Current Response (Error):**
```json
{
  "success": false,
  "message": "Salon not found"
}
```

---

## 🐛 Debug Steps

1. **Check Backend Server:**
   - Make sure Laravel server is running: `php artisan serve`
   - Check the server is accessible from emulator: `http://10.0.2.2:8000`

2. **Check Database:**
   - Verify database connection works
   - Check if `stores` table exists
   - Check if any salons exist: `SELECT * FROM stores;`

3. **Check API Route:**
   - Test the endpoint in Postman or browser:
     ```
     http://localhost:8000/api/salons/by-domain/man1saloonsa
     ```

4. **Check Logs:**
   - Laravel logs: `storage/logs/laravel.log`
   - App logs: Already visible in your Flutter console ✅

---

## ✨ Improved Error Message

I've updated the error handling to show a clearer message. After the update, instead of:
```
Network error: ApiException: غير موجود: Salon not found (Status: 404)
```

You'll see:
```
الصالون غير موجود. تأكد من اسم النطاق الفرعي
(The salon doesn't exist. Check the subdomain name)
```

---

## 📝 Summary

**Problem:** Subdomain `man1saloonsa` is not in the database  
**Solution:** Add the salon to your database using one of the methods above  
**Status:** Error handling improved ✅  

---

## 🔗 Related Files

- `lib/repositories/auth_repository.dart` - Login logic (updated with better error)
- `lib/services/api_client.dart` - API communication
- `lib/services/logger_service.dart` - Logging (working perfectly!)

---

*Need more help? Check your Laravel backend logs and database!*
