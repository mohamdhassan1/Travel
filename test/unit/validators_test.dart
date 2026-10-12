import 'package:flutter_test/flutter_test.dart';
import 'package:rahala/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('requires a value', () {
      expect(Validators.email(null), FieldError.required);
      expect(Validators.email('   '), FieldError.required);
    });

    test('rejects malformed addresses', () {
      for (final bad in [
        'plain',
        'a@b',
        'a@@b.com',
        '@example.com',
        'a@example.',
        'a b@example.com',
      ]) {
        expect(Validators.email(bad), FieldError.invalidEmail, reason: bad);
      }
    });

    test('accepts valid addresses, trimming whitespace', () {
      for (final good in [
        'a@b.co',
        ' first.last+tag@sub.example.travel ',
        "o'neil@example.org",
      ]) {
        expect(Validators.email(good), isNull, reason: good);
      }
    });
  });

  group('Validators.newPassword', () {
    test('enforces length before strength', () {
      expect(Validators.newPassword(''), FieldError.required);
      expect(Validators.newPassword('a1b2'), FieldError.passwordTooShort);
    });

    test('requires letters and digits', () {
      expect(Validators.newPassword('abcdefgh'), FieldError.passwordTooWeak);
      expect(Validators.newPassword('12345678'), FieldError.passwordTooWeak);
      expect(Validators.newPassword('travel2026'), isNull);
    });

    test('counts Arabic letters and Arabic-Indic digits', () {
      expect(Validators.newPassword('سفرسعيد٢٠٢٦'), isNull);
    });
  });

  test('loginPassword only checks presence (server is the authority)', () {
    expect(Validators.loginPassword(''), FieldError.required);
    expect(Validators.loginPassword('x'), isNull);
  });

  test('confirmPassword must match', () {
    expect(Validators.confirmPassword('', 'abc'), FieldError.required);
    expect(
      Validators.confirmPassword('abd', 'abc'),
      FieldError.passwordMismatch,
    );
    expect(Validators.confirmPassword('abc', 'abc'), isNull);
  });

  test('fullName bounds', () {
    expect(Validators.fullName(' '), FieldError.required);
    expect(Validators.fullName('A'), FieldError.nameTooShort);
    expect(Validators.fullName('A' * 81), FieldError.nameTooLong);
    expect(Validators.fullName('سارة علي'), isNull);
  });
}
