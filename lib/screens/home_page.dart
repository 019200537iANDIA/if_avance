// Importaciones necesarias
import 'package:flutter/material.dart';       // Framework UI de Flutter
import '../services/auth_service.dart';       // Servicio de autenticación
import '../services/guide_service.dart';      // Servicio de gestión de guías
import '../models/guide.dart';                // Modelo de datos Guide
import 'guide_detail_page.dart';              // Pantalla de detalle de guía
import 'profile_page.dart';                   // Pantalla de perfil
import 'admin_panel.dart';                    // Panel de administración

/// Pantalla principal de la aplicación que muestra todas las guías disponibles
/// 
/// Esta es la primera pantalla que ven los usuarios después de iniciar sesión.
/// Muestra una lista de guías de primeros auxilios y proporciona navegación
/// a otras secciones importantes de la app.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// Estado de la página principal
/// 
/// Gestiona la verificación de permisos de administrador y
/// la visualización dinámica de las guías
class _HomePageState extends State<HomePage> {
  /// Servicio para operaciones de autenticación y gestión de usuarios
  final _authService = AuthService();
  
  /// Servicio para operaciones CRUD con las guías de primeros auxilios
  final _guideService = GuideService();
  
  /// Bandera que indica si el usuario actual tiene privilegios de administrador
  /// 
  /// Se inicializa en false y se actualiza al verificar los permisos
  /// Determina la visibilidad del botón de administración
  bool isAdmin = false;

  /// Método del ciclo de vida que se ejecuta al crear el estado
  /// 
  /// Se llama una sola vez cuando el widget se inserta en el árbol.
  /// Aquí iniciamos la verificación de permisos de administrador.
  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  /// Verifica si el usuario actual tiene permisos de administrador
  /// 
  /// Consulta el servicio de autenticación de forma asíncrona
  /// y actualiza el estado para reflejar los permisos del usuario.
  /// Esto controla la visibilidad del botón de administración.
  Future<void> _checkAdmin() async {
    final admin = await _authService.isAdmin();
    setState(() => isAdmin = admin);
  }

  /// Cierra la sesión del usuario y navega a la pantalla de login
  /// 
  /// Utiliza `pushReplacementNamed` en lugar de `push` para reemplazar
  /// toda la pila de navegación, evitando que el usuario pueda volver
  /// a la página principal usando el botón atrás después de cerrar sesión.
  Future<void> _logout() async {
    await _authService.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barra superior de la aplicación
      appBar: AppBar(
        title: const Text('Guías de Emergencia'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        
        /// Botones de acción en la barra superior
        /// 
        /// Se organizan de izquierda a derecha:
        /// 1. Panel de admin (solo visible para administradores)
        /// 2. Perfil de usuario
        /// 3. Cerrar sesión
        actions: [
          // Botón de administración (condicional)
          // Solo se muestra si isAdmin es true
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Panel Admin',
              onPressed: () {
                // Navega al panel de administración
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminPanel()),
                );
              },
            ),
          
          // Botón de perfil (siempre visible)
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Perfil',
            onPressed: () {
              // Navega a la página de perfil
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
          ),
          
          // Botón de cerrar sesión (siempre visible)
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
          ),
        ],
      ),
      
      /// Cuerpo principal con StreamBuilder para actualizaciones en tiempo real
      /// 
      /// El StreamBuilder escucha cambios en la colección de guías de Firebase
      /// y reconstruye automáticamente la interfaz cuando hay actualizaciones
      body: StreamBuilder<List<Guide>>(
        // Stream que proporciona la lista de guías en tiempo real
        stream: _guideService.getGuides(),
        
        builder: (context, snapshot) {
          /// Estado 1: Cargando datos
          /// Muestra un indicador de progreso circular mientras
          /// se establece la conexión y se cargan los datos
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          /// Estado 2: Error en la carga
          /// Muestra un mensaje descriptivo del error si algo falla
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          /// Estado 3: Sin datos o lista vacía
          /// Informa al usuario que no hay guías disponibles
          /// Útil para nuevas instalaciones o si se eliminaron todas las guías
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No hay guías disponibles'),
            );
          }

          /// Estado 4: Datos cargados exitosamente
          /// Extrae la lista de guías del snapshot
          final guides = snapshot.data!;

          /// Construye una lista desplazable de tarjetas con las guías
          return ListView.builder(
            // Espaciado alrededor de la lista
            padding: const EdgeInsets.all(8),
            // Número total de guías
            itemCount: guides.length,
            
            /// Constructor de cada tarjeta de guía
            itemBuilder: (context, i) {
              final guide = guides[i];
              
              /// Tarjeta Material Design para cada guía
              return Card(
                // Espaciado entre tarjetas
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                // Sombra para efecto de profundidad
                elevation: 3,
                
                /// ListTile: widget conveniente para listas con ícono/imagen,
                /// texto principal, subtexto y acción
                child: ListTile(
                  // Espaciado interno de la tarjeta
                  contentPadding: const EdgeInsets.all(12),
                  
                  /// Imagen miniatura a la izquierda
                  leading: ClipRRect(
                    // Bordes redondeados para la imagen
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      // Usa la ruta de la guía o logo por defecto
                      guide.imagePath.isNotEmpty 
                          ? guide.imagePath 
                          : 'assets/images/logo.png',
                      width: 60,
                      height: 60,
                      // Ajusta la imagen para llenar el espacio
                      fit: BoxFit.cover,
                      
                      /// Manejo de errores: muestra ícono si la imagen falla
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.medical_services,
                        size: 60,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  
                  /// Título de la guía en negrita
                  title: Text(
                    guide.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  
                  /// Vista previa del contenido (truncada)
                  /// 
                  /// Características:
                  /// - Trunca a 80 caracteres con "..."
                  /// - Máximo 2 líneas de texto
                  /// - Ellipsis al final si es muy largo
                  subtitle: Text(
                    guide.content.length > 80
                        ? '${guide.content.substring(0, 80)}...'
                        : guide.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  /// Ícono de flecha indicando que es clickeable
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  
                  /// Acción al tocar la tarjeta
                  /// Navega a la página de detalle pasando la guía completa
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GuideDetailPage(guide: guide),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}