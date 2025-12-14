import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:primeros_auxilios_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Flujo de administrador', () {
    testWidgets('Admin puede crear, editar y eliminar guías', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login como admin (asumiendo que existe un usuario admin)
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico'),
        'admin@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'admin123',
      );
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle(Duration(seconds: 5));

      // Verificar que el botón Admin es visible
      expect(find.text('Panel Admin'), findsOneWidget);

      // Navegar a AdminPanel
      await tester.tap(find.text('Panel Admin'));
      await tester.pumpAndSettle();

      expect(find.text('Panel de Administración'), findsOneWidget);

      // Crear nueva guía
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Título'),
        'Guía de Prueba',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Contenido'),
        '1. Paso uno\n2. Paso dos\n3. Paso tres',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Ruta de imagen'),
        'assets/images/test.png',
      );

      await tester.tap(find.text('Crear'));
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Verificar que la guía fue creada
      expect(find.text('Guía de Prueba'), findsOneWidget);
      expect(find.text('Guía creada exitosamente'), findsOneWidget);

      // Editar guía
      final editButton = find.byIcon(Icons.edit).first;
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      final titleField = find.widgetWithText(TextField, 'Título');
      await tester.enterText(titleField, 'Guía Editada');

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle(Duration(seconds: 3));

      expect(find.text('Guía Editada'), findsOneWidget);
      expect(find.text('Guía actualizada exitosamente'), findsOneWidget);

      // Eliminar guía
      final deleteButton = find.byIcon(Icons.delete).first;
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Confirmar eliminación
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle(Duration(seconds: 3));

      expect(find.text('Guía eliminada exitosamente'), findsOneWidget);
    });

    testWidgets('Usuario normal no puede acceder al panel admin', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login como usuario normal
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

      // Verificar que el botón Admin NO es visible
      expect(find.text('Panel Admin'), findsNothing);
    });
  });
}