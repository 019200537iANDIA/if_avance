// Importaciones de Firebase y Google Sign-In
import 'package:firebase_auth/firebase_auth.dart';       // Autenticación de Firebase
import 'package:google_sign_in/google_sign_in.dart';     // Google OAuth 2.0
import 'package:cloud_firestore/cloud_firestore.dart';   // Base de datos NoSQL

/// Servicio centralizado de autenticación y gestión de usuarios
/// 
/// Esta clase maneja toda la lógica relacionada con:
/// - Registro de nuevos usuarios
/// - Inicio de sesión (email/password y Google)
/// - Cierre de sesión
/// - Verificación de permisos de administrador
/// - Obtención de datos de usuario
/// 
/// Integra tres servicios de Firebase:
/// 1. Firebase Auth: Autenticación y gestión de sesiones
/// 2. Google Sign-In: Autenticación OAuth con Google
/// 3. Cloud Firestore: Almacenamiento de datos adicionales de usuario
/// 
/// IMPORTANTE: Usa inyección de dependencias para facilitar testing
class AuthService {
  /// Instancia de Firebase Authentication
  /// 
  /// Gestiona las cuentas de usuario, sesiones y tokens de autenticación.
  /// Maneja tanto email/password como proveedores externos (Google).
  final FirebaseAuth _auth;
  
  /// Instancia de Google Sign-In
  /// 
  /// Implementa el flujo OAuth 2.0 de Google.
  /// Permite iniciar sesión con cuentas de Google existentes.
  final GoogleSignIn _googleSignIn;
  
  /// Instancia de Cloud Firestore
  /// 
  /// Base de datos NoSQL donde almacenamos datos adicionales de usuario
  /// que Firebase Auth no gestiona (nombre, teléfono, rol de admin, etc.)
  final FirebaseFirestore _firestore;

  /// Constructor con inyección de dependencias
  /// 
  /// Permite pasar instancias personalizadas para testing (mocks).
  /// Si no se proporcionan parámetros, usa las instancias por defecto.
  /// 
  /// Parámetros opcionales:
  /// - [auth]: Instancia de FirebaseAuth (default: FirebaseAuth.instance)
  /// - [firestore]: Instancia de Firestore (default: FirebaseFirestore.instance)
  /// - [googleSignIn]: Instancia de GoogleSignIn (default: GoogleSignIn())
  /// 
  /// Ejemplo para producción:
  /// ```dart
  /// final authService = AuthService(); // Usa instancias por defecto
  /// ```
  /// 
  /// Ejemplo para testing:
  /// ```dart
  /// final authService = AuthService(
  ///   auth: mockAuth,
  ///   firestore: fakeFirestore,
  /// );
  /// ```
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  /// Obtiene el usuario actualmente autenticado
  /// 
  /// Retorna:
  /// - [User]: Si hay un usuario autenticado
  /// - [null]: Si no hay sesión activa
  /// 
  /// Este getter es útil para verificar rápidamente
  /// si el usuario está autenticado y obtener su información básica
  User? get currentUser => _auth.currentUser;

