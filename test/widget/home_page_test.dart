import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:if_avance/screens/home_page.dart';
import 'package:if_avance/services/guide_service.dart';
import 'package:if_avance/models/guide.dart';

class MockGuideService extends Mock implements GuideService {}

void main() {
  late MockGuideService mockGuideService;

  setUp(() {
    mockGuideService = MockGuideService();
  });

  Widget createHomePage() {
    return MaterialApp(
      home: HomePage(),
      routes: {
        '/profile': (context) => Scaffold(body: Text('Profile Page')),
        '/admin': (context) => Scaffold(body: Text('Admin Page')),
      },
    );
  }

  group('HomePage Widget Tests', () {
    testWidgets('HomePage muestra botones de navegación', (WidgetTester tester) async {
      await tester.pumpWidget(createHomePage());
      await tester.pump();

      expect(find.text('Mi Perfil'), findsOneWidget);
      expect(find.text('Cerrar Sesión'), findsOneWidget);
    });

    testWidgets('HomePage muestra CircularProgressIndicator mientras carga', (WidgetTester tester) async {
      when(mockGuideService.getGuides()).thenAnswer(
        (_) => Stream.value([]),
      );

      await tester.pumpWidget(createHomePage());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Botón perfil navega correctamente', (WidgetTester tester) async {
      await tester.pumpWidget(createHomePage());
      await tester.pumpAndSettle();

      final profileButton = find.text('Mi Perfil');
      await tester.tap(profileButton);
      await tester.pumpAndSettle();

      expect(find.text('Profile Page'), findsOneWidget);
    });
  });
}