import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:if_avance/screens/signup_page.dart';

void main() {
  Widget createSignupPage() {
    return MaterialApp(
      home: SignupPage(),
    );
  }

  group('SignupPage Widget Tests', () {
    testWidgets('SignupPage muestra todos los campos', (WidgetTester tester) async {
      await tester.pumpWidget(createSignupPage());

      expect(find.text('Regístrate'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(4));
      expect(find.text('Registrar'), findsOneWidget);
    });

    testWidgets('Validación de nombre muestra error si está vacío', (WidgetTester tester) async {
      await tester.pumpWidget(createSignupPage());

      await tester.tap(find.text('Registrar'));
      await tester.pump();

      expect(find.text('Nombre requerido'), findsOneWidget);
    });

    testWidgets('Validación de teléfono muestra error si tiene menos de 9 dígitos', (WidgetTester tester) async {
      await tester.pumpWidget(createSignupPage());

      final phoneField = find.byType(TextFormField).at(2);
      await tester.enterText(phoneField, '12345678');
      await tester.tap(find.text('Registrar'));
      await tester.pump();

      expect(find.text('Teléfono inválido'), findsOneWidget);
    });

    testWidgets('Todos los campos tienen íconos apropiados', (WidgetTester tester) async {
      await tester.pumpWidget(createSignupPage());

      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.email), findsOneWidget);
      expect(find.byIcon(Icons.phone), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsOneWidget);
    });
  });
}