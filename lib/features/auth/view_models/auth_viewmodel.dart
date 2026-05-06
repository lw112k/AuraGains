import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();

  // --- State Variables ---
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _currentUser;

  // --- Getters ---
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // --- Private Helpers ---

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // --- Core Methods ---
  /// Restores session on app startup
  Future<bool> restoreSession() async {
    // 1. App is booting up! Turn on the global loading screen
    _isLoading = true;
    notifyListeners();

    final session = _authRepo.currentSession;

    if (session != null) {
      _currentUser = await _authRepo.getUserProfile(session.user.id);
    }

    // 2. We finished checking. Turn off the global loading screen
    _isLoading = false;
    notifyListeners();

    return _currentUser != null;
  }

  /// Login Logic
  Future<bool> login({required String email, required String password}) async {
    // andle loading locally on the Login button!
    _setError(null);

    try {
      final response = await _authRepo.signIn(email, password);

      if (response.user != null) {
        // Fetch the role/username after successful login
        _currentUser = await _authRepo.getUserProfile(response.user!.id);

        // notifyListeners() so AuthWrapper knows to send us to UserHome!
        notifyListeners();

        return true;
      }
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError("An unexpected error occurred.");
    }

    return false;
  }

  /// Registration Logic
  Future<bool> register({
    required String email,
    required String password,
    required String username,
  }) async {
    _setError(null);

    try {
      _currentUser = await _authRepo.registerUser(
        email: email,
        password: password,
        username: username,
      );

      notifyListeners(); // Main.dart will automatically route them to UserHome!
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError(e.toString());
    }

    return false;
  }

  /// Logout Logic
  Future<void> logout() async {
    await _authRepo.signOut();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners(); // Forces the AuthWrapper back to the Login View
  }
}
