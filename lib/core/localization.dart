import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported app languages
enum AppLanguage { ka, en }

/// Localization provider — stores current language, rebuilds UI on change.
class LocaleProvider extends ChangeNotifier {
  static const _kLangKey = 'app_language';

  AppLanguage _language = AppLanguage.ka;
  AppLanguage get language => _language;

  /// True if the user has never picked a language (first launch).
  bool _isFirstLaunch = true;
  bool get isFirstLaunch => _isFirstLaunch;

  /// Load saved language from SharedPreferences.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kLangKey);
    if (stored != null) {
      _language = stored == 'en' ? AppLanguage.en : AppLanguage.ka;
      _isFirstLaunch = false;
    }
  }

  /// Change language and persist.
  Future<void> setLanguage(AppLanguage lang) async {
    if (_language == lang && !_isFirstLaunch) return;
    _language = lang;
    _isFirstLaunch = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLangKey, lang == AppLanguage.en ? 'en' : 'ka');
    notifyListeners();
  }

  /// Shorthand to get the current strings.
  AppStrings get s => AppStrings._forLanguage(_language);
}

/// All localised strings for the app.
class AppStrings {
  final AppLanguage _lang;
  const AppStrings._forLanguage(this._lang);

  /// Create strings for a given language (useful outside widget tree).
  const factory AppStrings.forLanguage(AppLanguage lang) = AppStrings._forLanguage;

  /// Convenience: get strings from a BuildContext.
  static AppStrings of(BuildContext context) {
    // Works outside Provider too for models — provide a fallback.
    try {
      return context
          .dependOnInheritedWidgetOfExactType<_LocaleInherited>()!
          .strings;
    } catch (_) {
      return const AppStrings._forLanguage(AppLanguage.ka);
    }
  }

  String _t(String ka, String en) => _lang == AppLanguage.en ? en : ka;

  // ─── Common ───
  String get appName => 'SmartLuxy';
  String get error => _t('შეცდომა', 'Error');
  String get cancel => _t('გაუქმება', 'Cancel');
  String get close => _t('დახურვა', 'Close');
  String get yes => _t('დიახ', 'Yes');
  String get no => _t('არა', 'No');
  String get retryBtn => _t('ხელახლა ცდა', 'Retry');
  String get required_ => _t('სავალდებულოა', 'Required');
  String get skip => _t('გამოტოვება', 'Skip');
  String get confirm => _t('დადასტურება', 'Confirm');
  String get continueBtn => _t('გაგრძელება', 'Continue');
  String get start => _t('დაწყება', 'Get Started');
  String get loading => _t('იტვირთება...', 'Loading...');

  // ─── Splash ───
  String get splashSubtitle => _t('კომფორტი ერთი შეხებით', 'Comfort at Your Fingertips');
  String get chooseLanguage => _t('აირჩიეთ ენა', 'Choose Language');
  String get georgian => _t('ქართული', 'Georgian');
  String get english => _t('English', 'English');

  // ─── Onboarding ───
  String get onboardingTitle1 => _t('მიიღეთ მაქსიმალური კომფორტი', 'Get Maximum Comfort');
  String get onboardingSubtitle1 =>
      _t('Smart Luxy — თქვენი საცხოვრებელი კომპლექსის მართვა ერთ აპლიკაციაში.',
          'Smart Luxy — manage your residential complex in one app.');
  String get onboardingFeature1a => _t('გადახადეთ საცხოვრებელი ხარჯი', 'Pay your housing fees');
  String get onboardingFeature1b => _t('გახსენით კარი დისტანციურად', 'Open doors remotely');
  String get onboardingFeature1c => _t('ყველაფერი ერთ აპლიკაციაში', 'Everything in one app');

  String get onboardingTitle2 => _t('შეტყობინებები', 'Notifications');
  String get onboardingSubtitle2 =>
      _t('მიიღეთ ნოტიფიკაცია გადახდებზე და ახალ მოთხოვნებზე რეალურ დროში.',
          'Get notified about payments and new requests in real time.');
  String get onboardingFeature2a => _t('ახალი მოთხოვნა ბინაში', 'New apartment request');
  String get onboardingFeature2b => _t('გადახდის დადასტურება', 'Payment confirmation');
  String get onboardingFeature2c => _t('ვადის გახსენება', 'Deadline reminders');

