/// Why a form field is invalid. Localized in the presentation layer.
enum FieldError {
  required,
  invalidEmail,
  passwordTooShort,
  passwordTooWeak,
  passwordMismatch,
  nameTooShort,
  nameTooLong,
  invalidPhone,
  textTooLong,
}

/// Pure validation rules shared by every form.
abstract final class Validators {
  static const minPasswordLength = 8;
  static const maxNameLength = 80;

  static final _email = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}$",
  );
  static final _letter = RegExp(r'\p{L}', unicode: true);
  static final _digit = RegExp(r'\p{Nd}', unicode: true);

  static FieldError? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return FieldError.required;
    if (!_email.hasMatch(v)) return FieldError.invalidEmail;
    return null;
  }

  /// Sign-in only checks presence: strength rules may have changed since the
  /// account was created, and the server is the authority.
  static FieldError? loginPassword(String? value) => (value == null || value.isEmpty) ? FieldError.required : null;

  static FieldError? newPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return FieldError.required;
    if (v.length < minPasswordLength) return FieldError.passwordTooShort;
    if (!_letter.hasMatch(v) || !_digit.hasMatch(v)) return FieldError.passwordTooWeak;
    return null;
  }

  static FieldError? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return FieldError.required;
    if (value != original) return FieldError.passwordMismatch;
    return null;
  }

  static FieldError? fullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return FieldError.required;
    if (v.length < 2) return FieldError.nameTooShort;
    if (v.length > maxNameLength) return FieldError.nameTooLong;
    return null;
  }
}

/// Rules that mirror the `bookings` table's CHECK constraints, so invalid
/// input is caught before a request is sent (the database still enforces them).
abstract final class BookingValidators {
  static const maxSpecialRequestsLength = 500;

  /// Same pattern as `bookings_contact_phone_check`: optional leading `+`,
  /// then 6–20 digits, spaces, parentheses or dashes.
  static final _phone = RegExp(r'^\+?[0-9 ()-]{6,20}$');

  static FieldError? contactName(String? value) => Validators.fullName(value);

  static FieldError? contactPhone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return FieldError.required;
    if (!_phone.hasMatch(v) || !RegExp(r'[0-9]').hasMatch(v)) return FieldError.invalidPhone;
    return null;
  }

  static FieldError? specialRequests(String? value) =>
      (value?.length ?? 0) > maxSpecialRequestsLength ? FieldError.textTooLong : null;
}

/// Rules that mirror the `profiles` table's CHECK constraints.
abstract final class ProfileValidators {
  static FieldError? fullName(String? value) => Validators.fullName(value);

  /// Optional; when present, same pattern as `profiles_phone_check`.
  static FieldError? phone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    return BookingValidators.contactPhone(v);
  }
}
