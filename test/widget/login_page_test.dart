import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:primeros_auxilios_app/pages/login_page.dart';
import 'package:primeros_auxilios_app/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
  });

  Widget createLoginPage() {
    return MaterialApp(
      home: LoginPage(),
      routes: {
        '/signup': (context) => Scaffold(body: Text('Signup Page')),
        '/home': (context) => Scaffold(body: Text('Home Page')),
      },
    );
  }

  group('LoginPage Widget Tests', () {
    testWidgets('LoginPage muestra todos los elementos', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginPage());

      expect(find.text('Bienvenido'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('Continuar con Google'), findsOneWidget);
      expect(find.text('¿No tienes cuenta? Regístrate'), findsOneWidget);
    });

    testWidgets('Validación de email muestra error si no contiene @', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginPage());

      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'invalid-email');
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump();

      expect(find.text('Email inválido'), findsOneWidget);
    });

    testWidgets('Validación de password muestra error si tiene menos de 6 caracteres', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginPage());

      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, '12345');
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump();

      expect(find.text('Mínimo 6 caracteres'), findsOneWidget);
    });

    testWidgets('Campo password oculta texto', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginPage());

      final passwordField = tester.widget<TextFormField>(find.byType(TextFormField).last);
      expect(passwordField.obscureText, isTrue);
    });

    testWidgets('Botón Google Sign-In es presionable', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginPage());

      final googleButton = find.text('Continuar con Google');
      expect(googleButton, findsOneWidget);

      await tester.tap(googleButton);
      await tester.pump();
    });

    testWidgets('Link a signup navega correctamente', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginPage());

      final signupLink = find.text('¿No tienes cuenta? Regístrate');
      await tester.tap(signupLink);
      await tester.pumpAndSettle();

      expect(find.text('Signup Page'), findsOneWidget);
    });
  });
}