  String get onboardingTitle3 => _t('კამერა და გალერეა', 'Camera & Gallery');
  String get onboardingSubtitle3 =>
      _t('პროფილის სურათის ატვირთვისთვის საჭიროა კამერასა და გალერეაზე წვდომა.',
          'Camera and gallery access is needed to upload a profile photo.');
  String get onboardingFeature3a => _t('გადაიღეთ ახალი ფოტო', 'Take a new photo');
  String get onboardingFeature3b => _t('აირჩიეთ გალერეიდან', 'Choose from gallery');

  String get onboardingTitleFinal => _t('მზად ხართ!', 'You\'re Ready!');
  String get onboardingSubtitleFinal =>
      _t('ყველა ნებართვა მინიჭებულია. ახლა შეგიძლიათ სრულად ისარგებლოთ აპლიკაციით.',
          'All permissions granted. You can now fully use the app.');

  String get permissionRequired => _t('ნებართვა საჭიროა', 'Permission Required');
  String get permissionDeniedMsg =>
      _t('ეს ნებართვა სამუდამოდ უარყოფილია. გთხოვთ გახსნათ პარამეტრები და ხელით ჩართოთ.',
          'This permission is permanently denied. Please open settings and enable it manually.');
  String get openSettings => _t('პარამეტრები', 'Settings');
  String get permissionGranted => _t('ნებართვა მინიჭებულია!', 'Permission Granted!');
  String get grantPermission => _t('ნებართვის მინიჭება', 'Grant Permission');
  String get requesting => _t('მოთხოვნა...', 'Requesting...');

  // ─── Navigation ───
  String get navHome => _t('მთავარი', 'Home');
  String get navDoors => _t('კარები', 'Doors');
  String get navPayments => _t('გადახდები', 'Payments');
  String get navSettings => _t('პარამეტრები', 'Settings');

  // ─── Auth / Login ───
  String get loginTitle => _t('გაიარეთ ავტორიზაცია', 'Sign In');
  String get email => _t('ელ.ფოსტა', 'Email');
  String get emailRequired => _t('ელ.ფოსტა სავალდებულოა', 'Email is required');
  String get emailInvalid => _t('ელ.ფოსტის ფორმატი არასწორია', 'Invalid email format');
  String get password => _t('პაროლი', 'Password');
  String get passwordRequired => _t('პაროლი სავალდებულოა', 'Password is required');
  String get forgotPassword => _t('პაროლი დაგავიწყდათ?', 'Forgot Password?');
  String get signIn => _t('შესვლა', 'Sign In');
  String get noAccount => _t('არ გაქვთ ანგარიში? ', 'Don\'t have an account? ');
  String get register => _t('რეგისტრაცია', 'Register');
  String get loginFailed => _t('ავტორიზაცია ვერ მოხერხდა', 'Login failed');
  String get generalError => _t('დაფიქსირდა შეცდომა. სცადეთ მოგვიანებით.', 'An error occurred. Try again later.');

  // ─── Register ───
  String get registerTitle => _t('რეგისტრაცია', 'Register');
  String get firstName => _t('სახელი', 'First Name');
  String get lastName => _t('გვარი', 'Last Name');
  String get personalId => _t('პირადი ნომერი', 'Personal ID');
  String get personalIdHint => _t('11 ციფრი', '11 digits');
  String get phone => _t('ტელეფონი', 'Phone');
  String get phoneFormat => _t('ფორმატი: 5XXXXXXXX', 'Format: 5XXXXXXXX');
  String get invalidFormat => _t('არასწორი ფორმატი', 'Invalid format');
  String get minChars6 => _t('მინ. 6 სიმბოლო', 'Min. 6 characters');
  String get complex => _t('კომპლექსი', 'Complex');
  String get chooseComplex => _t('აირჩიეთ კომპლექსი', 'Choose Complex');
  String get apartment => _t('ბინა', 'Apartment');
  String get registerFailed => _t('რეგისტრაცია ვერ მოხერხდა', 'Registration failed');
  String get requestSent => _t('მოთხოვნა გაგზავნილია', 'Request Sent');
  String get requestSentMsg =>
      _t('თქვენი მოთხოვნა მფლობელს გაეგზავნა დასადასტურებლად.',
          'Your request has been sent to the owner for approval.');
  String get understood => _t('გასაგებია', 'OK');
  String get alreadyHaveAccount => _t('უკვე გაქვთ ანგარიში? შესვლა', 'Already have an account? Sign In');

