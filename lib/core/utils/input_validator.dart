/// Input validation utilities for production-grade data validation
class InputValidator {
  /// Validate email address
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'البريد الإلكتروني غير صحيح';
    }

    return null;
  }

  /// Validate phone number (supports various formats)
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'رقم الهاتف مطلوب';
    }

    // Remove common separators
    final cleanedPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check if it contains only digits and optional + at start
    if (!RegExp(r'^\+?\d{10,15}$').hasMatch(cleanedPhone)) {
      return 'رقم الهاتف غير صحيح';
    }

    return null;
  }

  /// Validate required field
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? '$fieldName مطلوب' : 'هذا الحقل مطلوب';
    }
    return null;
  }

  /// Validate password strength
  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }

    if (value.length < minLength) {
      return 'كلمة المرور يجب أن تكون $minLength أحرف على الأقل';
    }

    // Check for at least one letter and one number (optional but recommended)
    // Uncomment for stronger password requirements
    // if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(value)) {
    //   return 'كلمة المرور يجب أن تحتوي على حروف وأرقام';
    // }

    return null;
  }

  /// Validate numeric value
  static String? numeric(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? '$fieldName مطلوب' : 'هذا الحقل مطلوب';
    }

    if (double.tryParse(value) == null) {
      return 'يجب إدخال رقم صحيح';
    }

    return null;
  }

  /// Validate positive number
  static String? positiveNumber(String? value, {String? fieldName}) {
    final numericError = numeric(value, fieldName: fieldName);
    if (numericError != null) return numericError;

    final number = double.parse(value!);
    if (number <= 0) {
      return 'يجب أن يكون الرقم أكبر من صفر';
    }

    return null;
  }

  /// Validate number range
  static String? numberRange(
    String? value, {
    double? min,
    double? max,
    String? fieldName,
  }) {
    final numericError = numeric(value, fieldName: fieldName);
    if (numericError != null) return numericError;

    final number = double.parse(value!);

    if (min != null && number < min) {
      return 'القيمة يجب أن تكون $min على الأقل';
    }

    if (max != null && number > max) {
      return 'القيمة يجب أن تكون $max كحد أقصى';
    }

    return null;
  }

  /// Validate discount percentage (0-100)
  static String? discountPercentage(String? value) {
    return numberRange(value, min: 0, max: 100, fieldName: 'نسبة الخصم');
  }

  /// Validate price/amount
  static String? price(String? value) {
    return positiveNumber(value, fieldName: 'السعر');
  }

  /// Validate minimum length
  static String? minLength(String? value, int min, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return fieldName != null ? '$fieldName مطلوب' : 'هذا الحقل مطلوب';
    }

    if (value.length < min) {
      return 'يجب أن يكون $min أحرف على الأقل';
    }

    return null;
  }

  /// Validate maximum length
  static String? maxLength(String? value, int max) {
    if (value != null && value.length > max) {
      return 'يجب أن يكون $max حرف كحد أقصى';
    }
    return null;
  }

  /// Combine multiple validators
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }

  /// Sanitize input (remove leading/trailing spaces)
  static String? sanitize(String? value) {
    return value?.trim();
  }

  /// Validate Arabic text only
  static String? arabicOnly(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? '$fieldName مطلوب' : 'هذا الحقل مطلوب';
    }

    if (!RegExp(r'^[\u0600-\u06FF\s]+$').hasMatch(value)) {
      return 'يجب إدخال نص عربي فقط';
    }

    return null;
  }

  /// Validate alphanumeric
  static String? alphanumeric(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? '$fieldName مطلوب' : 'هذا الحقل مطلوب';
    }

    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
      return 'يجب إدخال حروف وأرقام فقط';
    }

    return null;
  }

  /// Validate URL
  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرابط مطلوب';
    }

    try {
      final uri = Uri.parse(value);
      if (!uri.hasScheme || (!uri.hasAuthority && uri.scheme != 'file')) {
        return 'الرابط غير صحيح';
      }
      return null;
    } catch (e) {
      return 'الرابط غير صحيح';
    }
  }

  /// Validate date is not in the past
  static String? notPastDate(DateTime? value) {
    if (value == null) {
      return 'التاريخ مطلوب';
    }

    if (value.isBefore(DateTime.now())) {
      return 'لا يمكن اختيار تاريخ في الماضي';
    }

    return null;
  }

  /// Validate date is not in the future
  static String? notFutureDate(DateTime? value) {
    if (value == null) {
      return 'التاريخ مطلوب';
    }

    if (value.isAfter(DateTime.now())) {
      return 'لا يمكن اختيار تاريخ في المستقبل';
    }

    return null;
  }
}

/// Extension for easy validation on TextEditingController
extension ValidatedTextController on String {
  /// Quick email validation
  bool get isValidEmail => InputValidator.email(this) == null;

  /// Quick phone validation
  bool get isValidPhone => InputValidator.phone(this) == null;

  /// Quick numeric validation
  bool get isNumeric => double.tryParse(this) != null;

  /// Quick positive number validation
  bool get isPositiveNumber {
    final num = double.tryParse(this);
    return num != null && num > 0;
  }
}
