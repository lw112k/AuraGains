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
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // --- Core Methods ---
  /// Restores session on app startup
  Future<bool> restoreSession() async {
    final session = _authRepo.currentSession;

    if (session != null) {
      _currentUser = await _authRepo.getUserProfile(session.user.id);
      notifyListeners();
      return _currentUser != null;
    }
    return false;
  }

  /// Login Logic
  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authRepo.signIn(email, password);

      if (response.user != null) {
        // Fetch the role/username after successful login
        _currentUser = await _authRepo.getUserProfile(response.user!.id);
        _setLoading(false);
        return true; // Main.dart will automatically route them now!
      }
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError("An unexpected error occurred.");
    }

    _setLoading(false);
    return false;
  }

  /// Registration Logic 
  Future<bool> register({
    required String email,
    required String password,
    required String username,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      _currentUser = await _authRepo.registerUser(
        email: email,
        password: password,
        username: username,
      );

      _setLoading(false);
      notifyListeners(); // Main.dart will automatically route them to UserHome!
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError(e.toString());
    }

    _setLoading(false);
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