  // ─── Forgot Password ───
  String get forgotTitle => _t('პაროლის აღდგენა', 'Password Recovery');
  String get enterPhone => _t('შეიყვანეთ ტელეფონის ნომერი', 'Enter your phone number');
  String get smsHint => _t('SMS-ით გამოგიგზავნით დადასტურების კოდს', 'We\'ll send you an SMS verification code');
  String get sendCode => _t('კოდის გაგზავნა', 'Send Code');
  String get codeSentSms => _t('კოდი გაიგზავნა SMS-ით', 'Code sent via SMS');
  String get enterSmsCode => _t('შეიყვანეთ SMS კოდი', 'Enter SMS Code');
  String codeSentTo(String p) => _t('კოდი გაგზავნილია ნომერზე: $p', 'Code sent to: $p');
  String get enter6digitCode => _t('შეიყვანეთ 6-ნიშნა კოდი', 'Enter 6-digit code');
  String get codeInvalid => _t('კოდი არასწორია', 'Invalid code');
  String get newPassword => _t('ახალი პაროლი', 'New Password');
  String get enterNewPassword => _t('შეიყვანეთ ახალი პაროლი (მინ. 6 სიმბოლო)', 'Enter new password (min. 6 characters)');
  String get passwordMinHint => _t('პაროლი მინ. 6 სიმბოლო', 'Password min. 6 characters');
  String get changePassword => _t('პაროლის შეცვლა', 'Change Password');
  String get passwordChanged => _t('პაროლი შეცვლილია', 'Password Changed');
  String get signInWithNewPassword =>
      _t('გთხოვთ გაიაროთ ავტორიზაცია ახალი პაროლით.', 'Please sign in with your new password.');

  // ─── Dashboard ───
  String get owner => _t('მფლობელი', 'Owner');
  String get resident => _t('მცხოვრები', 'Resident');
  String get aptLabel => _t('ბინა', 'Apt');
  String get floor => _t('სართული', 'Floor');
  String get building => _t('კორპუსი', 'Building');
  String aptBuilding(String n, String b) => _t('ბინა $n $b', 'Apt $n $b');
  String buildingLabel(String b) => _t('$b კორპუსი', 'Building $b');
  String aptFloor(String f) => _t('სართ. $f', 'Floor $f');
  String aptNumber(String n) => _t('ბინა $n', 'Apt $n');

  String get accessBlocked => _t('წვდომა დაბლოკილია', 'Access Blocked');
  String get accessActive => _t('წვდომა აქტიურია', 'Access Active');
  String get accessLimited => _t('წვდომა შეზღუდულია', 'Access Limited');
  String get paid => _t('გადახდილი', 'Paid');
  String get unpaid => _t('გადასახდელი', 'Unpaid');
  String get residential => _t('საცხოვრებელი', 'Residential');
  String get parking => _t('პარკინგი', 'Parking');
  String get discount => _t('ფასდაკლება', 'Discount');
  String get total => _t('სულ', 'Total');
  String get payment => _t('გადახდა', 'Payment');
  String debtTotal(String amount) => _t('დავალიანება: $amount ₾', 'Debt: $amount ₾');

  String get complexStats => _t('კომპლექსის სტატისტიკა', 'Complex Statistics');
  String complexProgress(int paidCount, int totalCount, String percent) =>
      _t('$paidCount/$totalCount ბინა გადახდილი ($percent%)',
          '$paidCount/$totalCount apartments paid ($percent%)');

  String pendingApprovalsCount(int n) => _t('მოთხოვნები ($n)', 'Requests ($n)');
  String get seeAll => _t('ყველა', 'See All');
  String approvedMsg(String name) => _t('$name დადასტურებულია ✓', '$name approved ✓');
  String get rejectRequest => _t('მოთხოვნის უარყოფა', 'Reject Request');
  String rejectConfirm(String name) =>
      _t('ნამდვილად გსურთ $name-ის მოთხოვნის უარყოფა?',
          'Are you sure you want to reject $name\'s request?');
  String get reject => _t('უარყოფა', 'Reject');
  String get requestRejected => _t('მოთხოვნა უარყოფილია', 'Request Rejected');
  String get approve => _t('დადასტურება', 'Approve');

  String residentsCount(int n) => _t('მცხოვრებლები ($n)', 'Residents ($n)');
  String get me => _t('მე', 'Me');

  String get successful => _t('წარმატებული', 'Successful');
  String get processing => _t('მუშავდება', 'Processing');
  String get failed => _t('წარუმატებელი', 'Failed');
  String get latestPayment => _t('ბოლო გადახდა', 'Latest Payment');

