// lib/features/auth/presentation/providers/auth_provider.dart
/// Complete authentication provider connected to Firebase Auth.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _initialize();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  bool _isLoading = false;
  String? _errorMessage;
  User? _firebaseUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _firebaseUser;
  bool get isAuthenticated => _firebaseUser != null;
  String get currentUserId => _firebaseUser?.uid ?? '';

  void _initialize() {
    // Set initial user from Firebase
    _firebaseUser = _auth.currentUser;

    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      _firebaseUser = user;
      notifyListeners();
    });
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _firebaseUser = credential.user;
      _logger.i('Sign in successful');
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseErrorToMessage(e.code);
      _logger.e('Sign in failed: ${e.code}');
      return false;
    } catch (e) {
      _errorMessage = 'Authentication failed. Please try again.';
      _logger.e('Sign in unexpected error');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name
      if (credential.user != null) {
        await credential.user!.updateDisplayName(name.trim());
        await credential.user!.reload();
        _firebaseUser = _auth.currentUser;
      }

      _logger.i('Registration successful');
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseErrorToMessage(e.code);
      _logger.e('Registration failed: ${e.code}');
      return false;
    } catch (e) {
      _errorMessage = 'Registration failed. Please try again.';
      _logger.e('Registration unexpected error');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendPasswordResetEmail({required String email}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      _logger.i('Password reset email sent');
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseErrorToMessage(e.code);
      _logger.e('Password reset failed: ${e.code}');
      return false;
    } catch (e) {
      _errorMessage = 'Failed to send reset email. Please try again.';
      _logger.e('Password reset unexpected error');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _firebaseUser = null;
      _errorMessage = null;
      _logger.i('Sign out successful');
      notifyListeners();
    } catch (e) {
      _logger.e('Sign out failed');
      rethrow;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _mapFirebaseErrorToMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Email or password is incorrect. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
