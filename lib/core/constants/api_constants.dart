class ApiConstants {
  static const String baseUrl = 'https://api.plainscan.com/api';

  // 🔐 Authentication
  static const String signUp = '/auth/signup';
  static const String verifyEmail = '/auth/verify-email';
  static const String resendVerification = '/auth/resend-verification';
  static const String login = '/auth/login';
  static const String verify2Fa = '/auth/verify-2fa';
  static const String googleLogin = '/auth/google';
  static const String appleLogin = '/auth/apple';
  static const String authSession = '/auth/session';
  static const String meReferral = '/auth/me/referral';
  static const String refreshToken = '/auth/refresh-token';
  static const String profile = '/auth/me';
  static const String preferences = '/auth/me/preferences';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String logout = '/auth/logout';
  static const String deleteAccount = '/auth/delete-account';
  static const String inviteInfo = '/auth/invite-info';
  static const String acceptInvite = '/auth/accept-invite';

  // 📦 Plans
  static const String listPlans = '/plans';
  static const String currentPlan = '/plans/current';

  // 💳 Payments
  static const String createOrder = '/payments/create-order';
  static const String verifyPayment = '/payments/verify-payment';
  static const String verifyStripePayment = '/payments/verify-stripe-payment';
  static const String verifyApplePayment = '/payments/verify-apple';
  static const String verifyGooglePlayPayment = '/payments/verify-google-play';
  static const String creditsPacks = '/payments/credits-packs';
  static const String createCreditOrder = '/payments/credits/create-order';
  static const String verifyCreditPayment = '/payments/credits/verify';
  static const String usdToInrRate = '/payments/usd-to-inr-rate';

  // 🎁 Referrals
  static const String myReferralCode = '/referral/my-code';
  static const String applyReferral = '/referral/apply';
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.plainscan.app&hl=en';
  static const String appStoreUrl = 'https://apps.apple.com/app/id6813783856';

  // 📲 Push Notifications
  static const String registerPushToken = '/push/register';
  static const String removePushToken = '/push/token';
  static const String pushStatus = '/push/status';
  static const String togglePush = '/push/toggle';

  // 🔑 Google Sign-In Configuration
 
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '690500109578-aj7b3h7fctv2sed7c8jnl8i3ljg6n7go.apps.googleusercontent.com',
  );


    static const String uploadFile =
      'files/upload';

  static String createJob(String toolSlug) =>
      'tools/$toolSlug/jobs';

  static String jobStatus(String jobId) =>
      'jobs/$jobId';

  static String downloadFile(String fileId) =>
      'files/$fileId/download';
}
