import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/repositories/auth_repository.dart';
import '../models/user.dart';

enum AuthStatus { checking, signedOut, signedIn }

/// App-wide login state. The app shows a loading screen while [status] is
/// [AuthStatus.checking], then the login page or the recipes.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required this._authRepository}) {
    unawaited(_restoreSession());
  }

  static const int minUsernameLength = 3;
  static const int minPasswordLength = 6;

  final AuthRepository _authRepository;

  AuthStatus _status = AuthStatus.checking;
  User? _user;
  bool _isRegistering = false;
  bool _isBusy = false;
  bool _isDisposed = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get user => _user;

  /// True on the "Create account" form, false on "Log in".
  bool get isRegistering => _isRegistering;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;

  String? validateUsername(String? value) {
    return (value ?? '').trim().length < minUsernameLength
        ? 'Use at least $minUsernameLength characters'
        : null;
  }

  String? validatePassword(String? value) {
    final password = value ?? '';
    // Only new passwords get the length rule; logging in just needs one.
    if (!_isRegistering) {
      return password.isEmpty ? 'Enter your password' : null;
    }
    return password.length < minPasswordLength
        ? 'Use at least $minPasswordLength characters'
        : null;
  }

  void toggleMode() {
    _isRegistering = !_isRegistering;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> submit(String username, String password) async {
    if (_isBusy) return;
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = _isRegistering
          ? await _authRepository.register(username, password)
          : await _authRepository.login(username, password);
      _status = AuthStatus.signedIn;
    } on AuthException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _user = null;
    _isRegistering = false;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }

  Future<void> _restoreSession() async {
    try {
      _user = await _authRepository.restoreSession();
    } catch (_) {
      _user = null;
    }
    if (_isDisposed) return;
    _status = _user == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