  /// Stream que emite cambios en el estado de autenticación
  /// 
  /// Este Stream es fundamental para:
  /// - Detectar cuando un usuario inicia sesión
  /// - Detectar cuando un usuario cierra sesión
  /// - Actualizar la UI automáticamente según el estado de auth
  /// 
  /// Retorna un Stream que emite:
  /// - [User]: Cuando hay un usuario autenticado
  /// - [null]: Cuando no hay sesión activa
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// authService.authStateChanges.listen((user) {
  ///   if (user == null) {
  ///     // Navegar al login
  ///   } else {
  ///     // Navegar al home
  ///   }
  /// });
  /// ```
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Registra un nuevo usuario con email y contraseña
  /// 
  /// Este método realiza dos operaciones críticas:
  /// 1. Crea la cuenta en Firebase Auth (autenticación)
  /// 2. Guarda datos adicionales en Firestore (perfil)
  /// 
  /// Parámetros:
  /// - [email]: Correo electrónico del usuario (debe ser válido y único)
  /// - [password]: Contraseña (Firebase requiere mínimo 6 caracteres)
  /// - [name]: Nombre completo del usuario
  /// - [phone]: Número de teléfono del usuario
  /// 
  /// Retorna:
  /// - [User]: Si el registro fue exitoso
  /// - [null]: Si hubo algún error (email en uso, conexión, etc.)
  /// 
  /// Proceso:
  /// 1. Crea cuenta en Firebase Auth
  /// 2. Obtiene el UID generado automáticamente
  /// 3. Crea documento en Firestore con ese UID
  /// 4. Almacena datos adicionales del perfil
  Future<User?> signUpWithEmail(
    String email, 
    String password, 
    String name, 
    String phone
  ) async {
    try {
      /// Crea la cuenta en Firebase Authentication
      /// 
      /// Firebase automáticamente:
      /// - Valida el formato del email
      /// - Encripta la contraseña
      /// - Genera un UID único
      /// - Crea el usuario en la base de datos de Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      
      /// Guarda datos adicionales en Firestore
      /// 
      /// Firebase Auth solo almacena email y password.
      /// Usamos Firestore para datos adicionales del perfil.
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,                              // Nombre completo
          'email': email,                            // Email (duplicado para queries)
          'phone': phone,                            // Teléfono de contacto
          'isAdmin': false,                          // Nuevo usuario = no admin
          'createdAt': FieldValue.serverTimestamp(), // Timestamp del servidor
        });
      }
      
      return user;
    } catch (e) {
      /// Manejo de errores
      /// 
      /// Errores comunes:
      /// - email-already-in-use: El email ya está registrado
      /// - invalid-email: Formato de email inválido
      /// - weak-password: Contraseña muy débil (< 6 caracteres)
      /// - network-request-failed: Sin conexión a internet
      print('Error en registro: $e');
      return null;
    }
  }

  /// Inicia sesión con email y contraseña
  /// 
  /// Verifica las credenciales contra Firebase Auth.
  /// No consulta Firestore porque la autenticación es
  /// manejada completamente por Firebase Auth.
  /// 
  /// Parámetros:
  /// - [email]: Correo electrónico del usuario
  /// - [password]: Contraseña del usuario
  /// 
  /// Retorna:
  /// - [User]: Si las credenciales son correctas
  /// - [null]: Si las credenciales son incorrectas o hay un error
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      /// Intenta autenticar con las credenciales proporcionadas
      /// 
      /// Firebase Auth:
      /// - Verifica el email existe
      /// - Compara la contraseña encriptada
      /// - Crea un token de sesión si es correcto
      /// - Retorna los datos del usuario
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      /// Manejo de errores
      /// 
      /// Errores comunes:
      /// - user-not-found: No existe cuenta con ese email
      /// - wrong-password: Contraseña incorrecta
      /// - user-disabled: Cuenta deshabilitada
      /// - too-many-requests: Demasiados intentos fallidos
      print('Error en login: $e');
      return null;
    }
  }

  /// Inicia sesión usando Google Sign-In (OAuth 2.0)
  /// 
  /// Implementa el flujo completo de autenticación con Google:
  /// 1. Abre el diálogo de selección de cuenta de Google
  /// 2. Usuario autoriza la aplicación
  /// 3. Obtiene tokens de acceso de Google
  /// 4. Intercambia tokens por credenciales de Firebase
  /// 5. Autentica en Firebase con esas credenciales
  /// 6. Crea perfil en Firestore si es primera vez
  /// 
  /// Retorna:
  /// - [User]: Si el login fue exitoso
  /// - [null]: Si el usuario canceló o hubo error
  Future<User?> signInWithGoogle() async {
    try {
      /// Paso 1: Inicia el flujo de Google Sign-In
      /// 
      /// Abre un diálogo donde el usuario:
      /// - Selecciona su cuenta de Google
      /// - Autoriza los permisos solicitados
      /// 
      /// Retorna null si el usuario cancela el diálogo
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Usuario canceló

      /// Paso 2: Obtiene tokens de autenticación de Google
      /// 
      /// Incluye:
      /// - accessToken: Token de acceso a APIs de Google
      /// - idToken: Token de identidad del usuario
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;
      
      /// Paso 3: Crea credenciales de Firebase usando tokens de Google
      /// 
      /// Convierte los tokens de Google en un formato
      /// que Firebase Auth puede entender y verificar
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      /// Paso 4: Autentica en Firebase con las credenciales de Google
      /// 
      /// Firebase verifica los tokens con Google y
      /// crea o actualiza la cuenta del usuario
      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      /// Paso 5: Crea perfil en Firestore si es primera vez
      /// 
      /// Google Sign-In no proporciona teléfono ni permite
      /// marcar como admin, así que creamos el documento con
      /// valores por defecto si no existe.
      if (user != null) {
        // Verifica si el documento del usuario ya existe
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        
        // Si no existe, crea el documento con datos de Google
        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'name': user.displayName ?? 'Usuario',    // Nombre de Google
            'email': user.email,                      // Email de Google
            'phone': '',                              // Sin teléfono
            'isAdmin': false,                         // No es admin
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return user;
    } catch (e) {
      /// Manejo de errores
      /// 
      /// Errores comunes:
      /// - account-exists-with-different-credential: 
      ///   El email ya está asociado con otro método de login
      /// - network-request-failed: Sin conexión
      /// - user-cancelled: Usuario cerró el diálogo
      print('Error en Google Sign In: $e');
      return null;
    }
  }

  /// Cierra la sesión del usuario actual
  /// 
  /// IMPORTANTE: Debe cerrar sesión en ambos servicios:
  /// - Google Sign-In: Para limpiar la sesión de Google
  /// - Firebase Auth: Para limpiar la sesión de Firebase
  /// 
  /// Si solo cerramos en Firebase Auth, el usuario seguiría
  /// autenticado en Google y podría reconectarse automáticamente.
  Future<void> signOut() async {
    // Cierra sesión en Google (si se usó Google Sign-In)
    await _googleSignIn.signOut();
    // Cierra sesión en Firebase Auth (siempre necesario)
    await _auth.signOut();
  }

  /// Verifica si el usuario actual tiene permisos de administrador
  /// 
  /// Consulta el campo 'isAdmin' en el documento de Firestore
  /// del usuario. Este campo se establece manualmente en la
  /// base de datos para otorgar permisos de administrador.
  /// 
  /// Retorna:
  /// - [true]: Si el usuario es administrador
  /// - [false]: Si no es admin o no hay usuario autenticado
  /// 
  /// Uso típico:
  /// ```dart
  /// if (await authService.isAdmin()) {
  ///   // Mostrar botón de panel de admin
  /// }
  /// ```
  Future<bool> isAdmin() async {
    // Si no hay usuario autenticado, no puede ser admin
    if (currentUser == null) return false;
    
    try {
      // Consulta el documento del usuario en Firestore
      final doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      
      // Extrae el campo isAdmin o retorna false si no existe
      return doc.data()?['isAdmin'] ?? false;
    } catch (e) {
      print('Error verificando admin: $e');
      return false;
    }
  }

  /// Obtiene todos los datos del perfil del usuario actual
  /// 
  /// Recupera el documento completo de Firestore que contiene:
  /// - name: Nombre completo
  /// - email: Correo electrónico
  /// - phone: Número de teléfono
  /// - isAdmin: Bandera de administrador
  /// - createdAt: Fecha de creación de cuenta
  /// 
  /// Retorna:
  /// - [Map<String, dynamic>]: Datos del usuario
  /// - [null]: Si no hay usuario autenticado
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// final data = await authService.getUserData();
  /// String nombre = data?['name'] ?? 'Usuario';
  /// ```
  Future<Map<String, dynamic>?> getUserData() async {
    // Si no hay usuario autenticado, no hay datos
    if (currentUser == null) return null;
    
    try {
      // Obtiene el documento del usuario
      final doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      
      // Retorna los datos como mapa o null si no existe
      return doc.data();
    } catch (e) {
      print('Error obteniendo datos de usuario: $e');
      return null;
    }
  }
}