/// A collection of ready-made validators for common form field rules.
///
/// Every method returns a [FieldValidator] — a function you pass
/// directly into [FieldMeta.validators].
///
/// Example:
/// ```dart
/// FieldMeta(
///   key: 'email',
///   label: 'Email',
///   type: FieldType.text,
///   required: true,
///   validators: [
///     RjValidators.email(),
///   ],
/// )
/// ```
///
/// Combine multiple validators:
/// ```dart
/// validators: [
///   RjValidators.minLength(8),
///   RjValidators.hasUppercase(),
///   RjValidators.hasDigit(),
/// ]
/// ```
///
/// Override the default error message with the [message] parameter:
/// ```dart
/// RjValidators.email(message: 'আপনার ইমেইল সঠিক নয়')  // Bengali
/// ```
class RjValidators {
  RjValidators._();

  // ─── Required ──────────────────────────────────────────────────────────────

  /// Validates that a value is not null or empty.
  /// Works with strings, lists, and any other type (null check).
  static FieldValidator required({String? message}) {
    return (value) {
      if (value == null) return message ?? 'This field is required';
      if (value is String && value.trim().isEmpty) {
        return message ?? 'This field is required';
      }
      if (value is List && value.isEmpty) {
        return message ?? 'This field is required';
      }
      return null;
    };
  }

  // ─── Text ──────────────────────────────────────────────────────────────────

  /// Validates a properly formatted email address.
  static FieldValidator email({String? message}) {
    return (value) {
      if (value == null || value.toString().trim().isEmpty) return null;
      final pattern = RegExp(r'^[\w.+\-]+@[a-zA-Z0-9\-]+\.[a-zA-Z]{2,}$');
      if (!pattern.hasMatch(value.toString().trim())) {
        return message ?? 'Enter a valid email address';
      }
      return null;
    };
  }

  /// Validates a URL (http or https).
  static FieldValidator url({String? message}) {
    return (value) {
      if (value == null || value.toString().trim().isEmpty) return null;
      final pattern = RegExp(
        r'^(https?:\/\/)?([\w\-]+\.)+[\w]{2,}(\/[\w\-./?%&=]*)?$',
        caseSensitive: false,
      );
      if (!pattern.hasMatch(value.toString().trim())) {
        return message ?? 'Enter a valid URL';
      }
      return null;
    };
  }

  // ─── Phone ────────────────────────────────────────────────────────────────

  /// Validates a phone number — digits only, optional leading +.
  /// Accepts 7–15 digits (international standard).
  static FieldValidator phone({String? message}) {
    return (value) {
      if (value == null || value.toString().trim().isEmpty) return null;
      final pattern = RegExp(r'^\+?[0-9]{7,15}$');
      if (!pattern.hasMatch(value.toString().trim())) {
        return message ?? 'Enter a valid phone number';
      }
      return null;
    };
  }

  /// Validates a Bangladeshi mobile number (starts with 01, 11 digits total).
  static FieldValidator bdPhone({String? message}) {
    return (value) {
      if (value == null || value.toString().trim().isEmpty) return null;
      final pattern = RegExp(r'^01[3-9][0-9]{8}$');
      if (!pattern.hasMatch(value.toString().trim())) {
        return message ??
            'Enter a valid Bangladeshi mobile number (01XXXXXXXXX)';
      }
      return null;
    };
  }

  // ─── Length ───────────────────────────────────────────────────────────────

  /// Requires the string value to be at least [min] characters.
  static FieldValidator minLength(int min, {String? message}) {
    return (value) {
      if (value == null) return null;
      final str = value.toString();
      if (str.length < min) {
        return message ?? 'Must be at least $min characters';
      }
      return null;
    };
  }

  /// Requires the string value to be at most [max] characters.
  static FieldValidator maxLength(int max, {String? message}) {
    return (value) {
      if (value == null) return null;
      final str = value.toString();
      if (str.length > max) {
        return message ?? 'Must be no more than $max characters';
      }
      return null;
    };
  }

  /// Requires the string length to be between [min] and [max] (inclusive).
  static FieldValidator lengthBetween(int min, int max, {String? message}) {
    return (value) {
      if (value == null) return null;
      final len = value.toString().length;
      if (len < min || len > max) {
        return message ?? 'Must be between $min and $max characters';
      }
      return null;
    };
  }

  // ─── Numeric range ────────────────────────────────────────────────────────

  /// Requires the numeric value to be at least [min].
  static FieldValidator min(num min, {String? message}) {
    return (value) {
      if (value == null) return null;
      final n = value is num ? value : num.tryParse(value.toString());
      if (n == null || n < min) {
        return message ?? 'Must be at least $min';
      }
      return null;
    };
  }

  /// Requires the numeric value to be at most [max].
  static FieldValidator max(num max, {String? message}) {
    return (value) {
      if (value == null) return null;
      final n = value is num ? value : num.tryParse(value.toString());
      if (n == null || n > max) {
        return message ?? 'Must be no more than $max';
      }
      return null;
    };
  }

  /// Requires the numeric value to be between [min] and [max] (inclusive).
  static FieldValidator between(num min, num max, {String? message}) {
    return (value) {
      if (value == null) return null;
      final n = value is num ? value : num.tryParse(value.toString());
      if (n == null || n < min || n > max) {
        return message ?? 'Must be between $min and $max';
      }
      return null;
    };
  }

