// lib/features/auth/presentation/screens/login_screen.dart
//login screen with Firebase authentication integration.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../routes/route_names.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final bool valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    context.read<AuthProvider>().clearError();

    final bool success = await context.read<AuthProvider>().signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.pushReplacementNamed(context, RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // Green gradient header with wave clipper
            Stack(
              children: <Widget>[
                ClipPath(
                  clipper: _HeaderWaveClipper(),
                  child: Container(
                    height: 320,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[Color(0xFF1B4332), Color(0xFF2D6A4F)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      children: <Widget>[
                        const SizedBox(height: 8),
                        Text(
                          'AgriTrade',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                            fontFamily: 'Poppins',
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: -0.2),
                        const SizedBox(height: 12),
                        const Text(
                          'Grow your farm. Reach more buyers.',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'NunitoSans',
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Icon(
                          Icons.agriculture,
                          color: Colors.white,
                          size: 80,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Form section on cream background
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    // Email field
                    Semantics(
                      label: 'Email address input field',
                      textField: true,
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          fontFamily: 'NunitoSans',
                          color: AppColors.backgroundCream,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Email',
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
                    // Password field
                    Semantics(
                      label: 'Password input field',
                      textField: true,
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(
                          fontFamily: 'NunitoSans',
                          color: AppColors.backgroundCream,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(
                            fontFamily: 'NunitoSans',
                            color: AppColors.mutedText,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: AppColors.primaryGreen,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.primaryGreen,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
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
                            return 'Password is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Forgot password link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, RouteNames.forgotPassword);
                        },
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontFamily: 'NunitoSans',
                            fontSize: 14,
                          ),
                        ),
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
                    // Sign In button
                    Consumer<AuthProvider>(
                      builder: (BuildContext context, AuthProvider authProvider, _) {
                        return Semantics(
                          button: true,
                          enabled: !authProvider.isLoading,
                          label: 'Sign in button',
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
                                  : const Icon(Icons.login, color: Colors.white),
                              label: Text(
                                authProvider.isLoading ? 'Signing in...' : 'Sign In',
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
                    const SizedBox(height: 16),
                    // Create Account button
                    Semantics(
                      button: true,
                      label: 'Create new account button',
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, RouteNames.register);
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: const BorderSide(
                              color: AppColors.primaryGreen,
                              width: 2,
                            ),
                          ),
                          icon: const Icon(
                            Icons.person_add_alt_1,
                            color: AppColors.primaryGreen,
                          ),
                          label: const Text(
                            'Create Account',
                            style: TextStyle(
                              color: AppColors.primaryGreen,
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path()..lineTo(0, size.height - 70);
    path.quadraticBezierTo(size.width * 0.25, size.height, size.width * 0.55, size.height - 40);
    path.quadraticBezierTo(size.width * 0.82, size.height - 80, size.width, size.height - 30);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
