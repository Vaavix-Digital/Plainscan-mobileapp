class ApiConstants {
  static const String baseUrl = 'https://api.plainscan.com/api';

  // 🔐 Authentication
  static const String signUp = '/auth/signup';
  static const String verifyEmail = '/auth/verify-email';
  static const String resendVerification = '/auth/resend-verification';
  static const String login = '/auth/login';
  static const String verify2Fa = '/auth/verify-2fa';
  static const String googleLogin = '/auth/google';
  static const String refreshToken = '/auth/refresh-token';
  static const String profile = '/auth/me';
  static const String preferences = '/auth/me/preferences';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String logout = '/auth/logout';
  static const String inviteInfo = '/auth/invite-info';
  static const String acceptInvite = '/auth/accept-invite';

  // 📦 Plans
  static const String listPlans = '/plans';
  static const String currentPlan = '/plans/current';

  // 💳 Payments
  static const String createOrder = '/payments/create-order';
  static const String verifyPayment = '/payments/verify-payment';
  static const String verifyStripePayment = '/payments/verify-stripe-payment';
  static const String creditsPacks = '/payments/credits-packs';
  static const String createCreditOrder = '/payments/credits/create-order';
  static const String verifyCreditPayment = '/payments/credits/verify';
  static const String usdToInrRate = '/payments/usd-to-inr-rate';

  // 🔑 Google Sign-In Configuration
  // Required on Android to obtain the idToken for backend verification.
  // Replace with the actual Web Client ID from Google Cloud Console.
  static const String googleServerClientId = 'YOUR_GOOGLE_SIGN_IN_WEB_CLIENT_ID.apps.googleusercontent.com';

    static const String uploadFile =
      'files/upload';

  static String createJob(String toolSlug) =>
      'tools/$toolSlug/jobs';

  static String jobStatus(String jobId) =>
      'jobs/$jobId';

  static String downloadFile(String fileId) =>
      'files/$fileId/download';
}
