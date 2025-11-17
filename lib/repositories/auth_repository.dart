/// Repository for authentication operations
class AuthRepository {
  /// Mock login - validates credentials
  /// In a real app, this would call your backend API
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    required String subdomain,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock validation
    if (username.isEmpty || password.isEmpty) {
      throw Exception('اسم المستخدم وكلمة المرور مطلوبة');
    }

    // Mock authentication - accept any non-empty credentials
    // In real app, validate against your backend
    if (username.isNotEmpty && password.isNotEmpty) {
      return {
        'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
        'userId': 1,
        'username': username,
        'subdomain': subdomain,
      };
    } else {
      throw Exception('اسم المستخدم أو كلمة المرور غير صحيحة');
    }
  }

  /// Mock logout
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Clear stored credentials if needed
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    await Future.delayed(const Duration(milliseconds: 100));
    // In real app, check if token exists and is valid
    return false;
  }

  /// Get stored user data
  Future<Map<String, dynamic>?> getUserData() async {
    await Future.delayed(const Duration(milliseconds: 100));
    // In real app, retrieve from SharedPreferences or secure storage
    return null;
  }
}