  // ─── Dashboard model status labels ───
  String get adminBlocked => _t('ადმინის მიერ დაბლოკილი', 'Blocked by Admin');
  String gracePeriod(int days) =>
      _t('Grace Period — $days დღე დარჩა', 'Grace Period — $days days left');
  String get paidActive => _t('გადახდილი — აქტიური', 'Paid — Active');
  String get active => _t('აქტიური', 'Active');
  String get neverPaid => _t('არასდროს გადახდილი', 'Never Paid');
  String get blockedUnpaid => _t('დაბლოკილი — გადაუხდელობა', 'Blocked — Unpaid');
  String get blocked => _t('დაბლოკილი', 'Blocked');

  // ─── Credit Days ───
  String get creditDays => _t('+ბალანს დღეები', '+Balance Days');
  String get creditActive => _t('+ბალანსი აქტიურია', '+Balance Active');
  String creditDaysRemaining(int n) => _t('$n დღე დარჩა', '$n days remaining');
  String get creditAmount => _t('გადახდილი თანხა', 'Amount Paid');
  String get creditDailyRate => _t('დღიური ტარიფი', 'Daily Rate');
  String get creditPeriod => _t('პერიოდი', 'Period');
  String get creditDaysGranted => _t('მინიჭებული დღეები', 'Days Granted');
  String creditGapWarning(int days, double dailyRate, double totalAmount, String deadline) =>
      _t('+ბალანსის შემდეგ $days დღე × ${dailyRate.toStringAsFixed(0)}₾ = ${totalAmount.toStringAsFixed(0)}₾ ($deadline-მდე)',
          'After balance: $days days × ${dailyRate.toStringAsFixed(0)}₾ = ${totalAmount.toStringAsFixed(0)}₾ (until $deadline)');

  // ─── Doors ───
  String get doorsTitle => _t('კარები', 'Doors');
  String get doorsNotFound => _t('კარები ვერ მოიძებნა', 'No doors found');
  String get doorOpened => _t('კარი გაიხსნა', 'Door Opened');
  String get doorOpenFailed => _t('კარის გახსნა ვერ მოხერხდა', 'Failed to open door');
  String get openBtn => _t('გახსნა', 'Open');
  String cooldownSec(int n) => _t('$n წმ', '${n}s');
  String get elevator => _t('ლიფტი', 'Elevator');
  String get door => _t('კარი', 'Door');
  String cooldownWait(int n) => _t('გთხოვთ დაიცადოთ $n წამი', 'Please wait $n seconds');
  String get elevatorPin => _t('ლიფტის PIN კოდი', 'Elevator PIN Code');
  String get pinChangesDaily => _t('იცვლება ყოველ 24 საათში', 'Changes every 24 hours');
  String get pinUpdated => _t('განახლდა', 'Updated');
  String get pinNextRotation => _t('შემდეგი ცვლილება', 'Next change');
  String get pinAccessDenied => _t('PIN კოდზე წვდომა შეზღუდულია გადაუხდელობის გამო', 'PIN access restricted due to unpaid fees');
  String get pinNotGenerated => _t('PIN კოდი ჯერ არ არის გენერირებული', 'PIN code not yet generated');
  String get doorsAndElevator => _t('კარები და ლიფტი', 'Doors & Elevator');
  String get entrances => _t('შესასვლელები', 'Entrances');
  String get elevators => _t('ლიფტები', 'Elevators');
  String get accessGranted => _t('წვდომა აქტიურია', 'Access granted');
  String get accessDenied => _t('წვდომა შეზღუდულია', 'Access denied');
  String get gracePeriodLabel => _t('Grace Period', 'Grace Period');
  String graceDaysLeft(int n) => _t('$n დღე დარჩა', '$n days left');

  // ─── Payments ───
  String get paymentHistory => _t('გადახდების ისტორია', 'Payment History');
  String get paymentHistoryEmpty => _t('გადახდების ისტორია ცარიელია', 'Payment history is empty');
  String paymentApt(String n) => _t('ბინა $n', 'Apt $n');
  String get paymentTitle => _t('გადახდა', 'Payment');
  String totalMonths(int n) => _t('სულ ($n თვე)', 'Total ($n months)');
  String get debt => _t('დავალიანება', 'Debt');
  String get currentMonth => _t('მიმდინარე თვე', 'Current Month');
  String get prepayment => _t('წინასწარი', 'Prepayment');

