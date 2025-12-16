/// To chain validators, call them one after the other with the ?? operator.
/// Reasoning: If the first validator returns null then it has no errors, so
/// we check the second one, etc.
/// Once a validator returns a non-null value, this means it caught an error
/// and no need to check any further
class Validators {
  static String? required(String? val, String name) {
    if (val == null || val.isEmpty) {
      return '* $name is required';
    }
    return null;
  }

  static String? email(String? val) {
    if (val == null || !val.contains('@')) {
      return '* Please enter a valid email';
    }
    return null;
  }

  static String? phone(String? val) {
    if (val == null) return null;
    // Kenya phone numbers with +254 prefix:
    // - Mobile: 9 digits starting with 7 (712345678) or 10 digits with leading 0 (0712345678)
    // - Landline: 9 digits starting with area codes 2-9 (201234567) or 10 digits with leading 0 (0201234567)
    final cleaned = val.trim().replaceAll(RegExp(r'[\s-]'), '');
    // Accepts: 9 digits (7XXXXXXXX or 2-9XXXXXXXX) or 10 digits (07XXXXXXXX or 02-9XXXXXXXX)
    final regExp = RegExp(r'^(0?[2-9]\d{8}|0?7\d{8})$');
    if (!regExp.hasMatch(cleaned)) {
      return '* Please enter a valid phone number (9-10 digits)';
    }
    return null;
  }

  /// Allows years only between 1900 and 2099
  /// Allows only birth years of people between 18 and 100 years old
  static String? birthYear(String? val) {
    if (val == null) return null;
    final regExp = RegExp(r'^(19|20)\d{2}$');
    if (!regExp.hasMatch(val)) {
      return '* Please enter a valid year';
    }
    final year = int.tryParse(val) ?? 0;
    final age = DateTime.now().year - year;
    if (age < 18) {
      return '* You must be at least 18 years old';
    } else if (age > 100) {
      return '* You must be less than 100 years old';
    }
    return null;
  }

  /// Allows only alphabetical non numeric characters,
  /// and only the dash and apostrophe in special chars
  static String? name(String? val) {
    if (val == null) return null;
    final regExp =
        RegExp(r"^[a-zA-Z]+(([' -][a-zA-Z ])?[a-zA-Z]*)*$");
    if (!regExp.hasMatch(val)) {
      return '* Please enter a valid name';
    }
    return null;
  }
}
