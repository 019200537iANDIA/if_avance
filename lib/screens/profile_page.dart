// Importaciones necesarias
import 'package:flutter/material.dart';   // Framework UI de Flutter
import '../services/auth_service.dart';   // Servicio de autenticación y datos de usuario

/// Pantalla de perfil del usuario
/// 
/// Muestra la información personal del usuario autenticado y
/// proporciona opciones para gestionar la cuenta como cerrar sesión.
/// Carga datos tanto de Firebase Auth como de Firestore.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

/// Estado de la página de perfil
/// 
/// Gestiona la carga de datos del usuario y la actualización de la UI
class _ProfilePageState extends State<ProfilePage> {
  /// Servicio para operaciones de autenticación y acceso a datos de usuario
  final _authService = AuthService();
  
  /// Datos adicionales del usuario almacenados en Firestore
  /// 
  /// Incluye información como:
  /// - name: Nombre completo del usuario
  /// - phone: Número de teléfono
  /// - isAdmin: Bandera de permisos de administrador
  /// 
  /// Es nullable porque puede no existir durante la carga inicial
  Map<String, dynamic>? userData;
  
  /// Bandera que indica si los datos están siendo cargados
  /// 
  /// Controla la visualización del indicador de progreso
  /// Se inicializa en true porque comenzamos cargando datos
  bool loading = true;

  /// Método del ciclo de vida ejecutado al crear el estado
  /// 
  /// Inicia la carga de datos del usuario desde Firebase
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Carga los datos adicionales del usuario desde Firestore
  /// 
  /// Proceso:
  /// 1. Consulta el servicio de autenticación por los datos del usuario
  /// 2. Actualiza el estado con los datos recibidos
  /// 3. Cambia la bandera loading a false para mostrar la UI
  /// 
  /// Los datos incluyen información que no está en Firebase Auth
  /// como el teléfono, nombre personalizado, y permisos de admin
  Future<void> _loadUserData() async {
    final data = await _authService.getUserData();
    setState(() {
      userData = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    /// Obtiene el usuario actual de Firebase Auth
    /// 
    /// Este objeto contiene información básica como:
    /// - email: Correo electrónico
    /// - displayName: Nombre de Google (si usó Google Sign-In)
    /// - photoURL: URL de foto de perfil (si usó Google Sign-In)
    final user = _authService.currentUser;

    return Scaffold(
      // Barra superior de la aplicación
      appBar: AppBar(
        title: const Text('Perfil de Usuario'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      
      /// Cuerpo condicional basado en el estado de carga
      /// 
      /// Muestra diferentes vistas según:
      /// 1. Si está cargando datos
      /// 2. Si no hay usuario autenticado
      /// 3. Si todo está correcto (vista normal del perfil)
      body: loading
          // Estado 1: Cargando datos
          ? const Center(child: CircularProgressIndicator())
          : user == null
              // Estado 2: No hay usuario (caso raro, pero manejado)
              ? const Center(child: Text('No hay usuario activo'))
              // Estado 3: Usuario válido, mostrar perfil completo
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      /// Avatar circular del usuario
                      /// 
                      /// Comportamiento inteligente:
                      /// - Si tiene photoURL (Google Sign-In): muestra la foto
                      /// - Si no tiene foto: muestra ícono de persona genérico
                      /// 
                      /// El radio de 60 crea un avatar prominente y visible
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.green,
                        // Solo establece backgroundImage si existe photoURL
                        backgroundImage: user.photoURL != null
                            ? NetworkImage(user.photoURL!)
                            : null,
                        // Solo muestra el ícono si NO hay foto
                        child: user.photoURL == null
                            ? const Icon(
                                Icons.person, 
                                size: 60, 
                                color: Colors.white
                              )
                            : null,
                      ),
                      
                      const SizedBox(height: 20),

                      /// Nombre del usuario con sistema de fallback triple
                      /// 
                      /// Prioridad de datos:
                      /// 1. userData['name']: Nombre de Firestore (más personalizado)
                      /// 2. user.displayName: Nombre de Google Sign-In
                      /// 3. 'Usuario': Fallback por defecto
                      /// 
                      /// Este sistema asegura que siempre haya un nombre visible
                      Text(
                        userData?['name'] ?? user.displayName ?? 'Usuario',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      
                      const SizedBox(height: 30),

                      /// Tarjeta de correo electrónico
                      /// 
                      /// El email siempre debería existir en Firebase Auth
                      /// pero usamos fallback por seguridad
                      _buildInfoCard(
                        icon: Icons.email,
                        title: 'Correo electrónico',
                        value: user.email ?? 'No disponible',
                      ),
                      
                      const SizedBox(height: 15),

                      /// Tarjeta de teléfono
                      /// 
                      /// El teléfono es opcional y solo existe si el usuario
                      /// se registró con email/contraseña y lo proporcionó
                      _buildInfoCard(
                        icon: Icons.phone,
                        title: 'Teléfono',
                        value: userData?['phone'] ?? 'No registrado',
                      ),
                      
                      const SizedBox(height: 15),

                      /// Tarjeta de tipo de usuario
                      /// 
                      /// Verifica explícitamente si isAdmin es true
                      /// Cualquier otro valor (false, null, ausente) = Usuario regular
                      _buildInfoCard(
                        icon: Icons.admin_panel_settings,
                        title: 'Tipo de usuario',
                        value: userData?['isAdmin'] == true 
                            ? 'Administrador' 
                            : 'Usuario',
                      ),
                      
                      const SizedBox(height: 30),

                      /// Botón de cerrar sesión
                      /// 
                      /// Características:
                      /// - Color rojo para indicar acción importante/destructiva
                      /// - Ancho completo para fácil acceso
                      /// - Ícono de logout para claridad visual
                      /// - Usa pushReplacementNamed para limpiar navegación
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            // Cierra la sesión en Firebase
                            await _authService.signOut();
                            
                            /// Navega al login reemplazando toda la pila
                            /// 
                            /// Esto es crucial para seguridad:
                            /// - El usuario no puede volver atrás
                            /// - Se limpia toda la información de sesión
                            /// - Se resetea completamente la navegación
                            Navigator.pushReplacementNamed(context, '/');
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Cerrar Sesión'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  /// Widget reutilizable para tarjetas de información
  /// 
  /// Crea una tarjeta Material Design consistente que muestra:
  /// - Un ícono temático a la izquierda
  /// - Un título descriptivo pequeño en gris
  /// - El valor real en texto más grande y negro
  /// 
  /// Este patrón de diseño es común en pantallas de perfil y
  /// configuración, proporcionando una estructura visual clara.
  /// 
  /// Parámetros:
  /// - [icon]: IconData del ícono a mostrar
  /// - [title]: Etiqueta descriptiva del campo
  /// - [value]: Valor actual del campo
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// _buildInfoCard(
  ///   icon: Icons.email,
  ///   title: 'Email',
  ///   value: 'usuario@ejemplo.com'
  /// )
  /// ```
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      // Sombra sutil para efecto de profundidad
      elevation: 2,
      child: ListTile(
        // Ícono verde a la izquierda
        leading: Icon(icon, color: Colors.green),
        
        // Título pequeño en gris (label del campo)
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        
        // Valor del campo en negro y más grande (dato principal)
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}