  String get paymentSuccess => _t('გადახდა წარმატებულია', 'Payment Successful');
  String get paymentSuccessMsg => _t('თქვენი გადახდა წარმატებით შესრულდა.', 'Your payment was completed successfully.');
  String get paymentFailed => _t('გადახდა ვერ მოხერხდა', 'Payment Failed');
  String get paymentFailedMsg => _t('გადახდა არ შესრულდა. სცადეთ ხელახლა.', 'Payment failed. Please try again.');
  String get paymentPendingMsg => _t('გადახდა მუშავდება. სტატუსი მალე განახლდება.', 'Payment is being processed. Status will update shortly.');
  String get cancelPayment => _t('გადახდის გაუქმება', 'Cancel Payment');
  String get cancelPaymentMsg => _t('ნამდვილად გსურთ გადახდის გაუქმება?', 'Are you sure you want to cancel the payment?');

  // ─── Residents ───
  String get residentsTitle => _t('მცხოვრებლები', 'Residents');
  String aptComplex(String apt, String complex) => _t('ბინა $apt — $complex', 'Apt $apt — $complex');
  String get you => _t('თქვენ', 'You');
  String pendingRequests(int n) => _t('მოლოდინი მოთხოვნები ($n)', 'Pending Requests ($n)');
  String get removeResident => _t('მცხოვრების წაშლა', 'Remove Resident');
  String removeConfirm(String name) =>
      _t('ნამდვილად გსურთ $name-ის წაშლა?', 'Are you sure you want to remove $name?');
  String get removeBtn => _t('წაშლა', 'Remove');
  String get rejectRequestTitle => _t('მოთხოვნის უარყოფა', 'Reject Request');
  String get rejectRequestMsg =>
      _t('ნამდვილად გსურთ ამ მოთხოვნის უარყოფა?', 'Are you sure you want to reject this request?');

  // ─── Settings ───
  String get settingsTitle => _t('პარამეტრები', 'Settings');
  String get personalInfo => _t('პირადი ინფორმაცია', 'Personal Info');
  String get personalNo => _t('პირადი №', 'Personal ID');
  String get apartments => _t('ბინ(ებ)ი', 'Apartment(s)');
  String get billingInfo => _t('გადახდის ინფორმაცია', 'Billing Info');
  String get project => _t('პროექტი', 'Project');
  String get monthlyFeeLabel => _t('ყოველთვიური', 'Monthly Fee');
  String get parkingFeeLabel => _t('პარკინგის საფასური', 'Parking Fee');
  String get paymentDeadline => _t('გადახდის ვადა', 'Payment Deadline');
  String deadlineDay(int day) => _t('ყოველი თვის $day რიცხვი', 'Day $day of each month');
  String daysRemaining(int days) => _t('დარჩენილია $days დღე', '$days days remaining');
  String get daysLeft => _t('დღე დარჩა', 'days left');
  String daysPassed(int days) => _t('გავლილია $days დღე', '$days days passed');
  String get deadlinePassed => _t('ვადა გასულია', 'Deadline passed');
  String get paidOnTime => _t('დროულად გადახდილი', 'Paid on time');
  String get all => _t('ყველა', 'All');
  String get changePhone => _t('ტელეფონის შეცვლა', 'Change Phone');
  String get changePasswordSetting => _t('პაროლის შეცვლა', 'Change Password');
  String get activeSessions => _t('აქტიური სესიები', 'Active Sessions');
  String get current => _t('მიმდინარე', 'Current');
  String get clearOtherSessions => _t('სხვა სესიების დასუფთავება', 'Clear Other Sessions');
  String get clearOtherSessionsConfirm => _t('ყველა სხვა მოწყობილობიდან გამოსვლა. საჭიროა ხელახლა ავტორიზაცია.', 'You will be logged out from all other devices. Re-login is required.');
  String get sessionsCleared => _t('სესიები გასუფთავდა', 'Sessions cleared');
  String get logout => _t('გამოსვლა', 'Log Out');
  String get logoutAll => _t('ყველა მოწყობილობიდან გამოსვლა', 'Log Out From All Devices');
  String get logoutConfirm => _t('ნამდვილად გსურთ გამოსვლა?', 'Are you sure you want to log out?');
  String get logoutAllConfirm =>
      _t('ნამდვილად გსურთ ყველა მოწყობილობიდან გამოსვლა?',
          'Are you sure you want to log out from all devices?');
  String get imageUpdated => _t('სურათი განახლდა', 'Image Updated');
  String get imageUploadFailed => _t('სურათის ატვირთვა ვერ მოხერხდა', 'Image upload failed');