  /// Requires the value to be a positive number (> 0).
  static FieldValidator positive({String? message}) {
    return (value) {
      if (value == null) return null;
      final n = value is num ? value : num.tryParse(value.toString());
      if (n == null || n <= 0) {
        return message ?? 'Must be a positive number';
      }
      return null;
    };
  }

  /// Requires the value to be a non-negative number (≥ 0).
  static FieldValidator nonNegative({String? message}) {
    return (value) {
      if (value == null) return null;
      final n = value is num ? value : num.tryParse(value.toString());
      if (n == null || n < 0) {
        return message ?? 'Must be 0 or greater';
      }
      return null;
    };
  }

  // ─── Password ─────────────────────────────────────────────────────────────

  /// Requires at least one uppercase letter.
  static FieldValidator hasUppercase({String? message}) {
    return (value) {
      if (value == null || value.toString().isEmpty) return null;
      if (!RegExp(r'[A-Z]').hasMatch(value.toString())) {
        return message ?? 'Must contain at least one uppercase letter';
      }
      return null;
    };
  }

  /// Requires at least one lowercase letter.
  static FieldValidator hasLowercase({String? message}) {
    return (value) {
      if (value == null || value.toString().isEmpty) return null;
      if (!RegExp(r'[a-z]').hasMatch(value.toString())) {
        return message ?? 'Must contain at least one lowercase letter';
      }
      return null;
    };
  }

  /// Requires at least one digit.
  static FieldValidator hasDigit({String? message}) {
    return (value) {
      if (value == null || value.toString().isEmpty) return null;
      if (!RegExp(r'[0-9]').hasMatch(value.toString())) {
        return message ?? 'Must contain at least one number';
      }
      return null;
    };
  }

  /// Requires at least one special character.
  static FieldValidator hasSpecialChar({String? message}) {
    return (value) {
      if (value == null || value.toString().isEmpty) return null;
      if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value.toString())) {
        return message ?? 'Must contain at least one special character';
      }
      return null;
    };
  }

  // ─── Pattern ──────────────────────────────────────────────────────────────

  /// Validates against a custom [RegExp] pattern.
  static FieldValidator pattern(RegExp regex, {String? message}) {
    return (value) {
      if (value == null || value.toString().isEmpty) return null;
      if (!regex.hasMatch(value.toString())) {
        return message ?? 'Invalid format';
      }
      return null;
    };
  }

  /// Requires the value to contain only letters (a-z, A-Z).
  static FieldValidator lettersOnly({String? message}) {
    return pattern(
      RegExp(r'^[a-zA-Z\s]+$'),
      message: message ?? 'Only letters are allowed',
    );
  }

  /// Requires the value to contain only digits.
  static FieldValidator digitsOnly({String? message}) {
    return pattern(
      RegExp(r'^[0-9]+$'),
      message: message ?? 'Only numbers are allowed',
    );
  }

  /// Requires the value to be alphanumeric (letters and digits only).
  static FieldValidator alphanumeric({String? message}) {
    return pattern(
      RegExp(r'^[a-zA-Z0-9]+$'),
      message: message ?? 'Only letters and numbers are allowed',
    );
  }

  // ─── Date ─────────────────────────────────────────────────────────────────

  /// Requires the selected date to be in the past (before today).
  static FieldValidator pastDate({String? message}) {
    return (value) {
      if (value == null) return null;
      if (value is DateTime && !value.isBefore(DateTime.now())) {
        return message ?? 'Date must be in the past';
      }
      return null;
    };
  }

  /// Requires the selected date to be in the future (after today).
  static FieldValidator futureDate({String? message}) {
    return (value) {
      if (value == null) return null;
      if (value is DateTime && !value.isAfter(DateTime.now())) {
        return message ?? 'Date must be in the future';
      }
      return null;
    };
  }

  // ─── Selection ────────────────────────────────────────────────────────────

  /// Requires at least [min] items to be selected (for chip/multi-select fields).
  static FieldValidator minSelect(int min, {String? message}) {
    return (value) {
      if (value is List && value.length < min) {
        return message ?? 'Select at least $min option(s)';
      }
      return null;
    };
  }

  /// Requires at most [max] items to be selected (for chip/multi-select fields).
  static FieldValidator maxSelect(int max, {String? message}) {
    return (value) {
      if (value is List && value.length > max) {
        return message ?? 'Select no more than $max option(s)';
      }
      return null;
    };
  }

  // ─── Equality ─────────────────────────────────────────────────────────────

  /// Requires the value to match [other] — useful for confirm password fields.
  /// Pass a getter so the comparison is always against the current value.
  static FieldValidator matches(String Function() other, {String? message}) {
    return (value) {
      if (value?.toString() != other()) {
        return message ?? 'Values do not match';
      }
      return null;
    };
  }

  // ─── Custom ───────────────────────────────────────────────────────────────

  /// Wraps any custom logic into a [FieldValidator].
  ///
  /// Use this when you need a one-off rule that doesn't fit the predefined
  /// validators above:
  ///
  /// ```dart
  /// RjValidators.custom(
  ///   (value) => value == 'admin' ? 'Reserved username' : null,
  /// )
  /// ```
  static FieldValidator custom(String? Function(dynamic value) fn) => fn;
}

/// Typedef re-exported for convenience.
typedef FieldValidator = String? Function(dynamic value);
