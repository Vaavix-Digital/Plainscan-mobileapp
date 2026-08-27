import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:plainscan/app/routes.dart';
import 'package:plainscan/core/constants/api_constants.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/services/auth_service.dart';


class AuthController extends GetxController {
  final RxBool isLoading = false.obs;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  @override
  void onInit() {
    super.onInit();

    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    await _googleSignIn.initialize(
      serverClientId: ApiConstants.googleServerClientId,
    );
  }

  Future<void> handleGoogleLogin() async {
    if (isLoading.value) return;

    isLoading.value = true;

    try {
      final GoogleSignInAccount googleUser =
          await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      final String? idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Google ID token was not received.',
        );
      }

      final result = await AuthService.googleLogin(
        token: idToken,
      );

      if (result.success) {
        Get.offNamed(AppRoutes.home);
      } else {
        _showError(
          result.errorMessage ??
              'Google authentication failed.',
        );
      }
    } on GoogleSignInException catch (e) {
      _showError(
        'Google Sign-In failed: ${e.description ?? e.code.name}',
      );
    } catch (e) {
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