  // Delete Account
  String get deleteAccount => _t('ანგარიშის წაშლა', 'Delete Account');
  String get deleteAccountTitle => _t('ანგარიშის წაშლის მოთხოვნა', 'Account Deletion Request');
  String get deleteWarning => _t('ანგარიშის წაშლა შეუქცევადია. ყველა მონაცემი სამუდამოდ წაიშლება.', 'Account deletion is irreversible. All data will be permanently deleted.');
  String get deleteInfoTitle => _t('რა მოხდება ანგარიშის წაშლის შემდეგ?', 'What happens after account deletion?');
  String get deleteInfoBody => _t('• თქვენი პერსონალური მონაცემები წაიშლება\n• გადახდების ისტორია წაიშლება\n• აპლიკაციაში ავტორიზაცია ვეღარ მოხერხდება\n• მოთხოვნის დამუშავებას შეიძლება დასჭირდეს 30 სამუშაო დღე', '• Your personal data will be deleted\n• Payment history will be removed\n• You will no longer be able to log in\n• Processing may take up to 30 business days');
  String get deleteReasonLabel => _t('მიუთითეთ წაშლის მიზეზი:', 'Please select a reason:');
  String get deleteReasonNoUse => _t('აღარ ვიყენებ სერვისს', 'I no longer use the service');
  String get deleteReasonPrivacy => _t('კონფიდენციალურობის შეშფოთება', 'Privacy concerns');
  String get deleteReasonOtherService => _t('სხვა სერვისზე გადავედი', 'Switched to another service');
  String get deleteReasonDissatisfied => _t('უკმაყოფილო ვარ სერვისით', 'Dissatisfied with the service');
  String get deleteReasonOther => _t('სხვა მიზეზი', 'Other reason');
  String get deleteDetailsHint => _t('დამატებითი კომენტარი (არასავალდებულო)', 'Additional comments (optional)');
  String get deleteConfirmCheckbox => _t('ვადასტურებ, რომ მინდა ჩემი ანგარიშისა და ყველა მონაცემის სამუდამოდ წაშლა', 'I confirm that I want to permanently delete my account and all data');
  String get deleteConfirmButton => _t('დიახ, წაშალე', 'Yes, Delete');
  String get deleteSubmitButton => _t('წაშლის მოთხოვნის გაგზავნა', 'Send Deletion Request');
  String get deleteSelectReason => _t('გთხოვთ აირჩიოთ მიზეზი', 'Please select a reason');
  String get deleteConfirmRequired => _t('გთხოვთ დაადასტუროთ წაშლა', 'Please confirm deletion');
  String get deleteFinalWarning => _t('ეს მოქმედება შეუქცევადია. ნამდვილად გსურთ ანგარიშის წაშლის მოთხოვნის გაგზავნა?', 'This action is irreversible. Are you sure you want to send an account deletion request?');
  String get deleteRequestSent => _t('წაშლის მოთხოვნა წარმატებით გაიგზავნა', 'Deletion request sent successfully');
  String get deleteRequestFailed => _t('მოთხოვნის გაგზავნა ვერ მოხერხდა', 'Failed to send request');
  String get language => _t('ენა', 'Language');
  String get themeLabel => _t('თემა', 'Theme');
  String get themeDark => _t('მუქი', 'Dark');
  String get themeLight => _t('ნათელი', 'Light');
  String get themeSystem => _t('სისტემური', 'System');

  // ─── Change Password Screen ───
  String get currentPassword => _t('მიმდინარე პაროლი', 'Current Password');
  String get enterCurrentPassword => _t('შეიყვანეთ მიმდინარე პაროლი', 'Enter current password');
  String get enterNewPasswordShort => _t('შეიყვანეთ ახალი პაროლი', 'Enter new password');
  String get repeatNewPassword => _t('გაიმეორეთ ახალი პაროლი', 'Repeat New Password');
  String get repeatPassword => _t('გაიმეორეთ პაროლი', 'Repeat password');
  String get passwordsNoMatch => _t('პაროლები არ ემთხვევა', 'Passwords don\'t match');
  String get passwordChangedOk => _t('პაროლი შეიცვალა', 'Password Changed');
  String get passwordChangeFailed => _t('პაროლის შეცვლა ვერ მოხერხდა', 'Password change failed');

