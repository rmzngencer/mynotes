import 'package:mynotes/services/auth/auth_exception.dart';
import 'package:mynotes/services/auth/auth_provider.dart';
import 'package:mynotes/services/auth/auth_user.dart';
import 'package:test/test.dart';

void main() {
  group('Moch Authentication', () {
    final provider = MockAuthProvider();
    test('Should not be initiliazed to began with', () {
      expect(provider.isInitialized, false);
    });
    test('connot log out if not initilazer', () {
      expect(provider.logout(),
          throwsA(const TypeMatcher<NotInitilazeException>()));
    });
    test('should be able to be initiliazed', () async {
      await provider.initialize();
      expect(provider.isInitialized, true);
    });
    test('user should be null', () {
      expect(provider.currentUser, null);
    });
    test(
      'shoul be abel to inizilate in les 2 second',
      () async {
        await provider.initialize();
        expect(provider.isInitialized, true);
      },
      timeout: Timeout(const Duration(seconds: 2)),
    );
    test('creat user should delegete to logIn function', () async {
      final badEmailUser = provider.creatUser(
        email: 'foo@bar.com',
        password: 'anypassword',
      );
      expect(badEmailUser, throwsA(const TypeMatcher<UserNotFoundException>()));
      final badPaswordUSer = provider.creatUser(
        email: 'someone@bar.com',
        password: 'foobar',
      );
      expect(
          badPaswordUSer, throwsA(const TypeMatcher<WrongPasswordException>()));
      final user = await provider.creatUser(
        email: 'foo',
        password: 'bar',
      );
      expect(provider.currentUser, user);
      expect(user.isEmailVerified, false);
    });
    test('logged in user should be able to get verified', () {
      provider.sendEmailVerification();
      final user = provider.currentUser;
      expect(user, isNotNull);
      expect(user!.isEmailVerified, true);
    });
    test('should be able to log out and log in again', () async {
      await provider.logout();
      await provider.login(
        email: 'email',
        password: 'password',
      );
      final user = provider.currentUser;
      expect(user, isNotNull);
    });
  });
}

class NotInitilazeException implements Exception {}

class MockAuthProvider implements AuthProvider {
  AuthUser? _user;
  var _isInitialized = false;
  bool get isInitialized => _isInitialized;

  @override
  Future<AuthUser> creatUser({
    required String email,
    required String password,
  }) async {
    if (!isInitialized) {
      throw UnimplementedError();
    }
    await Future.delayed(const Duration(seconds: 1));
    return login(
      email: email,
      password: password,
    );
  }

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<void> initialize() async {
    await Future.delayed(const Duration(seconds: 1));
    _isInitialized = true;
  }

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) {
    if (!isInitialized) throw NotInitilazeException();
    if (email == 'foo@bar.com') throw UserNotFoundException();
    const user = AuthUser(isEmailVerified: false, email: 'foo@bar.com');
    _user = user;
    return Future.value(user);
  }

  @override
  Future<void> logout() async {
    if (!isInitialized) throw NotInitilazeException();
    if (_user == null) throw UserNotFoundException();
    await Future.delayed(const Duration(seconds: 1));
    _user = null;
  }

  @override
  Future<void> sendEmailVerification() async {
    if (!isInitialized) throw NotInitilazeException();
    final user = _user;
    if (user == null) throw UserNotFoundException();
    const mewUser = AuthUser(isEmailVerified: true, email: 'foo@bar.com');
    _user = mewUser;
  }
}
