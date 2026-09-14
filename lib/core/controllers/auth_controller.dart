import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:plainscan/app/routes.dart';
import 'package:plainscan/core/constants/api_constants.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/services/auth_service.dart';
import 'package:plainscan/core/services/referral_service.dart';
import 'package:plainscan/core/services/storage_service.dart';


class AuthController extends GetxController {
  final RxBool isLoading = false.obs;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<void>? _initFuture;

  @override
  void onInit() {
    super.onInit();
    _initFuture = _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      final serverClientId = ApiConstants.googleServerClientId.trim();
      await _googleSignIn.initialize(
        serverClientId: serverClientId.isNotEmpty ? serverClientId : null,
      );
    } catch (e) {
      debugPrint('Error initializing Google Sign-In: $e');
    }
  }

  Future<void> handleGoogleLogin() async {
    if (isLoading.value) return;

    final serverClientId = ApiConstants.googleServerClientId.trim();
    if (serverClientId.isEmpty || serverClientId.startsWith('YOUR_GOOGLE_SIGN_IN')) {
      _showError(
        'Google Sign-In is not configured yet. Please configure your Google Web Client ID in api_constants.dart.',
      );
      return;
    }

    isLoading.value = true;

    try {
      if (_initFuture != null) {
        await _initFuture;
      }

      // Reset any previous session so the Google account selector appears cleanly
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final GoogleSignInAccount googleUser =
          await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      final String? idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Google ID token was not received. Ensure googleServerClientId in api_constants.dart is your WEB Client ID (not Android Client ID).',
        );
      }

      final result = await AuthService.googleLogin(
        token: idToken,
      );

      if (result.success) {
        final pendingCode = await StorageService.getPendingReferralCode();
        if (pendingCode != null && pendingCode.isNotEmpty) {
          await ReferralService.applyReferralCode(pendingCode);
          await StorageService.clearPendingReferralCode();
        }
        Get.offAllNamed(AppRoutes.home);
        Get.rawSnackbar(
          messageText: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Signed in successfully!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.emerald,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
          borderRadius: 8,
          duration: const Duration(seconds: 3),
        );
      } else {
        _showError(
          result.errorMessage ??
              'Google authentication failed.',
        );
      }
    } on GoogleSignInException catch (e) {
      debugPrint('GoogleSignInException: ${e.code}, description: ${e.description}');

      // User closed or canceled sign-in sheet; do not show error
      if (e.code == GoogleSignInExceptionCode.canceled ||
          (e.description != null &&
              (e.description!.toLowerCase().contains('canceled') ||
                  e.description!.toLowerCase().contains('cancelled') ||
                  e.description!.contains('12501')))) {
        return;
      }

      String message = e.description ?? e.code.name;
      if (message.contains('28444') || message.contains('Developer console')) {
        message =
            'Google Cloud Console setup incomplete (Error 28444): \n1. Add SHA-1 to Firebase Console.\n2. Ensure googleServerClientId in api_constants.dart is a Web Client ID (not an Android Client ID).\n3. Check OAuth Consent Screen.';
      } else if (e.code == GoogleSignInExceptionCode.clientConfigurationError ||
          message.contains('serverClientId')) {
        message =
            'Google Sign-In configuration error: serverClientId is required. Verify your Google Web Client ID in api_constants.dart.';
      }
      _showError(
        'Google Sign-In failed: $message',
      );
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      _showError(
        'Google login failed: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _showError(String message) {
    Get.rawSnackbar(
      messageText: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: AppColors.coral,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      borderRadius: 8,
    );
  }
}