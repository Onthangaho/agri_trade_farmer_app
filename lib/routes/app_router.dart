// lib/routes/app_router.dart
/// Route generation with auth guard and shared-axis transitions.

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/crops/presentation/screens/add_crop_screen.dart';
import '../features/farms/presentation/screens/my_farm_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../shared/screens/main_shell_screen.dart';
import '../shared/screens/placeholder_screen.dart';
import 'route_names.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return _routeForSettings(settings);
  }

  static Route<dynamic> _routeForSettings(RouteSettings settings) {
    final String routeName = settings.name ?? RouteNames.login;
    final Route<dynamic> route = _buildRoute(routeName, settings);
    return route;
  }

  static Route<dynamic> _buildRoute(String routeName, RouteSettings settings) {
    if (_isProtectedRoute(routeName)) {
      return _guardedRoute(routeName, settings);
    }

    if (routeName == RouteNames.splash) {
      return _fadeRoute(const SplashScreen(), settings);
    }

    return _sharedAxisRoute(_buildScreen(routeName), settings);
  }

  static Route<dynamic> _guardedRoute(String routeName, RouteSettings settings) {
    return _sharedAxisRoute(
      Builder(
        builder: (BuildContext context) {
          final bool isAuthenticated = context.read<AuthProvider>().isAuthenticated;
          if (!isAuthenticated) {
            return const LoginScreen();
          }
          return _buildScreen(routeName);
        },
      ),
      settings,
    );
  }

  static bool _isProtectedRoute(String routeName) {
    return routeName == RouteNames.home ||
        routeName == RouteNames.addCrop ||
        routeName == RouteNames.cropDetail ||
        routeName == RouteNames.addFarm ||
        routeName == RouteNames.editProfile ||
        routeName == RouteNames.settings ||
        routeName == RouteNames.messages;
  }

  static Widget _buildScreen(String routeName) {
    switch (routeName) {
      case RouteNames.login:
        return const LoginScreen();
      case RouteNames.register:
        return const RegisterScreen();
      case RouteNames.forgotPassword:
        return const ForgotPasswordScreen();
      case RouteNames.home:
        return const MainShellScreen();
      case RouteNames.addCrop:
        return const AddCropScreen();
      case RouteNames.cropDetail:
        return const AppPlaceholderScreen(
          title: 'Crop Detail',
          message: 'Crop detail content will be added with the crop feature.',
        );
      case RouteNames.addFarm:
        return const MyFarmScreen();
      case RouteNames.editProfile:
        return const ProfileScreen();
      case RouteNames.settings:
        return const AppPlaceholderScreen(
          title: 'Settings',
          message: 'App settings will be added after the base foundation.',
        );
      case RouteNames.messages:
        return const AppPlaceholderScreen(
          title: 'Messages',
          message: 'Buyer and farmer messaging will be added later.',
        );
      case RouteNames.splash:
      default:
        return const SplashScreen();
    }
  }

  static PageRouteBuilder<dynamic> _sharedAxisRoute(Widget child, RouteSettings settings) {
    return PageRouteBuilder<dynamic>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
        return child;
      },
      transitionsBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          child: child,
        );
      },
    );
  }

  static PageRouteBuilder<dynamic> _fadeRoute(Widget child, RouteSettings settings) {
    return PageRouteBuilder<dynamic>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
        return child;
      },
      transitionsBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}
