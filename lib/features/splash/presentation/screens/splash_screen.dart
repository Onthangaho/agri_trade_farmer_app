// lib/features/splash/presentation/screens/splash_screen.dart
/// Splash screen with Lottie farming animation, staggered text reveals, and auth routing.

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../routes/route_names.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future<void>.delayed(const Duration(milliseconds: 2800));
    if (!mounted) {
      return;
    }

    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;

    if (user != null) {
      Navigator.pushReplacementNamed(context, RouteNames.home);
    } else {
      Navigator.pushReplacementNamed(context, RouteNames.login);
    }
  }

  @override
  void dispose() => super.dispose();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreenDark,
      body: Stack(
        children: <Widget>[
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // ── Lottie animation (fadeIn at 0ms) ──
                  SizedBox(
                    width: 280,
                    height: 280,
                    child: Lottie.asset(
                      'assets/lottie/farming.json',
                      fit: BoxFit.contain,
                      repeat: true,
                      reverse: false,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 300.ms, delay: 0.ms),
                  const SizedBox(height: 32),

                  // ── App name (fadeIn + slideY at 400ms) ──
                  Text(
                    'AgriTrade',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                          fontSize: 36,
                        ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 400.ms)
                      .slideY(begin: 0.2, end: 0, duration: 500.ms, delay: 400.ms),

                  const SizedBox(height: 8),

                  // ── Tagline (fadeIn at 700ms) ──
                  Text(
                    'Connecting farmers to markets',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontFamily: 'Nunito Sans',
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 700.ms),

                  const SizedBox(height: 48),

                  // ── Loading indicator (fadeIn at 1000ms) ──
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.7),
                      ),
                      strokeWidth: 2,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 300.ms, delay: 1000.ms),
                ],
              ),
            ),
          ),

          // ── Powered by text at bottom (40% opacity) ──
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Powered by AgriTrade SA',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                  fontFamily: 'Nunito Sans',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
