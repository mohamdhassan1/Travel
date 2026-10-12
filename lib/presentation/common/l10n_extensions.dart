import 'package:flutter/widgets.dart';

import '../../core/errors/app_failure.dart';
import '../../core/utils/validators.dart';
import '../../l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension FailureMessage on AppFailure {
  String message(AppLocalizations l10n) => switch (type) {
        FailureType.network => l10n.errorNetwork,
        FailureType.timeout => l10n.errorTimeout,
        FailureType.invalidCredentials => l10n.authErrorInvalidCredentials,
        FailureType.emailNotConfirmed => l10n.authErrorEmailNotConfirmed,
        FailureType.emailAlreadyRegistered => l10n.authErrorEmailInUse,
        FailureType.weakPassword => l10n.authErrorWeakPassword,
        FailureType.samePassword => l10n.authErrorSamePassword,
        FailureType.signupDisabled => l10n.authErrorSignupDisabled,
        FailureType.rateLimited => l10n.errorRateLimited,
        FailureType.sessionExpired => l10n.errorSessionExpired,
        FailureType.permissionDenied => l10n.errorPermissionDenied,
        FailureType.notFound => l10n.errorNotFound,
        FailureType.server => l10n.errorServer,
        FailureType.invalidData => l10n.errorInvalidData,
        FailureType.invalidInput => l10n.errorInvalidInput,
        FailureType.packageUnavailable => l10n.bookingErrorPackageUnavailable,
        FailureType.tooManyTravelers => l10n.bookingErrorTooManyTravelers,
        FailureType.invalidTravelDate => l10n.bookingErrorInvalidDate,
        FailureType.bookingNotCancellable => l10n.bookingErrorNotCancellable,
        FailureType.bookingRateLimited => l10n.bookingErrorRateLimited,
        FailureType.idempotencyConflict => l10n.bookingErrorIdempotencyConflict,
        FailureType.unknown => l10n.errorUnknown,
      };
}

extension FieldErrorMessage on FieldError {
  String message(AppLocalizations l10n) => switch (this) {
        FieldError.required => l10n.validationRequired,
        FieldError.invalidEmail => l10n.validationEmailInvalid,
        FieldError.passwordTooShort => l10n.validationPasswordTooShort(
            Validators.minPasswordLength,
          ),
        FieldError.passwordTooWeak => l10n.validationPasswordWeak,
        FieldError.passwordMismatch => l10n.validationPasswordMismatch,
        FieldError.nameTooShort => l10n.validationNameTooShort,
        FieldError.invalidPhone => l10n.validationPhoneInvalid,
        FieldError.textTooLong => l10n.validationTextTooLong(BookingValidators.maxSpecialRequestsLength),
        FieldError.nameTooLong => l10n.validationNameTooLong(
            Validators.maxNameLength,
          ),
      };
}

/// Adapts a pure [Validators] rule to a [FormFieldValidator] with localized text.
FormFieldValidator<String> localizedValidator(
  BuildContext context,
  FieldError? Function(String?) rule,
) =>
    (value) => rule(value)?.message(context.l10n);
