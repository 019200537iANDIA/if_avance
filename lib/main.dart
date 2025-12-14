// Importaciones necesarias para el funcionamiento de la aplicación
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'dart:async';

// Importaciones de pantallas
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'screens/home_page.dart';
import 'screens/profile_page.dart';
import 'screens/admin_panel.dart';

// Importación de servicios
import 'services/guide_service.dart';

/// Función principal de la aplicación - Punto de entrada
/// 
/// Configura Firebase, Crashlytics, Analytics y carga las guías predeterminadas
/// antes de iniciar la aplicación.
void main() async {
  // Asegura que los enlaces de widgets estén inicializados
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Inicializa Firebase
    await Firebase.initializeApp();
    
    // Configurar Crashlytics para capturar errores de Flutter
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    
    // Capturar errores asíncronos no manejados
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    
    // Carga las guías de primeros auxilios predeterminadas
    await GuideService().initializeDefaultGuides();
    
  } catch (e, stackTrace) {
    // Registrar error de inicialización
    debugPrint('Error en inicialización: $e');
    FirebaseCrashlytics.instance.recordError(e, stackTrace);
  }
  
  // Ejecuta la aplicación
  runApp(const PrimerosAuxiliosApp());
}

/// Widget raíz de la aplicación de Primeros Auxilios
/// 
/// Configura:
/// - Tema visual con Material Design
/// - Sistema de navegación por rutas
/// - Firebase Analytics para seguimiento de navegación
/// - Todas las páginas disponibles
class PrimerosAuxiliosApp extends StatelessWidget {
  /// Constructor constante para optimización de rendimiento
  const PrimerosAuxiliosApp({super.key});
  
  /// Instancia de Firebase Analytics para métricas
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  
  /// Observer para rastrear navegación entre pantallas
  static FirebaseAnalyticsObserver observer = 
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Oculta el banner "DEBUG" en la esquina superior derecha
      debugShowCheckedModeBanner: false,
      
      // Título de la aplicación
      title: 'Primeros Auxilios',
      
      // Configuración del tema visual
      // Verde representa salud, seguridad y urgencia médica
      theme: ThemeData(
        primarySwatch: Colors.green,
        // Configuración adicional de tema
        appBarTheme: const AppBarTheme(
          elevation: 2,
          centerTitle: true,
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        // Configuración de botones elevados
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      
      // Observer de Analytics para rastrear navegación
      navigatorObservers: [observer],
      
      // Ruta inicial: Pantalla de login
      initialRoute: '/',
      
      // Definición de todas las rutas de navegación
      routes: {
        '/': (_) => const LoginPage(),
        '/signup': (_) => const SignupPage(),
        '/home': (_) => const HomePage(),
        '/profile': (_) => const ProfilePage(),
        '/admin': (_) => const AdminPanel(),
      },
      
      // Manejo de rutas desconocidas
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Página no encontrada',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(_, '/'),
                    child: const Text('Volver al inicio'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}