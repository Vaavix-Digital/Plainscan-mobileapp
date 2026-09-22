import 'package:get/get.dart';
import 'package:plainscan/features/onboarding/screens/splash_screen.dart';
import 'package:plainscan/features/onboarding/screens/onboarding_screen.dart';
import 'package:plainscan/features/onboarding/screens/language_selection_screen.dart';
import 'package:plainscan/features/onboarding/screens/auth_screen.dart';
import 'package:plainscan/features/onboarding/screens/two_factor_screen.dart';
import 'package:plainscan/features/onboarding/screens/verify_email_screen.dart';
import 'package:plainscan/features/onboarding/screens/forgot_password_screen.dart';
import 'package:plainscan/features/onboarding/screens/reset_password_screen.dart';
import 'package:plainscan/features/home/screens/home_screen.dart';
import 'package:plainscan/features/profile/pages/plans_page.dart';
import 'package:plainscan/features/profile/pages/referral_share_screen.dart';
import 'package:plainscan/features/profile/pages/payment_page.dart';
import 'package:plainscan/features/alltools/all_tools.dart';
import 'package:plainscan/features/files/pages/files_page.dart';
import 'package:plainscan/features/profile/pages/subscription_success_page.dart';
import 'package:plainscan/features/search/screens/search_screen.dart';
import 'package:plainscan/features/profile/pages/privacy_policy_page.dart';
import 'package:plainscan/features/profile/pages/terms_of_service_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String language = '/language-setup';
  static const String auth = '/auth';
  static const String login = '/login';
  static const String verify2Fa = '/verify-2fa';
  static const String verifyEmail = '/verify-email';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String home = '/home';
  static const String search = '/search';
  static const String tools = '/tools';
  static const String files = '/files';
  static const String referral = '/referral-share';
  static const String plans = '/plans';
  static const String payment = '/payment';
  static const String paymentSuccess = '/payment-success';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfService = '/terms-of-service';

  static final List<GetPage> pages = [
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: onboarding,
      page: () => const OnboardingScreen(),
    ),
    GetPage(
      name: language,
      page: () => const LanguageSelectionScreen(),
    ),
    GetPage(
      name: auth,
      page: () => const AuthScreen(),
    ),
    GetPage(
      name: login,
      page: () => const AuthScreen(),
    ),
    GetPage(
      name: verify2Fa,
      page: () {
        final email = Get.arguments as String? ?? '';
        return TwoFactorScreen(email: email);
      },
    ),
    GetPage(
      name: verifyEmail,
      page: () {
        final email = Get.arguments as String? ?? '';
        return VerifyEmailScreen(email: email);
      },
    ),
    GetPage(
      name: forgotPassword,
      page: () {
        final email = Get.arguments as String? ?? '';
        return ForgotPasswordScreen(initialEmail: email);
      },
    ),
    GetPage(
      name: resetPassword,
      page: () {
        final args = Get.arguments;
        String token = '';
        if (args is String) {
          token = args;
        } else if (args is Map) {
          token = args['token']?.toString() ?? '';
        }
        if (token.isEmpty && Get.parameters['token'] != null) {
          token = Get.parameters['token']!;
        }
        return ResetPasswordScreen(token: token);
      },
    ),
    GetPage(
      name: home,
      page: () => const HomeScreen(),
    ),
    GetPage(
      name: search,
      page: () => const SearchScreen(),
    ),
    GetPage(
      name: tools,
      page: () => AllTools(),
    ),
    GetPage(
      name: files,
      page: () => const FilesPage(),
    ),
    GetPage(
      name: referral,
      page: () => const ReferralShareScreen(),
    ),
    GetPage(
      name: plans,
      page: () => const PlansPage(),
    ),
    GetPage(
      name: payment,
      page: () => const PaymentPage(),
    ),
    GetPage(
      name: paymentSuccess,
      page: () => const SubscriptionSuccessPage(),
    ),
    GetPage(
      name: privacyPolicy,
      page: () => const PrivacyPolicyPage(),
    ),
    GetPage(
      name: termsOfService,
      page: () => const TermsOfServicePage(),
    ),
  ];
}
