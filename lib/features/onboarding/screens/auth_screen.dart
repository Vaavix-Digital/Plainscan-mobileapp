import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:plainscan/app/routes.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/controllers/auth_controller.dart';
import 'package:plainscan/core/services/auth_service.dart';
import 'package:plainscan/core/services/referral_service.dart';
import 'package:plainscan/core/services/storage_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();
  final AuthController authController = Get.put(AuthController());

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _captureReferralCodeFromUrlOrStorage();
  }

  void _captureReferralCodeFromUrlOrStorage() async {
    String? code = Get.parameters['ref'] ??
        Get.parameters['referral'] ??
        Get.parameters['referral_code'] ??
        Get.parameters['code'];

    if (code == null || code.trim().isEmpty) {
      code = await StorageService.captureReferral();
    }
    if (code == null || code.trim().isEmpty) {
      code = await StorageService.getPendingReferralCode();
    }

    if (code != null && code.trim().isNotEmpty) {
      final cleanCode = code.trim().toUpperCase();
      await StorageService.setPendingReferralCode(cleanCode);
      if (mounted) {
        setState(() {
          _referralController.text = cleanCode;
          _tabController.index = 1; // Focus Sign Up tab
        });
      }
    }
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _formKey.currentState?.reset();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();
    final isSignUp = _tabController.index == 1;
    final refCode = _referralController.text.trim();

    AuthResult result;

    if (isSignUp) {
      if (refCode.isNotEmpty) {
        await StorageService.setPendingReferralCode(refCode);
      }
      result = await AuthService.signUp(
        email: email,
        password: password,
        name: name,
        referralCode: refCode.isNotEmpty ? refCode : null,
      );
    } else {
      result = await AuthService.login(email: email, password: password);
    }

    setState(() {
      _isLoading = false;
    });

    if (result.success) {
      if (isSignUp) {
        final refCode = _referralController.text.trim();
        if (refCode.isNotEmpty) {
          await StorageService.setPendingReferralCode(refCode);
        }
      }

      if (isSignUp || result.requiresVerification) {
        Get.toNamed(AppRoutes.verifyEmail, arguments: email);
        if (result.message != null && result.message!.isNotEmpty) {
          Get.rawSnackbar(
            messageText: Text(
              result.message!,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: AppColors.primary,
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(12),
            borderRadius: 8,
          );
        }
      } else if (result.requires2Fa) {
        Get.toNamed(AppRoutes.verify2Fa, arguments: email);
      } else {
        final pendingCode = await StorageService.getPendingReferralCode();
        if (pendingCode != null && pendingCode.isNotEmpty) {
          await ReferralService.applyReferralCode(pendingCode);
          await StorageService.clearPendingReferralCode();
        }
        Get.offAllNamed(AppRoutes.home);
        Get.rawSnackbar(
          messageText: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Signed in successfully!'.tr,
                style: const TextStyle(
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
      }
    } else {
      Get.rawSnackbar(
        messageText: Text(
          result.errorMessage?.tr ?? 'Authentication failed'.tr,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              // App Logo & Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.document_scanner_outlined,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'PlainScan',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Welcome to PlainScan'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Scan, clean, and organize your files instantly'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 32),

              // Sign In / Sign Up tab toggles
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.border),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: AppColors.primary,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.secondaryText,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(text: 'Sign In'.tr),
                    Tab(text: 'Sign Up'.tr),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Form fields
              Form(
                key: _formKey,
                child: AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) {
                    final isSignUp = _tabController.index == 1;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isSignUp) ...[
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Full Name'.tr,
                              prefixIcon: const Icon(Icons.person_outline),
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.coral,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.coral,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your name'.tr;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address'.tr,
                            prefixIcon: const Icon(Icons.email_outlined),
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.coral,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.coral,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email'.tr;
                            }
                            final trimmed = value.trim();
                            final emailRegex = RegExp(
                              r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
                            );
                            if (!emailRegex.hasMatch(trimmed)) {
                              return 'Please enter a valid email address'.tr;
                            }
                            final parts = trimmed.split('@');
                            if (parts.length == 2 && parts[1].toLowerCase() == 'gmail.com') {
                              if (parts[0].length < 6) {
                                return 'Gmail addresses must be at least 6 characters before @'.tr;
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Password'.tr,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.secondaryText,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.coral,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.coral,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password'.tr;
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters'.tr;
                            }
                            return null;
                          },
                        ),
                        if (!isSignUp) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Get.toNamed(
                                  AppRoutes.forgotPassword,
                                  arguments: _emailController.text.trim(),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Forgot Password?'.tr,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (isSignUp) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _referralController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              labelText: 'Referral Code (Optional)'.tr,
                              hintText: 'e.g. PLAIN2026',
                              prefixIcon: const Icon(Icons.card_giftcard_rounded, color: AppColors.primary),
                              helperText: 'Have a friend\'s invite code? Enter it to get 50 bonus credits!'.tr,
                              helperStyle: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                               : Text(
                                  isSignUp ? 'Create Account'.tr : 'Sign In'.tr,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'OR'.tr,
                      style: const TextStyle(color: AppColors.secondaryText),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
              const SizedBox(height: 24),

              // Social OAuth Mimicry
          Obx(
  () => OutlinedButton.icon(
    onPressed: authController.isLoading.value
        ? null
        : authController.handleGoogleLogin,
        icon: const FaIcon(
          FontAwesomeIcons.google,
          size: 20,
          color: AppColors.amber,
        ),
   
    label: Text(
      authController.isLoading.value
          ? 'Signing in...'.tr
          : 'Continue with Google'.tr,
      style: const TextStyle(
        color: AppColors.text,
      ),
    ),

    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 12),
      side: const BorderSide(
        color: AppColors.border,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
),
              if (Platform.isIOS) ...[
                const SizedBox(height: 16),
                Obx(
                  () => OutlinedButton.icon(
                    onPressed: authController.isLoading.value
                        ? null
                        : authController.handleAppleLogin,
                    icon: const FaIcon(
                      FontAwesomeIcons.apple,
                      size: 20,
                      color: AppColors.text,
                    ),
                    label: Text(
                      authController.isLoading.value
                          ? 'Signing in...'.tr
                          : 'Continue with Apple'.tr,
                      style: const TextStyle(
                        color: AppColors.text,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(
                        color: AppColors.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
