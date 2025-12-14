import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:primeros_auxilios_app/services/auth_service.dart';

@GenerateMocks([User])
void main() {
  late AuthService authService;
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    fakeFirestore = FakeFirebaseFirestore();
    authService = AuthService();
  });

  group('AuthService Tests', () {
    test('signUpWithEmail crea usuario correctamente', () async {
      final mockUser = MockUser(
        isAnonymous: false,
        uid: 'test-uid-123',
        email: 'test@example.com',
        displayName: 'Test User',
      );

      when(mockAuth.createUserWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => MockUserCredential(mockUser));

      final result = await authService.signUpWithEmail(
        'test@example.com',
        'password123',
        'Test User',
        '987654321',
      );

      expect(result, isNotNull);
      expect(result?.email, 'test@example.com');
    });

    test('signInWithEmail retorna usuario con credenciales válidas', () async {
      final mockUser = MockUser(
        isAnonymous: false,
        uid: 'test-uid-456',
        email: 'user@example.com',
        displayName: 'User',
      );

      when(mockAuth.signInWithEmailAndPassword(
        email: 'user@example.com',
        password: 'password123',
      )).thenAnswer((_) async => MockUserCredential(mockUser));

      final result = await authService.signInWithEmail(
        'user@example.com',
        'password123',
      );

      expect(result, isNotNull);
      expect(result?.uid, 'test-uid-456');
    });

    test('signInWithEmail retorna null con credenciales inválidas', () async {
      when(mockAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(FirebaseAuthException(code: 'user-not-found'));

      final result = await authService.signInWithEmail(
        'wrong@example.com',
        'wrongpassword',
      );

      expect(result, isNull);
    });

    test('isAdmin retorna true para usuario administrador', () async {
      await fakeFirestore.collection('users').doc('admin-uid').set({
        'name': 'Admin User',
        'email': 'admin@example.com',
        'phone': '123456789',
        'isAdmin': true,
      });

      final mockUser = MockUser(
        isAnonymous: false,
        uid: 'admin-uid',
        email: 'admin@example.com',
      );

      when(mockAuth.currentUser).thenReturn(mockUser);

      final result = await authService.isAdmin();

      expect(result, isTrue);
    });

    test('isAdmin retorna false para usuario normal', () async {
      await fakeFirestore.collection('users').doc('user-uid').set({
        'name': 'Normal User',
        'email': 'user@example.com',
        'phone': '123456789',
        'isAdmin': false,
      });

      final mockUser = MockUser(
        isAnonymous: false,
        uid: 'user-uid',
        email: 'user@example.com',
      );

      when(mockAuth.currentUser).thenReturn(mockUser);

      final result = await authService.isAdmin();

      expect(result, isFalse);
    });
  });
}