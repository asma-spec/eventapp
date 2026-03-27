import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _loading = false;

  UserModel? get user => _user;
  bool get loading => _loading;
  bool get isLoggedIn => _user != null;
  bool get isOrganisateur => _user?.role == 'organisateur';
  bool get isAdmin => _user?.role == 'admin'; // ✅ AJOUT

  Future<bool> inscription({
    required String email,
    required String password,
    required String nom,
    required String role,
  }) async {
    _loading = true;
    notifyListeners();
    _user = await _authService.inscription(
      email: email,
      password: password,
      nom: nom,
      role: role,
    );
    _loading = false;
    notifyListeners();
    return _user != null;
  }

  Future<bool> connexion({
    required String email,
    required String password,
  }) async {
    _loading = true;
    notifyListeners();
    _user = await _authService.connexion(
      email: email,
      password: password,
    );
    _loading = false;
    notifyListeners();
    return _user != null;
  }

  Future<void> deconnexion() async {
    await _authService.deconnexion();
    _user = null;
    notifyListeners();
  }
}// Provider auth
