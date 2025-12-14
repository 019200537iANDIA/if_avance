import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:primeros_auxilios_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Flujo completo de la aplicación', () {
    testWidgets('Flujo de registro e inicio de sesión', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verificar que estamos en LoginPage
      expect(find.text('Bienvenido'), findsOneWidget);

      // Navegar a SignupPage
      await tester.tap(find.text('¿No tienes cuenta? Regístrate'));
      await tester.pumpAndSettle();

      // Verificar que estamos en SignupPage
      expect(find.text('Regístrate'), findsOneWidget);

      // Llenar formulario de registro
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre completo'),
        'Test User',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico'),
        'testuser@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Teléfono'),
        '987654321',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'password123',
      );

      // Enviar formulario
      await tester.tap(find.text('Registrar'));
      await tester.pumpAndSettle(Duration(seconds: 5));

      // Verificar que regresamos a LoginPage
      expect(find.text('Bienvenido'), findsOneWidget);

      // Iniciar sesión con credenciales creadas
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico'),
        'testuser@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'password123',
      );

      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle(Duration(seconds: 5));

      // Verificar que estamos en HomePage
      expect(find.text('Guías de Primeros Auxilios'), findsOneWidget);
    });

    testWidgets('Navegación entre pantallas principales', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login previo (asumiendo usuario ya existe)
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico'),
        'testuser@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'password123',
      );
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle(Duration(seconds: 5));

      // Navegar a ProfilePage
      await tester.tap(find.text('Mi Perfil'));
      await tester.pumpAndSettle();

      expect(find.text('Mi Perfil'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);

      // Regresar a HomePage
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Guías de Primeros Auxilios'), findsOneWidget);
    });

    testWidgets('Visualización de guía detallada', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico'),
        'testuser@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'password123',
      );
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle(Duration(seconds: 5));

      // Esperar a que carguen las guías
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Hacer tap en la primera guía
      final firstGuide = find.byType(Card).first;
      await tester.tap(firstGuide);
      await tester.pumpAndSettle();

      // Verificar que estamos en GuideDetailPage
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('1.'), findsOneWidget); // Contenido con pasos
    });
  });
}