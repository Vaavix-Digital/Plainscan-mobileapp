import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:plainscan/app/routes.dart';
import 'package:plainscan/core/constants/api_constants.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/services/auth_service.dart';
import 'package:plainscan/core/services/storage_service.dart';


class AuthController extends GetxController {
  final RxBool isLoading = false.obs;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  static bool _isGoogleSignInInitialized = false;
  static Future<void>? _initFuture;

  @override
  void onInit() {
    super.onInit();
    _ensureInitialized();
  }

  Future<void> _ensureInitialized() async {
    if (_isGoogleSignInInitialized) return;
    _initFuture ??= _initializeGoogleSignIn();
    await _initFuture;
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      final serverClientId = ApiConstants.googleServerClientId.trim();
      await _googleSignIn.initialize(
        serverClientId: serverClientId.isNotEmpty ? serverClientId : null,
      );
      _isGoogleSignInInitialized = true;
    } catch (e) {
      debugPrint('Error initializing Google Sign-In: $e');
      _initFuture = null; // allow retry
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
      await _ensureInitialized();

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

      final pendingCode = await StorageService.getPendingReferralCode();
      final result = await AuthService.googleLogin(
        token: idToken,
        referralCode: pendingCode,
      );

      if (result.success) {
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
      debugPrint('GoogleSignInException: ${e.code}, description: ${e.description}, details: ${e.details}');

      final String rawDesc = e.description ?? '';
      final String lowerDesc = rawDesc.toLowerCase();

      // 1. Check for configuration errors FIRST.
      // On Android Credential Manager, config errors (SHA-1 mismatch, unconfigured OAuth consent)
      // are returned as GetCredentialCancellationException, which maps to code 'canceled'.
      if (rawDesc.contains('28444') ||
          lowerDesc.contains('developer console') ||
          lowerDesc.contains('developer_error') ||
          rawDesc.contains('10:') ||
          lowerDesc.contains('12500')) {
        _showError(
          'Google Cloud setup incomplete (Error 28444/10):\n'
          '1. Add SHA-1 to Firebase Console.\n'
          '2. Ensure OAuth Consent Screen is published/configured in Google Cloud Console.\n'
          '3. Ensure Web Client ID in api_constants.dart is correct.',
        );
        return;
      }

      if (e.code == GoogleSignInExceptionCode.clientConfigurationError ||
          lowerDesc.contains('serverclientid') ||
          lowerDesc.contains('missing server client id')) {
        _showError(
          'Google Sign-In configuration error: serverClientId is required. Verify your Google Web Client ID in api_constants.dart.',
        );
        return;
      }

      // 2. User closed or canceled sign-in sheet without an underlying error
      if (e.code == GoogleSignInExceptionCode.canceled ||
          lowerDesc.contains('canceled') ||
          lowerDesc.contains('cancelled') ||
          lowerDesc.contains('12501')) {
        debugPrint('Google sign-in canceled by user.');
        return;
      }

      _showError(
        'Google Sign-In failed: ${e.description ?? e.code.name}',
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