  // ─── Change Phone Screen ───
  String get enterNewPhone => _t('შეიყვანეთ ახალი ტელეფონის ნომერი', 'Enter new phone number');
  String get newPhone => _t('ახალი ტელეფონი', 'New Phone');
  String get enter6digitCodeShort => _t('შეიყვანეთ 6 ციფრიანი კოდი', 'Enter 6-digit code');
  String get phoneChanged => _t('ტელეფონი შეიცვალა', 'Phone Changed');
  String get phoneChangeTitle => _t('ტელეფონის შეცვლა', 'Change Phone');

  // ─── Provider error messages ───
  String get loadResidentsFailed => _t('მცხოვრებლების ჩატვირთვა ვერ მოხერხდა', 'Failed to load residents');
  String get approveSuccess => _t('მოთხოვნა დადასტურებულია', 'Request approved');
  String get approveFailed => _t('დადასტურება ვერ მოხერხდა', 'Approval failed');
  String get rejectSuccess => _t('მოთხოვნა უარყოფილია', 'Request rejected');
  String get rejectFailed => _t('უარყოფა ვერ მოხერხდა', 'Rejection failed');
  String get removeSuccess => _t('მომხმარებელი წაიშალა', 'User removed');
  String get removeFailed => _t('წაშლა ვერ მოხერხდა', 'Removal failed');
  String get loadDashboardFailed => _t('მონაცემების ჩატვირთვა ვერ მოხერხდა', 'Failed to load data');
  String get loadDashboardFailedRetry =>
      _t('მონაცემების ჩატვირთვა ვერ მოხერხდა. სცადეთ მოგვიანებით.', 'Failed to load data. Try again later.');
  String get loadDoorsFailed => _t('კარების ჩატვირთვა ვერ მოხერხდა', 'Failed to load doors');
  String get loadDoorsFailedRetry =>
      _t('კარების ჩატვირთვა ვერ მოხერხდა. სცადეთ მოგვიანებით.', 'Failed to load doors. Try again later.');
  String get loadHistoryFailed => _t('ისტორიის ჩატვირთვა ვერ მოხერხდა', 'Failed to load history');
  String get processPaymentFailed => _t('გადახდის ინიცირება ვერ მოხერხდა', 'Failed to initiate payment');
  String get profileLoadFailed => _t('პროფილის ჩატვირთვა ვერ მოხერხდა', 'Failed to load profile');
  String get imageUpdateSuccess => _t('სურათი განახლებულია', 'Image updated');
  String get passwordChangeSuccess => _t('პაროლი წარმატებით შეიცვალა', 'Password changed successfully');
  String get connectionError => _t('კავშირის შეცდომა', 'Connection Error');
  String get connectionFailed => _t('კავშირი ვერ მოხერხდა. სცადეთ მოგვიანებით.', 'Connection failed. Try again later.');
  String get noInternet => _t('ინტერნეტ კავშირი არ არის.', 'No internet connection.');

  // ─── Notification channels ───
  String get notifChannelRequests => _t('მოთხოვნები', 'Requests');
  String get notifChannelRequestsDesc => _t('ბინაში რეგისტრაციის ახალი მოთხოვნები', 'New apartment registration requests');
  String get notifChannelPayments => _t('გადახდები', 'Payments');
  String get notifChannelPaymentsDesc => _t('გადახდის შეტყობინებები', 'Payment notifications');
  String get notifChannelGeneral => _t('ზოგადი', 'General');
  String get notifChannelGeneralDesc => _t('ზოგადი შეტყობინებები', 'General notifications');
  String notifNewRequest(String apt) => _t('ახალი მოთხოვნა ბინა $apt-ზე', 'New request for Apt $apt');
  String notifRequestBody(String name) => _t('$name ითხოვს ბინაში რეგისტრაციას', '$name requests apartment registration');
  String get notifPayment => _t('გადახდა', 'Payment');

  // ─── Notification history screen ───
  String get notifTitle => _t('შეტყობინებები', 'Notifications');
  String get notifEmpty => _t('შეტყობინებები არ არის', 'No notifications');
  String get notifMarkAllRead => _t('ყველას წაკითხულად მონიშვნა', 'Mark all as read');
  String get notifClearAll => _t('ყველას წაშლა', 'Clear all');
  String get notifClearConfirm => _t('ნამდვილად გსურთ ყველა შეტყობინების წაშლა?', 'Are you sure you want to clear all notifications?');
  String get notifJustNow => _t('ახლახანს', 'Just now');
  String notifMinsAgo(int n) => _t('$n წუთის წინ', '${n}m ago');
  String notifHoursAgo(int n) => _t('$n საათის წინ', '${n}h ago');
  String notifDaysAgo(int n) => _t('$n დღის წინ', '${n}d ago');

