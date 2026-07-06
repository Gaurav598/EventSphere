class Validators {
  static String? requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!value.contains('@')) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? positiveInteger(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    final intValue = int.tryParse(value.trim());
    if (intValue == null || intValue <= 0) {
      return 'Must be a positive integer';
    }
    return null;
  }
}
