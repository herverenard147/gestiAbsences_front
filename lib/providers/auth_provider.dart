import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _loading = false;
  String? _error;

  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> checkSession() async {
    _user = await ApiService.getUser();
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiService.login(username, password);
      if (res['success'] == true) {
        await ApiService.saveSession(res['token'], res['user']);
        _user = res['user'];
        _loading = false;
        notifyListeners();
        return true;
      } else {
        _error = res['message'] ?? 'Erreur de connexion';
        _loading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Impossible de joindre le serveur';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await ApiService.logout();
    _user = null;
    notifyListeners();
  }
}
