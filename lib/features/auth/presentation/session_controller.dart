import 'package:flutter/foundation.dart';

import '../data/auth_repository.dart';
import '../domain/app_user.dart';

class SessionController extends ChangeNotifier {
  SessionController(this._repository);

  final AuthRepository _repository;
  AppUser? _user;
  bool _isRestored = false;

  AppUser? get currentUser => _user;
  bool get isSignedIn => _user != null;

  bool get isRestored => _isRestored;

  // Кирилл: сессия переживает перезапуск: id пользователя хранится в settings базы
  Future<void> restore() async {
    _user = await _repository.restoreSession();
    _isRestored = true;
    notifyListeners();
  }

  Future<AppUser> signIn(String login, String password) async {
    final user = await _repository.signIn(login, password);
    _user = user;
    notifyListeners();
    return user;
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _user = null;
    notifyListeners();
  }
}
