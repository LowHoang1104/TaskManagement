/// Input validation helpers.
/// Returns null if valid, or an error string if invalid.
class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email không được để trống.';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email không hợp lệ.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mật khẩu không được để trống.';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự.';
    }
    return null;
  }

  static String? required(String? value, [String fieldName = 'Trường này']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName không được để trống.';
    }
    return null;
  }

  static String? minLength(String? value, int min, [String fieldName = 'Trường này']) {
    if (value == null || value.length < min) {
      return '$fieldName phải có ít nhất $min ký tự.';
    }
    return null;
  }

  static String? maxLength(String? value, int max, [String fieldName = 'Trường này']) {
    if (value != null && value.length > max) {
      return '$fieldName không được vượt quá $max ký tự.';
    }
    return null;
  }

  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional field
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasAbsolutePath) {
      return 'URL không hợp lệ.';
    }
    return null;
  }
}
