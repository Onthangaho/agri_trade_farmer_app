// lib/features/auth/presentation/screens/forgot_password_screen.dart
// forgot password screen with email reset and success state.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../routes/route_names.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final bool valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    context.read<AuthProvider>().clearError();

    final bool success = await context.read<AuthProvider>().sendPasswordResetEmail(
          email: _emailController.text.trim(),
        );

    if (!mounted) {
      return;
    }

    if (success) {
      setState(() {
        _emailSent = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        title: const Text(
          'Reset Password',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _emailSent ? _buildSuccessState(context) : _buildFormState(context),
    );
  }

  Widget _buildFormState(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 32),
            // Lock icon in green circle
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_reset_outlined,
                color: AppColors.primaryGreen,
                size: 40,
              ),
            ),
            const SizedBox(height: 32),
            // Heading
            const Text(
              'Forgot your password?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.navyText,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Explanation text
            const Text(
              'Enter your email address and we will send you a link to reset your password.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.mutedText,
                fontFamily: 'NunitoSans',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Email form
            Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  Semantics(
                    label: 'Email address input field',
                    textField: true,
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                        fontFamily: 'NunitoSans',
                        color: AppColors.navyText,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        labelStyle: const TextStyle(
                          fontFamily: 'NunitoSans',
                          color: AppColors.mutedText,
                        ),
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: AppColors.primaryGreen,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.mutedText,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.primaryGreen,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (String? value) {
                        final String text = (value ?? '').trim();
                        if (text.isEmpty) {
                          return 'Email is required';
                        }
                        if (!text.contains('@') || !text.contains('.')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Error message display
                  Consumer<AuthProvider>(
                    builder: (BuildContext context, AuthProvider authProvider, _) {
                      if (authProvider.errorMessage != null) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.errorTerracotta.withValues(alpha: 0.1),
                            border: Border.all(
                              color: AppColors.errorTerracotta,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.errorTerracotta,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  authProvider.errorMessage!,
                                  style: const TextStyle(
                                    color: AppColors.errorTerracotta,
                                    fontFamily: 'NunitoSans',
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 24),
                  // Send Reset Link button
                  Consumer<AuthProvider>(
                    builder: (BuildContext context, AuthProvider authProvider, _) {
                      return Semantics(
                        button: true,
                        enabled: !authProvider.isLoading,
                        label: 'Send reset link button',
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: authProvider.isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              disabledBackgroundColor: AppColors.primaryGreen.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: authProvider.isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.mail_outline, color: Colors.white),
                            label: Text(
                              authProvider.isLoading ? 'Sending...' : 'Send Reset Link',
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Back to Sign In link
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Back to Sign In',
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontFamily: 'NunitoSans',
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 40),
            // Animated success icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                color: AppColors.primaryGreen,
                size: 52,
              ),
            )
                .animate()
                  .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 400.ms, curve: Curves.elasticOut)
                .fadeIn(),
            const SizedBox(height: 32),
            // Success heading
            const Text(
              'Check your email',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.navyText,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Email confirmation
            Text(
              'We sent a password reset link to:\n${_emailController.text}',
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.mutedText,
                fontFamily: 'NunitoSans',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Explanation
            const Text(
              'Open your email app and tap the link to reset your password. If you don\'t see the email, check your spam folder.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.mutedText,
                fontFamily: 'NunitoSans',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // Back to Sign In button
            Semantics(
              button: true,
              label: 'Back to sign in button',
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, RouteNames.login);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: const Text(
                    'Back to Sign In',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Try different email
            TextButton(
              onPressed: () {
                setState(() {
                  _emailSent = false;
                  _emailController.clear();
                });
                context.read<AuthProvider>().clearError();
              },
              child: const Text(
                'Try a different email',
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontFamily: 'NunitoSans',
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
