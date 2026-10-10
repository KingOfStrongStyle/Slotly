import 'package:flutter/foundation.dart';

import '../data/auth_repository.dart';
import '../domain/app_user.dart';

/// Who is signed in. The root of the app listens to it and shows the
/// customer or owner shell; repositories read [currentUser] for every
/// permission check.
class SessionController extends ChangeNotifier {
  SessionController(this._repository);

  final AuthRepository _repository;
  AppUser? _user;
  bool _isRestored = false;

  AppUser? get currentUser => _user;
  bool get isSignedIn => _user != null;

  /// False until [restore] finishes; the app shows a splash meanwhile.
  bool get isRestored => _isRestored;

  Future<void> restore() async {
    _user = await _repository.restoreSession();
    _isRestored = true;
    notifyListeners();
  }

  /// Throws [InvalidCredentialsException] for wrong credentials.
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
