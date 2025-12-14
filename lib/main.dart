// Importaciones necesarias para el funcionamiento de la aplicación
import 'package:flutter/material.dart';           // Framework de UI de Flutter
import 'package:firebase_core/firebase_core.dart'; // Inicialización de Firebase
import 'screens/login_page.dart';                  // Pantalla de inicio de sesión
import 'screens/signup_page.dart';                 // Pantalla de registro
import 'screens/home_page.dart';                   // Pantalla principal
import 'screens/profile_page.dart';                // Pantalla de perfil de usuario
import 'screens/admin_panel.dart';                 // Panel de administración
import 'services/guide_service.dart';              // Servicio para gestionar guías de primeros auxilios

/// Función principal de la aplicación - Punto de entrada
/// Esta función se ejecuta al iniciar la aplicación y configura
/// todos los servicios necesarios antes de mostrar la interfaz
void main() async {
  // Asegura que los enlaces de widgets estén inicializados antes de usar
  // funcionalidades asíncronas o plugins nativos
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa Firebase para permitir autenticación y base de datos
  await Firebase.initializeApp();
  
  // Carga las guías de primeros auxilios predeterminadas en la base de datos
  // Esto asegura que la app tenga contenido básico disponible desde el inicio
  await GuideService().initializeDefaultGuides();
  
  // Ejecuta la aplicación principal
  runApp(const FirstAidApp());
}

/// Widget raíz de la aplicación de Primeros Auxilios
/// 
/// Esta clase configura la estructura general de la aplicación incluyendo:
/// - El tema visual
/// - El sistema de navegación por rutas
/// - Las páginas disponibles
class FirstAidApp extends StatelessWidget {
  /// Constructor constante para optimización de rendimiento
  const FirstAidApp({super.key});

  /// Construye el widget raíz de la aplicación
  /// 
  /// Retorna un [MaterialApp] que implementa Material Design y
  /// configura todas las rutas de navegación de la aplicación
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Oculta el banner "DEBUG" en la esquina superior derecha
      debugShowCheckedModeBanner: false,
      
      // Título de la aplicación (aparece en el administrador de tareas)
      title: 'First Aid App',
      
      // Configuración del tema visual de la aplicación
      // El color verde representa salud, seguridad y urgencia médica
      theme: ThemeData(primarySwatch: Colors.green),
      
      // Ruta inicial que se muestra al abrir la aplicación
      // En este caso, la pantalla de login
      initialRoute: '/',
      
      // Definición de todas las rutas disponibles en la aplicación
      // Cada ruta mapea un nombre a un widget específico
      routes: {
        // Ruta raíz: Pantalla de inicio de sesión
        '/': (_) => const LoginPage(),
        
        // Ruta de registro: Permite crear nuevas cuentas de usuario
        '/signup': (_) => const SignupPage(),
        
        // Ruta principal: Pantalla con las guías de primeros auxilios
        '/home': (_) => const HomePage(),
        
        // Ruta de perfil: Muestra y permite editar información del usuario
        '/profile': (_) => const ProfilePage(),
        
        // Ruta de administración: Panel para gestionar contenido de la app
        // Solo accesible para usuarios con permisos de administrador
        '/admin': (_) => const AdminPanel(),
      },
    );
  }
}