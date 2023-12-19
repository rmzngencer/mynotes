import 'package:mynotes/services/auth/auth_provider.dart';
import 'package:mynotes/services/auth/auth_user.dart';

class AuthService implements AuthProvider {
  final AuthProvider provider;

  AuthService({required this.provider});

  @override
  Future<AuthUser> creatUser({
    required String email,
    required String password,
  }) {
    return provider.creatUser(email: email, password: password);
  }

  @override
  AuthUser? get currentUser => provider.currentUser;
  

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) {
    return provider.login(email: email, password: password);
  }

  @override
  Future<void> logout() {
   return provider.logout();
  }

  @override
  Future<void> sendEmailVerification() {
   return provider.sendEmailVerification();
  }
}
