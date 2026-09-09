import 'package:get/get.dart';
import 'package:plainscan/features/onboarding/screens/splash_screen.dart';
import 'package:plainscan/features/onboarding/screens/onboarding_screen.dart';
import 'package:plainscan/features/onboarding/screens/language_selection_screen.dart';
import 'package:plainscan/features/onboarding/screens/consent_permissions_screen.dart';
import 'package:plainscan/features/onboarding/screens/auth_screen.dart';
import 'package:plainscan/features/onboarding/screens/two_factor_screen.dart';
import 'package:plainscan/features/onboarding/screens/verify_email_screen.dart';
import 'package:plainscan/features/home/screens/home_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String language = '/language-setup';
  static const String permissions = '/permissions-setup';
  static const String auth = '/auth';
  static const String verify2Fa = '/verify-2fa';
  static const String verifyEmail = '/verify-email';
  static const String home = '/home';

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
      name: permissions,
      page: () => const ConsentPermissionsScreen(),
    ),
    GetPage(
      name: auth,
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
      name: home,
      page: () => const HomeScreen(),
    ),
  ];
}
