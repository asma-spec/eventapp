import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _loading = false;
  String? _errorMessage; // ← NOUVEAU : message d'erreur précis

  UserModel? get user => _user;
  bool get loading => _loading;
  bool get isLoggedIn => _user != null;
  bool get isOrganisateur => _user?.role == 'organisateur';
  bool get isAdmin => _user?.role == 'admin';
  String? get errorMessage => _errorMessage; // ← NOUVEAU

  Future<bool> inscription({
    required String email,
    required String password,
    required String nom,
    required String role,
  }) async {
    _loading = true;
    _errorMessage = null; // reset erreur
    notifyListeners();

    try {
      _user = await _authService.inscription(
        email: email,
        password: password,
        nom: nom,
        role: role,
      );
    } catch (e) {
      // ✅ Récupère le message précis depuis AuthService
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _user = null;
    }

    _loading = false;
    notifyListeners();
    return _user != null;
  }

  Future<bool> connexion({
    required String email,
    required String password,
  }) async {
    _loading = true;
    _errorMessage = null; // reset erreur
    notifyListeners();

    try {
      _user = await _authService.connexion(
        email: email,
        password: password,
      );
    } catch (e) {
      // ✅ Récupère le message précis depuis AuthService
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _user = null;
    }

    _loading = false;
    notifyListeners();
    return _user != null;
  }

  Future<void> deconnexion() async {
    await _authService.deconnexion();
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }

  // ✅ Réinitialiser le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
// Provider auth