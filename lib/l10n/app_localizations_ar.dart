// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'رحلة';

  @override
  String get commonRetry => 'حاول مرة أخرى';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonGoHome => 'الذهاب إلى الرئيسية';

  @override
  String get commonLoading => 'جارٍ التحميل…';

  @override
  String get commonSystemDefault => 'حسب إعدادات الجهاز';

  @override
  String get errorNetwork => 'يبدو أنك غير متصل بالإنترنت. تحقق من الاتصال وحاول مرة أخرى.';

  @override
  String get errorTimeout => 'استغرق الخادم وقتًا طويلًا للرد. يُرجى المحاولة مرة أخرى.';

  @override
  String get errorServer => 'حدث خطأ من جهتنا. يُرجى المحاولة بعد قليل.';

  @override
  String get errorUnknown => 'حدث أمر غير متوقع. يُرجى المحاولة مرة أخرى.';

  @override
  String get errorPermissionDenied => 'ليست لديك صلاحية للقيام بذلك.';

  @override
  String get errorNotFound => 'لم نتمكن من العثور على ما تبحث عنه.';

  @override
  String get errorSessionExpired => 'انتهت صلاحية جلستك. يُرجى تسجيل الدخول مرة أخرى.';

  @override
  String get errorRateLimited => 'محاولات كثيرة جدًا. انتظر دقيقة ثم حاول مرة أخرى.';

  @override
  String get validationRequired => 'هذا الحقل مطلوب';

  @override
  String get validationEmailInvalid => 'أدخل بريدًا إلكترونيًا صحيحًا';

  @override
  String validationPasswordTooShort(int min) {
    return 'استخدم $min أحرف على الأقل';
  }

  @override
  String get validationPasswordWeak => 'يجب أن تحتوي على حرف ورقم على الأقل';

  @override
  String get validationPasswordMismatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get validationNameTooShort => 'أدخل حرفين على الأقل';

  @override
  String validationNameTooLong(int max) {
    return 'يجب ألا يتجاوز $max حرفًا';
  }

  @override
  String get onboardingSkip => 'تخطٍّ';

  @override
  String get onboardingNext => 'التالي';

  @override
  String get onboarding1Title => 'اكتشف أماكن تلامس روحك';

  @override
  String get onboarding1Body => 'وجهات مختارة بعناية مع تفاصيل صادقة ومواسم محلية وطقس مباشر.';

  @override
  String get onboarding2Title => 'خطّط لكل التفاصيل في مكان واحد';

  @override
  String get onboarding2Body => 'قارن الباقات واختر التواريخ وعدد المسافرين، وراجع السعر الكامل قبل الحجز.';

  @override
  String get onboarding3Title => 'سافر مع تذكيرات في وقتها';

  @override
  String get onboarding3Body => 'نظّم رحلاتك واحصل على تذكيرات قبل موعد السفر.';

  @override
  String get onboardingCreateAccount => 'إنشاء حساب';

  @override
  String get onboardingHaveAccount => 'لديّ حساب بالفعل';

  @override
  String onboardingPageLabel(int current, int total) {
    return 'الصفحة $current من $total';
  }

  @override
  String get authEmailLabel => 'البريد الإلكتروني';

  @override
  String get authEmailHint => 'you@example.com';

  @override
  String get authPasswordLabel => 'كلمة المرور';

  @override
  String get authConfirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String get authNewPasswordLabel => 'كلمة المرور الجديدة';

  @override
  String get authFullNameLabel => 'الاسم الكامل';

  @override
  String get authFullNameHint => 'كما هو مكتوب في هويتك';

  @override
  String get authShowPassword => 'إظهار كلمة المرور';

  @override
  String get authHidePassword => 'إخفاء كلمة المرور';

  @override
  String get authPasswordRequirements => '٨ أحرف على الأقل، تتضمن حروفًا وأرقامًا.';

  @override
  String get loginTitle => 'مرحبًا بعودتك';

  @override
  String get loginSubtitle => 'سجّل الدخول لمتابعة التخطيط لرحلاتك.';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get loginForgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get loginNoAccount => 'جديد في رحلة؟';

  @override
  String get loginCreateAccount => 'إنشاء حساب';

  @override
  String get loginResendConfirmation => 'إعادة إرسال رسالة التأكيد';

  @override
  String get loginConfirmationResent => 'تم إرسال رسالة التأكيد. تحقق من بريدك الوارد.';

  @override
  String get registerTitle => 'أنشئ حسابك';

  @override
  String get registerSubtitle => 'احفظ المفضلة واحجز رحلاتك وأبقِ كل شيء متزامنًا.';

  @override
  String get registerButton => 'إنشاء الحساب';

  @override
  String get registerHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String get registerSignIn => 'تسجيل الدخول';

  @override
  String get registerCheckInboxTitle => 'تحقق من بريدك الوارد';

  @override
  String registerCheckInboxBody(String email) {
    return 'إذا لم يكن $email مسجّلًا من قبل، فقد أرسلنا إليه رابط تأكيد. افتح الرابط لتفعيل حسابك ثم سجّل الدخول.';
  }

  @override
  String get registerResend => 'إعادة الإرسال';

  @override
  String registerResendIn(int seconds) {
    return 'إعادة الإرسال بعد $seconds ث';
  }

  @override
  String get registerBackToSignIn => 'العودة إلى تسجيل الدخول';

  @override
  String get registerEmailResent => 'أعدنا إرسال الرسالة.';

  @override
  String get forgotTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get forgotSubtitle => 'أدخل البريد الإلكتروني الذي سجّلت به وسنرسل لك رابطًا آمنًا لإعادة التعيين.';

  @override
  String get forgotButton => 'إرسال رابط إعادة التعيين';

  @override
  String get forgotSentTitle => 'تحقق من بريدك الإلكتروني';

  @override
  String forgotSentBody(String email) {
    return 'إذا كان هناك حساب مرتبط بـ $email، فرابط إعادة تعيين كلمة المرور في طريقه إليك. افتحه على هذا الجهاز لاختيار كلمة مرور جديدة.';
  }

  @override
  String get resetTitle => 'اختر كلمة مرور جديدة';

  @override
  String get resetSubtitle => 'لقد دخلت عبر رابط آمن لإعادة التعيين. عيّن كلمة مرور جديدة لإنهاء العملية.';

  @override
  String get resetButton => 'تحديث كلمة المرور';

  @override
  String get resetSuccess => 'تم تحديث كلمة المرور.';

  @override
  String get authErrorInvalidCredentials => 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get authErrorEmailNotConfirmed => 'يُرجى تأكيد بريدك الإلكتروني قبل تسجيل الدخول.';

  @override
  String get authErrorEmailInUse => 'يوجد حساب بهذا البريد الإلكتروني بالفعل. جرّب تسجيل الدخول.';

  @override
  String get authErrorWeakPassword => 'كلمة المرور ضعيفة. اختر كلمة أطول وأقل شيوعًا.';

  @override
  String get authErrorSamePassword => 'يجب أن تختلف كلمة المرور الجديدة عن القديمة.';

  @override
  String get authErrorSignupDisabled => 'التسجيل الجديد متوقف حاليًا.';

  @override
  String get sessionEndedBanner => 'تم تسجيل خروجك. يُرجى تسجيل الدخول مرة أخرى.';

  @override
  String get accountEmailVerified => 'البريد الإلكتروني مؤكَّد';

  @override
  String get accountEmailNotVerified => 'البريد الإلكتروني غير مؤكَّد';

  @override
  String accountMemberSince(String date) {
    return 'عضو منذ $date';
  }

  @override
  String get accountSectionAbout => 'حول التطبيق';

  @override
  String get accountSignOut => 'تسجيل الخروج';

  @override
  String get accountSignOutConfirmTitle => 'تسجيل الخروج؟';

  @override
  String get accountSignOutConfirmBody => 'ستحتاج إلى تسجيل الدخول مرة أخرى لرؤية رحلاتك ومفضلتك.';

  @override
  String get accountSignedOutLocally =>
      'تم تسجيل الخروج على هذا الجهاز. تعذّر الوصول إلى الخادم لإنهاء الجلسات الأخرى.';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsTheme => 'المظهر';

  @override
  String get settingsThemeLight => 'فاتح';

  @override
  String get settingsThemeDark => 'داكن';

  @override
  String get settingsPhotoCredits => 'حقوق الصور';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get creditsTitle => 'حقوق الصور';

  @override
  String get creditsIntro => 'تُستخدم الصور وفق تراخيصها الأصلية. شكرًا للمصورين.';

  @override
  String get notFoundTitle => 'الصفحة غير موجودة';

  @override
  String get notFoundBody => 'ربما يكون الرابط الذي اتبعته معطلًا أو أن الصفحة نُقلت.';

  @override
  String get configErrorTitle => 'يلزم إعداد التطبيق';

  @override
  String get configErrorMissing =>
      'هذه النسخة لا تتضمن إعدادات الخادم. شغّل التطبيق باستخدام ‎--dart-define-from-file=env/dev.json (راجع ملف README).';

  @override
  String get configErrorInvalidUrl => 'رابط Supabase المُعدّ ليس رابط https صالحًا.';

  @override
  String get configErrorSecretKey => 'تم تمرير مفتاح سري (service-role). لا يُسمح إلا بالمفتاح العام داخل التطبيق.';

  @override
  String get errorInvalidData => 'استلمنا بيانات لم نتمكن من قراءتها. يُرجى المحاولة لاحقًا.';

  @override
  String get destinationsEmptyTitle => 'لا توجد وجهات بعد';

  @override
  String get destinationsEmptyBody => 'الكتالوج فارغ حاليًا. عُد إلينا قريبًا.';

  @override
  String get destinationsErrorTitle => 'تعذّر تحميل الوجهات';

  @override
  String get destinationFeatured => 'مميّزة';

  @override
  String destinationFromPrice(String price) {
    return 'ابتداءً من $price';
  }

  @override
  String get destinationPerPerson => 'للشخص';

  @override
  String get destinationNoPackages => 'لا توجد باقات متاحة بعد';

  @override
  String destinationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم',
      many: '$count يومًا',
      few: '$count أيام',
      two: 'يومان',
      one: 'يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String destinationDaysRange(int min, int max) {
    return '$min–$max أيام';
  }

  @override
  String get destinationImageUnavailable => 'الصورة غير متاحة';

  @override
  String get accountBrowseDestinations => 'تصفّح الوجهات';

  @override
  String get profileLoadError => 'تعذّر تحميل بيانات ملفك الشخصي.';

  @override
  String get detailsAbout => 'نبذة';

  @override
  String get detailsBestSeason => 'أفضل وقت للزيارة';

  @override
  String get detailsCoordinates => 'الإحداثيات';

  @override
  String get detailsGallery => 'معرض الصور';

  @override
  String detailsGalleryPhoto(int index, int total) {
    return 'الصورة $index من $total';
  }

  @override
  String detailsPhotoCredit(String credit) {
    return 'الصور: $credit';
  }

  @override
  String get detailsPackagesTitle => 'الباقات';

  @override
  String get detailsPackagesEmpty => 'لا توجد باقات متاحة لهذه الوجهة حاليًا.';

  @override
  String get detailsPackagesError => 'تعذّر تحميل الباقات.';

  @override
  String get detailsNotFoundTitle => 'الوجهة غير موجودة';

  @override
  String get detailsNotFoundBody => 'ربما لم تعد متاحة، أو أن الرابط غير صحيح.';

  @override
  String get detailsErrorTitle => 'تعذّر تحميل هذه الوجهة';

  @override
  String get detailsBackToDestinations => 'العودة إلى الوجهات';

  @override
  String get detailsPriceNote => 'أسعار تقديرية للشخص الواحد. لا يتم تحصيل أي مدفوعات في هذا التطبيق.';

  @override
  String get packageIncludes => 'ما تشمله الباقة';

  @override
  String packageMaxTravelers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'حتى $count مسافر',
      many: 'حتى $count مسافرًا',
      few: 'حتى $count مسافرين',
      two: 'حتى مسافرَين',
      one: 'حتى مسافر واحد',
    );
    return '$_temp0';
  }

  @override
  String get favoritesTitle => 'المفضلة';

  @override
  String get favoritesEmptyTitle => 'لا توجد وجهات مفضلة بعد';

  @override
  String get favoritesEmptyBody => 'اضغط على رمز القلب في أي وجهة لحفظها هنا.';

  @override
  String get favoritesErrorTitle => 'تعذّر تحميل المفضلة';

  @override
  String get favoriteAdd => 'إضافة إلى المفضلة';

  @override
  String get favoriteRemove => 'إزالة من المفضلة';

  @override
  String get favoriteAdded => 'تمت الإضافة إلى المفضلة';

  @override
  String get favoriteRemoved => 'تمت الإزالة من المفضلة';

  @override
  String favoriteAddFailed(String reason) {
    return 'تعذّرت الإضافة إلى المفضلة. $reason';
  }

  @override
  String favoriteRemoveFailed(String reason) {
    return 'تعذّرت الإزالة من المفضلة. $reason';
  }

  @override
  String get commonUndo => 'تراجع';

  @override
  String get errorInvalidInput => 'بعض البيانات التي أدخلتها غير صالحة. يُرجى مراجعتها والمحاولة مرة أخرى.';

  @override
  String get bookingErrorPackageUnavailable => 'هذه الباقة لم تعد متاحة. يُرجى اختيار باقة أخرى.';

  @override
  String get bookingErrorTooManyTravelers => 'هذه الباقة لا تسمح بهذا العدد من المسافرين.';

  @override
  String get bookingErrorInvalidDate => 'يُرجى اختيار تاريخ سفر بين الغد وسنة من الآن.';

  @override
  String get bookingErrorNotCancellable => 'لم يعد من الممكن إلغاء هذا الحجز.';

  @override
  String get validationPhoneInvalid => 'أدخل رقم هاتف صحيحًا (أرقام ومسافات و + ( ) -)';

  @override
  String validationTextTooLong(int max) {
    return 'يجب ألا يتجاوز $max حرف';
  }

  @override
  String get packageBookCta => 'احجز هذه الباقة';

  @override
  String get bookingTitle => 'احجز رحلتك';

  @override
  String get bookingPackageLabel => 'الباقة';

  @override
  String get bookingPackageRequired => 'اختر باقة';

  @override
  String get bookingNoPackages => 'لا توجد باقات قابلة للحجز لهذه الوجهة حاليًا.';

  @override
  String get bookingLoadErrorTitle => 'تعذّر تحميل خيارات الحجز';

  @override
  String get bookingTravelDateLabel => 'تاريخ السفر';

  @override
  String get bookingTravelDatePick => 'اختر تاريخًا';

  @override
  String get bookingTravelDateHint => 'يمكنك الحجز من الغد وحتى سنة مقبلة.';

  @override
  String get bookingTravelDateRequired => 'اختر تاريخ السفر';

  @override
  String get bookingTravelersLabel => 'المسافرون';

  @override
  String bookingTravelersMax(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تسمح هذه الباقة بـ $count مسافر كحد أقصى.',
      many: 'تسمح هذه الباقة بـ $count مسافرًا كحد أقصى.',
      few: 'تسمح هذه الباقة بـ $count مسافرين كحد أقصى.',
      two: 'تسمح هذه الباقة بمسافرَين كحد أقصى.',
      one: 'هذه الباقة لمسافر واحد.',
    );
    return '$_temp0';
  }

  @override
  String get bookingTravelersDecrease => 'تقليل عدد المسافرين';

  @override
  String get bookingTravelersIncrease => 'زيادة عدد المسافرين';

  @override
  String bookingTravelersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مسافر',
      many: '$count مسافرًا',
      few: '$count مسافرين',
      two: 'مسافران',
      one: 'مسافر واحد',
    );
    return '$_temp0';
  }

  @override
  String get bookingContactSection => 'بيانات التواصل';

  @override
  String get bookingContactName => 'الاسم الكامل للمسافر الرئيسي';

  @override
  String get bookingContactPhone => 'رقم الهاتف';

  @override
  String get bookingContactPhoneHint => '+20 100 000 0000 (مثال)';

  @override
  String get bookingSpecialRequests => 'طلبات خاصة (اختياري)';

  @override
  String get bookingSpecialRequestsHint => 'احتياجات غذائية، تسهيلات الوصول، تفضيلات الغرف…';

  @override
  String get bookingContinueToReview => 'مراجعة الحجز';

  @override
  String get bookingReviewTitle => 'راجع حجزك';

  @override
  String get bookingReviewEdit => 'تعديل البيانات';

  @override
  String get bookingPricePerPerson => 'السعر للشخص';

  @override
  String get bookingTotal => 'الإجمالي';

  @override
  String get bookingTotalNote => 'يحسب الخادم المبلغ النهائي من سعر الباقة عند التأكيد.';

  @override
  String get bookingNoPaymentNote =>
      'لا يتم تحصيل أي مدفوعات في هذا التطبيق، ولا يتم التحقق من التوفر لحظيًا. التأكيد يسجّل حجزك فقط.';

  @override
  String get bookingConfirmCta => 'تأكيد الحجز';

  @override
  String get bookingConfirmedTitle => 'تم تأكيد الحجز';

  @override
  String get bookingConfirmedBody => 'تم تسجيل حجزك. احتفظ برقم المرجع لأي استفسار.';

  @override
  String get bookingReference => 'رقم المرجع';

  @override
  String get bookingViewMyBookings => 'عرض حجوزاتي';

  @override
  String get bookingDone => 'تم';

  @override
  String get myBookingsTitle => 'حجوزاتي';

  @override
  String get myBookingsFilterUpcoming => 'القادمة';

  @override
  String get myBookingsFilterPast => 'السابقة';

  @override
  String get myBookingsFilterCancelled => 'الملغاة';

  @override
  String get myBookingsEmptyTitle => 'لا توجد حجوزات بعد';

  @override
  String get myBookingsEmptyBody => 'عندما تحجز رحلة ستظهر هنا.';

  @override
  String get myBookingsNoUpcoming => 'ليست لديك رحلات قادمة.';

  @override
  String get myBookingsNoPast => 'ليست لديك رحلات سابقة.';

  @override
  String get myBookingsNoCancelled => 'ليست لديك حجوزات ملغاة.';

  @override
  String get myBookingsErrorTitle => 'تعذّر تحميل حجوزاتك';

  @override
  String get bookingStatusConfirmed => 'مؤكَّد';

  @override
  String get bookingStatusCancelled => 'ملغى';

  @override
  String get bookingPastTrip => 'رحلة سابقة';

  @override
  String get bookingDetailsTitle => 'تفاصيل الحجز';

  @override
  String bookingBookedOn(String date) {
    return 'تم الحجز في $date';
  }

  @override
  String bookingCancelledOn(String date) {
    return 'أُلغي في $date';
  }

  @override
  String get bookingContact => 'التواصل';

  @override
  String get bookingCancelCta => 'إلغاء الحجز';

  @override
  String get bookingCancelConfirmTitle => 'إلغاء هذا الحجز؟';

  @override
  String bookingCancelConfirmBody(String destination, String date) {
    return 'لا يمكن التراجع عن ذلك. سيُلغى حجزك إلى $destination بتاريخ $date.';
  }

  @override
  String get bookingCancelKeep => 'الإبقاء على الحجز';

  @override
  String get bookingCancelledToast => 'تم إلغاء الحجز';

  @override
  String bookingCancelFailed(String reason) {
    return 'تعذّر إلغاء الحجز. $reason';
  }

  @override
  String get bookingCancelPolicy => 'يمكن إلغاء الحجز حتى اليوم السابق للسفر.';

  @override
  String get bookingCatalogItemUnavailable => 'لم يعد مدرجًا في الكتالوج';

  @override
  String get bookingNotFoundTitle => 'الحجز غير موجود';

  @override
  String get bookingNotFoundBody => 'ربما يخص حسابًا آخر، أو أن الرابط غير صحيح.';

  @override
  String get bookingErrorTitle => 'تعذّر تحميل هذا الحجز';

  @override
  String get bookingErrorIdempotencyConflict =>
      'يتطابق طلب الحجز هذا مع طلب سابق بتفاصيل مختلفة. راجع حجوزاتي ثم حاول مرة أخرى.';

  @override
  String get accountNotifications => 'الإشعارات';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsEmptyTitle => 'لا توجد إشعارات بعد';

  @override
  String get notificationsEmptyBody => 'عند حجز رحلة أو إلغائها سيظهر التحديث هنا.';

  @override
  String get notificationsErrorTitle => 'تعذّر تحميل الإشعارات';

  @override
  String get notificationsMarkAllRead => 'تعليم الكل كمقروء';

  @override
  String notificationsActionFailed(String error) {
    return 'تعذّر تحديث الإشعارات. $error';
  }

  @override
  String notificationsUnreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إشعار غير مقروء',
      many: '$count إشعارًا غير مقروء',
      few: '$count إشعارات غير مقروءة',
      two: 'إشعاران غير مقروءين',
      one: 'إشعار واحد غير مقروء',
      zero: 'لا توجد إشعارات غير مقروءة',
    );
    return '$_temp0';
  }

  @override
  String get notificationUnread => 'غير مقروء';

  @override
  String get notificationBookingConfirmedTitle => 'تم تأكيد الحجز';

  @override
  String get notificationBookingCancelledTitle => 'تم إلغاء الحجز';

  @override
  String get notificationTripReminderTitle => 'تذكير بالرحلة';

  @override
  String notificationTripOn(String destination, String date) {
    return '$destination بتاريخ $date';
  }

  @override
  String notificationReference(String reference) {
    return 'المرجع $reference';
  }

  @override
  String get settingsSectionNotifications => 'الإشعارات';

  @override
  String get settingsTripReminders => 'تذكيرات الرحلات';

  @override
  String get settingsTripRemindersSubtitle => 'على هذا الجهاز، الساعة 9:00 في اليوم السابق لكل رحلة مؤكَّدة';

  @override
  String get settingsNotificationsUnsupported => 'تذكيرات الرحلات والإشعارات الفورية غير متاحة على هذه المنصة.';

  @override
  String get settingsNotificationsAllowHint => 'اسمح بالإشعارات لتظهر تذكيرات الرحلات.';

  @override
  String get settingsNotificationsAllow => 'سماح';

  @override
  String get settingsNotificationsBlocked => 'الإشعارات متوقفة لتطبيق رحلة في إعدادات جهازك.';

  @override
  String get settingsNotificationsOpenSettings => 'فتح الإعدادات';

  @override
  String get notificationsPermissionDeniedToast => 'لم يتم السماح بالإشعارات. يمكنك تفعيلها لاحقًا من إعدادات جهازك.';

  @override
  String get tripReminderChannelName => 'تذكيرات الرحلات';

  @override
  String get tripReminderChannelDescription => 'تذكيرات في اليوم السابق لرحلاتك المحجوزة';

  @override
  String tripReminderTitle(String destination) {
    return 'رحلتك إلى $destination غدًا';
  }

  @override
  String get tripReminderTitleGeneric => 'رحلتك غدًا';

  @override
  String tripReminderBody(String package, String date, String reference) {
    return '$package · $date · المرجع $reference';
  }

  @override
  String tripReminderBodyNoPackage(String date, String reference) {
    return '$date · المرجع $reference';
  }

  @override
  String get commonView => 'عرض';

  @override
  String get pushForegroundBookingConfirmed => 'تم تأكيد الحجز';

  @override
  String get pushForegroundBookingCancelled => 'تم إلغاء الحجز';

  @override
  String get bookingUpdatesChannelName => 'تحديثات الحجز';

  @override
  String get bookingUpdatesChannelDescription => 'تأكيد حجوزاتك وإلغاؤها';

  @override
  String get settingsPushTitle => 'تحديثات الحجز';

  @override
  String get settingsPushOn => 'يتم إرسال تأكيدات الحجز وإلغاءاته إلى هذا الجهاز.';

  @override
  String get settingsPushNeedsPermission => 'اسمح بالإشعارات لتصلك تحديثات الحجز على هذا الجهاز.';

  @override
  String get settingsPushUnavailable => 'الإشعارات الفورية غير مُعدّة لهذا الجهاز بعد.';

  @override
  String get settingsPushNotRegistered =>
      'لم يتم تسجيل هذا الجهاز لتحديثات الحجز بعد. سيعيد التطبيق المحاولة عند فتحه مرة أخرى.';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navExplore => 'استكشف';

  @override
  String get navTrips => 'رحلاتي';

  @override
  String get navSaved => 'المحفوظة';

  @override
  String get navProfile => 'حسابي';

  @override
  String get listSeparator => '، ';

  @override
  String get homeGreetingMorning => 'صباح الخير';

  @override
  String get homeGreetingAfternoon => 'طاب يومك';

  @override
  String get homeGreetingEvening => 'مساء الخير';

  @override
  String homeGreetingName(String greeting, String name) {
    return '$greeting، $name';
  }

  @override
  String get homeHeadline => 'إلى أين وجهتك التالية؟';

  @override
  String homeNotificationsUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'الإشعارات، $count إشعار غير مقروء',
      many: 'الإشعارات، $count إشعارًا غير مقروء',
      few: 'الإشعارات، $count إشعارات غير مقروءة',
      two: 'الإشعارات، إشعاران غير مقروءين',
      one: 'الإشعارات، إشعار واحد غير مقروء',
    );
    return '$_temp0';
  }

  @override
  String get homeSearchHint => 'ابحث عن وجهة أو دولة';

  @override
  String get homeNextTrip => 'رحلتك القادمة';

  @override
  String get homeSeeAllTrips => 'كل الرحلات';

  @override
  String get homeTripToday => 'اليوم';

  @override
  String get homeTripTomorrow => 'غدًا';

  @override
  String homeTripInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'بعد $days يوم',
      many: 'بعد $days يومًا',
      few: 'بعد $days أيام',
      two: 'بعد يومين',
      one: 'بعد يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String get homeTripsError => 'تعذّر تحميل رحلاتك.';

  @override
  String get homeNoTripTitle => 'لا توجد رحلات قادمة';

  @override
  String get homeNoTripBody => 'مغامرتك التالية تبدأ باختيار وجهة.';

  @override
  String get homeNoTripCta => 'استكشف';

  @override
  String get homeCategories => 'تصفّح حسب النوع';

  @override
  String get homeFeatured => 'وجهات مميّزة';

  @override
  String get homeFeaturedSubtitle => 'مختارة من كتالوج رحلة';

  @override
  String get homeSeeAll => 'عرض الكل';

  @override
  String get homeRecentlyViewed => 'شاهدتها مؤخرًا';

  @override
  String homeSavedShortcut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count وجهة محفوظة',
      many: '$count وجهة محفوظة',
      few: '$count وجهات محفوظة',
      two: 'وجهتان محفوظتان',
      one: 'وجهة محفوظة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get homeMoreToExplore => 'المزيد لاستكشافه';

  @override
  String get homeMoreToExploreSubtitle => 'بقية الوجهات في الكتالوج';

  @override
  String get homeCatalogError => 'تعذّر تحميل الوجهات.';

  @override
  String get exploreTitle => 'استكشف';

  @override
  String get exploreSearchHint => 'وجهة أو دولة أو تجربة';

  @override
  String get exploreClearSearch => 'مسح البحث';

  @override
  String get exploreFilters => 'عوامل التصفية';

  @override
  String get exploreAllCategories => 'الكل';

  @override
  String exploreResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count وجهة',
      many: '$count وجهة',
      few: '$count وجهات',
      two: 'وجهتان',
      one: 'وجهة واحدة',
      zero: 'لا توجد وجهات',
    );
    return '$_temp0';
  }

  @override
  String get exploreSort => 'الترتيب';

  @override
  String get exploreSortFeatured => 'المميّزة أولًا';

  @override
  String get exploreSortPriceLow => 'السعر: من الأقل للأعلى';

  @override
  String get exploreSortPriceHigh => 'السعر: من الأعلى للأقل';

  @override
  String get exploreSortName => 'الاسم (أ–ي)';

  @override
  String get exploreNoResultsTitle => 'لا توجد وجهات مطابقة';

  @override
  String exploreNoResultsBody(String query) {
    return 'لا شيء يطابق «$query». جرّب اسمًا أو دولة أخرى، أو امسح عوامل التصفية.';
  }

  @override
  String get exploreNoResultsFiltersBody => 'لا توجد وجهة تناسب عوامل التصفية هذه. جرّب توسيعها.';

  @override
  String get exploreClearAll => 'مسح البحث والتصفية';

  @override
  String get exploreMaxPrice => 'السعر المبدئي للشخص';

  @override
  String get exploreAnyPrice => 'أي سعر';

  @override
  String explorePriceUpTo(String price) {
    return 'حتى $price';
  }

  @override
  String get explorePriceNote => 'بحسب أرخص باقة لكل وجهة. الأسعار أسعار نموذجية في الكتالوج.';

  @override
  String get exploreTripLength => 'مدة الرحلة';

  @override
  String get exploreLengthShort => 'عطلة قصيرة (١–٣ أيام)';

  @override
  String get exploreLengthMedium => '٤–٦ أيام';

  @override
  String get exploreLengthLong => 'أسبوع أو أكثر';

  @override
  String get exploreReset => 'إعادة الضبط';

  @override
  String get exploreApply => 'عرض النتائج';

  @override
  String get profileTitle => 'حسابي';

  @override
  String get profileEdit => 'تعديل الملف الشخصي';

  @override
  String get profileSave => 'حفظ التغييرات';

  @override
  String get profileSaved => 'تم تحديث الملف الشخصي.';

  @override
  String get profileSaveFailed => 'تعذّر حفظ ملفك الشخصي.';

  @override
  String get profileDiscardTitle => 'تجاهل التغييرات؟';

  @override
  String get profileDiscardBody => 'لم يتم حفظ تعديلاتك.';

  @override
  String get profileDiscard => 'تجاهل';

  @override
  String get profileKeepEditing => 'متابعة التعديل';

  @override
  String get profilePhoneLabel => 'رقم الهاتف (اختياري)';

  @override
  String get profilePhoneHint => 'مثال: +20 100 000 0000';

  @override
  String get profileEmailReadOnly => 'لا يمكن تغيير بريد تسجيل الدخول من هنا.';

  @override
  String get profileStatsError => 'تعذّر تحميل إحصاءات رحلاتك.';

  @override
  String get profilePhotoChange => 'تغيير الصورة';

  @override
  String get profilePhotoGallery => 'اختيار من المعرض';

  @override
  String get profilePhotoCamera => 'التقاط صورة';

  @override
  String get profilePhotoRemove => 'إزالة الصورة';

  @override
  String get profilePhotoUpdated => 'تم تحديث صورة الملف الشخصي.';

  @override
  String get profilePhotoRemoved => 'تمت إزالة صورة الملف الشخصي.';

  @override
  String get profilePhotoFailed => 'تعذّر تحديث صورتك.';

  @override
  String get profilePhotoTooLarge => 'الصورة كبيرة جدًا (الحد الأقصى ٢ ميغابايت). جرّب صورة أخرى.';

  @override
  String get profilePhotoPickFailed => 'تعذّر فتح منتقي الصور. تحقّق من أذونات التطبيق.';

  @override
  String get levelTitle => 'مستوى المسافر';

  @override
  String get levelNewTraveler => 'مسافر جديد';

  @override
  String get levelExplorer => 'مستكشف';

  @override
  String get levelVoyager => 'رحّالة';

  @override
  String get levelGlobetrotter => 'جوّاب الآفاق';

  @override
  String get levelHowItWorks => 'كيف تعمل المستويات';

  @override
  String get levelProgress => 'التقدّم نحو المستوى التالي';

  @override
  String get levelTopReached => 'وصلت إلى أعلى مستوى. رحلات سعيدة!';

  @override
  String levelNextHint(String missing, String level) {
    return '$missing لتصبح «$level».';
  }

  @override
  String levelTripsMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count رحلة مكتملة أخرى',
      many: '$count رحلة مكتملة أخرى',
      few: '$count رحلات مكتملة أخرى',
      two: 'رحلتان مكتملتان أخريان',
      one: 'رحلة مكتملة أخرى',
    );
    return '$_temp0';
  }

  @override
  String levelCountriesMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دولة أخرى',
      many: '$count دولة أخرى',
      few: '$count دول أخرى',
      two: 'دولتان أخريان',
      one: 'دولة أخرى',
    );
    return '$_temp0';
  }

  @override
  String get levelRulesIntro =>
      'يعتمد مستواك فقط على الرحلات التي قمت بها فعلًا مع رحلة: الحجوزات المؤكَّدة التي مضى تاريخ سفرها. الحجوزات الملغاة لا تُحتسب.';

  @override
  String get levelRuleStart => 'نقطة البداية للجميع';

  @override
  String levelRule(String trips, String countries) {
    return '$trips في $countries';
  }

  @override
  String levelTripsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count رحلة مكتملة',
      many: '$count رحلة مكتملة',
      few: '$count رحلات مكتملة',
      two: 'رحلتان مكتملتان',
      one: 'رحلة مكتملة واحدة',
    );
    return '$_temp0';
  }

  @override
  String levelCountriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دولة مختلفة',
      many: '$count دولة مختلفة',
      few: '$count دول مختلفة',
      two: 'دولتين مختلفتين',
      one: 'دولة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get levelRulesNote => 'هذا ليس تقييمًا من أشخاص آخرين — لا يوجد في رحلة نظام مراجعات. إنه يعكس سجل سفرك فقط.';

  @override
  String get statsCompleted => 'رحلات قمت بها';

  @override
  String get statsUpcoming => 'قادمة';

  @override
  String get statsDestinations => 'وجهات زرتها';

  @override
  String get statsCountries => 'دول زرتها';

  @override
  String statsFootnote(int total, int cancelled) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'بناءً على $total حجز',
      many: 'بناءً على $total حجزًا',
      few: 'بناءً على $total حجوزات',
      two: 'بناءً على حجزين',
      one: 'بناءً على حجز واحد',
    );
    String _temp1 = intl.Intl.pluralLogic(
      cancelled,
      locale: localeName,
      other: '$cancelled حجز ملغى',
      many: '$cancelled حجزًا ملغى',
      few: '$cancelled حجوزات ملغاة',
      two: 'حجزان ملغيان',
      one: 'حجز ملغى واحد',
      zero: 'لا توجد إلغاءات',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get statsNoBookings => 'لا توجد حجوزات بعد — ستظهر إحصاءاتك بعد رحلتك الأولى.';

  @override
  String get weatherTitle => 'الطقس الآن';

  @override
  String get weatherUnavailable => 'معلومات الطقس غير متاحة حاليًا.';

  @override
  String get weatherSource => 'طقس مباشر في الوجهة · البيانات من Open-Meteo.com';

  @override
  String weatherDegrees(int value) {
    return '$value°م';
  }

  @override
  String get weatherClear => 'صافٍ';

  @override
  String get weatherPartlyCloudy => 'غائم جزئيًا';

  @override
  String get weatherCloudy => 'غائم';

  @override
  String get weatherFog => 'ضباب';

  @override
  String get weatherDrizzle => 'رذاذ';

  @override
  String get weatherRain => 'مطر';

  @override
  String get weatherSnow => 'ثلج';

  @override
  String get weatherShowers => 'زخات مطر';

  @override
  String get weatherThunderstorm => 'عاصفة رعدية';

  @override
  String get weatherUnknown => 'الطقس';

  @override
  String get detailsShare => 'مشاركة';

  @override
  String detailsShareText(String name, String country, String summary, String link) {
    return '$name، $country — $summary\nافتحها في رحلة: $link';
  }

  @override
  String get detailsShareUnavailable => 'المشاركة غير متاحة على هذا الجهاز.';

  @override
  String get accountDelete => 'حذف الحساب';

  @override
  String get accountDeleteTitle => 'حذف حسابك؟';

  @override
  String get accountDeleteBody =>
      'سيؤدي هذا إلى حذف ملفك الشخصي وصورتك وحجوزاتك ووجهاتك المحفوظة وإشعاراتك من رحلة نهائيًا. لا يمكن التراجع عن ذلك.';

  @override
  String get accountDeleteConfirmCheck => 'أفهم أنه لا يمكن التراجع عن ذلك';

  @override
  String get accountDeleteCta => 'حذف نهائيًا';

  @override
  String get accountDeleted => 'تم حذف حسابك.';

  @override
  String accountDeleteFailed(String reason) {
    return 'تعذّر حذف حسابك. $reason';
  }

  @override
  String get settingsSectionAccount => 'الحساب';

  @override
  String get accountChangePassword => 'تغيير كلمة المرور';

  @override
  String get changePasswordTitle => 'غيّر كلمة المرور';

  @override
  String get changePasswordSubtitle => 'اختر كلمة مرور جديدة لحسابك. ستبقى مسجّلًا الدخول على هذا الجهاز.';

  @override
  String get bookingErrorRateLimited => 'أجريت عدة حجوزات خلال الساعة الماضية. يُرجى المحاولة لاحقًا.';

  @override
  String get bookingViewDestination => 'عرض الوجهة';

  @override
  String favoritesRefreshFailed(String reason) {
    return 'تعذّر تحديث وجهاتك المحفوظة. $reason';
  }
}