  // ─── Door/Payment Model Labels ───
  String get doorTypeElevator => _t('ლიფტი', 'Elevator');
  String get doorTypeDoor => _t('კარი', 'Door');
  String get statusPaid => _t('გადახდილი', 'Paid');
  String get statusBlocked => _t('დაბლოკილი', 'Blocked');
  String get statusUnpaid => _t('გადაუხდელი', 'Unpaid');
  String get statusAdminBlocked => _t('ადმინის მიერ დაბლოკილი', 'Blocked by Admin');
  String get paymentSuccessful => _t('წარმატებული', 'Successful');
  String get paymentProcessing => _t('მუშავდება', 'Processing');
  String get paymentFailedLabel => _t('წარუმატებელი', 'Failed');
  String get paymentTypeDebt => _t('დავალიანება', 'Debt');
  String get paymentTypeCurrent => _t('მიმდინარე', 'Current');
  String get paymentTypePrepaid => _t('წინასწარი', 'Prepaid');

  // ─── Messages ───
  String get navMessages => _t('შეტყობინებები', 'Messages');
  String get messagesTitle => _t('შეტყობინებები', 'Messages');
  String get messagesEmpty => _t('შეტყობინებები არ არის', 'No messages');
  String get messageReply => _t('პასუხი', 'Reply');
  String get messageSend => _t('გაგზავნა', 'Send');
  String get messageWriteReply => _t('დაწერეთ პასუხი...', 'Write a reply...');
  String get messageTicketClosed => _t('თემა დახურულია', 'Topic is closed');
  String get messageLoadFailed => _t('შეტყობინებების ჩატვირთვა ვერ მოხერხდა', 'Failed to load messages');
  String get messageSendFailed => _t('პასუხის გაგზავნა ვერ მოხერხდა', 'Failed to send reply');
  String get messageFromAdmin => _t('ადმინისტრაცია', 'Administration');
  String repliesCount(int n) => _t('$n პასუხი', '$n replies');
  String get messageDirectLabel => _t('პირდაპირი', 'Direct');
  String get messageComplexLabel => _t('კომპლექსის', 'Complex');
  String get messageAllLabel => _t('საერთო', 'General');
  String get unreadLabel => _t('ახალი', 'New');

  // ─── Polls ───
  String get navPolls => _t('გამოკითხვები', 'Polls');
  String get pollsTitle => _t('გამოკითხვები', 'Polls');
  String get pollsEmpty => _t('გამოკითხვები არ არის', 'No polls');
  String get pollActive => _t('აქტიური', 'Active');
  String get pollEnded => _t('დასრულებული', 'Ended');
  String get pollVote => _t('ხმის მიცემა', 'Vote');
  String get pollVoted => _t('ხმა მიცემულია', 'Voted');
  String get pollResults => _t('შედეგები', 'Results');
  String pollTotalVotes(int n) => _t('სულ $n ხმა', '$n total votes');
  String get pollVoteSuccess => _t('ხმა წარმატებით მიეცა', 'Vote cast successfully');
  String get pollVoteFailed => _t('ხმის მიცემა ვერ მოხერხდა', 'Failed to cast vote');
  String get pollAlreadyVoted => _t('უკვე ხმა მიგეცათ', 'Already voted');
  String get pollLoadFailed => _t('გამოკითხვების ჩატვირთვა ვერ მოხერხდა', 'Failed to load polls');
  String get pollNotStarted => _t('ჯერ არ დაწყებულა', 'Not started yet');
  String get pollExpired => _t('ვადა ამოიწურა', 'Expired');
  String pollVoters(int n) => _t('$n ამომრჩეველი', '$n voters');
}

/// InheritedWidget to inject strings into the widget tree.
class _LocaleInherited extends InheritedWidget {
  final AppStrings strings;

  const _LocaleInherited({
    required this.strings,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant _LocaleInherited old) =>
      old.strings._lang != strings._lang;
}

/// Wrap your MaterialApp in this to provide [AppStrings] down the tree.
class LocaleScope extends StatelessWidget {
  final LocaleProvider provider;
  final Widget child;

  const LocaleScope({super.key, required this.provider, required this.child});

  @override
  Widget build(BuildContext context) {
    return _LocaleInherited(
      strings: provider.s,
      child: child,
    );
  }
}
