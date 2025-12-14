// Importaciones necesarias
import 'package:flutter/material.dart';   // Framework UI de Flutter
import '../services/auth_service.dart';   // Servicio de autenticación y registro

/// Pantalla de registro para crear nuevas cuentas de usuario
/// 
/// Permite a los usuarios nuevos registrarse proporcionando:
/// - Nombre completo
/// - Correo electrónico
/// - Número de teléfono
/// - Contraseña
/// 
/// Crea tanto la cuenta en Firebase Auth como el perfil en Firestore
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  
  @override
  State<SignupPage> createState() => _SignupPageState();
}

/// Estado de la página de registro
/// 
/// Gestiona el formulario, la validación y el proceso de creación de cuenta
class _SignupPageState extends State<SignupPage> {
  /// Clave global para identificar y validar el formulario
  /// 
  /// Permite ejecutar validaciones y guardar todos los campos
  /// de forma centralizada
  final _formKey = GlobalKey<FormState>();
  
  /// Servicio que maneja toda la lógica de registro
  /// 
  /// Incluye creación de cuenta en Firebase Auth y
  /// almacenamiento de datos adicionales en Firestore
  final _authService = AuthService();
  
  /// Variables para almacenar los datos del formulario
  /// 
  /// Se inicializan como strings vacíos y se actualizan
  /// cuando el formulario se guarda (form.save())
  String name = '', email = '', phone = '', password = '';
  
  /// Bandera que indica si se está procesando el registro
  /// 
  /// Controla:
  /// - La deshabilitación del botón durante el proceso
  /// - La visualización del indicador de carga
  /// - Previene envíos múltiples simultáneos
  bool loading = false;

  /// Procesa el registro del nuevo usuario
  /// 
  /// Flujo del proceso:
  /// 1. Valida todos los campos del formulario
  /// 2. Guarda los valores de los campos
  /// 3. Activa el estado de carga
  /// 4. Intenta crear la cuenta en Firebase Auth y Firestore
  /// 5. Muestra mensaje de éxito o error
  /// 6. Si es exitoso, regresa al login
  Future<void> _register() async {
    // Obtiene el estado actual del formulario
    final form = _formKey.currentState!;
    
    // Valida todos los campos según sus validators
    if (form.validate()) {
      // Guarda los valores (ejecuta onSaved de cada campo)
      form.save();
      
      // Activa el estado de carga
      setState(() => loading = true);
      
      /// Intenta crear la cuenta
      /// 
      /// El servicio de autenticación:
      /// 1. Crea la cuenta en Firebase Auth con email/password
      /// 2. Guarda datos adicionales (name, phone) en Firestore
      /// 3. Retorna el usuario si es exitoso, null si falla
      final user = await _authService.signUpWithEmail(
        email, 
        password, 
        name, 
        phone
      );
      
      // Desactiva el estado de carga
      setState(() => loading = false);
      
      /// Verifica el resultado del registro
      if (user != null) {
        /// Registro exitoso
        /// 
        /// Muestra mensaje de confirmación
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta creada exitosamente')),
        );
        
        /// Regresa a la pantalla anterior (login)
        /// 
        /// Usa pop() en lugar de pushReplacement porque:
        /// - Ya estamos en un flujo de navegación desde login
        /// - El usuario puede iniciar sesión inmediatamente
        /// - Mantiene la pila de navegación limpia
        Navigator.pop(context);
      } else {
        /// Registro fallido
        /// 
        /// Razones comunes de fallo:
        /// - Email ya registrado (más común)
        /// - Conexión a internet débil o ausente
        /// - Error en Firebase
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al crear cuenta. El email puede estar en uso.')
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barra superior de la aplicación
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      
      /// Cuerpo centrado con scroll para pantallas pequeñas
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          
          /// Formulario principal de registro
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                /// Ícono grande de agregar persona
                /// 
                /// Identifica visualmente la funcionalidad de registro
                /// Color verde mantiene la coherencia de marca
                const Icon(Icons.person_add, size: 80, color: Colors.green),
                
                const SizedBox(height: 20),
                
                /// Título de la página
                Text(
                  'Regístrate',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 30),
                
                /// Campo: Nombre completo
                /// 
                /// Validación: No puede estar vacío
                /// Este campo es único del registro (no está en login)
                /// Se guarda en Firestore para personalización
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  // Guarda el valor eliminando espacios al inicio/final
                  onSaved: (v) => name = v!.trim(),
                  // Valida que no esté vacío
                  validator: (v) => v != null && v.isNotEmpty 
                      ? null 
                      : 'Nombre requerido',
                ),
                
                const SizedBox(height: 15),
                
                /// Campo: Correo electrónico
                /// 
                /// Validación: Debe contener '@' (formato básico)
                /// Este será el identificador único del usuario
                /// Teclado optimizado para emails (@, .com accesibles)
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  // Teclado especializado para emails
                  keyboardType: TextInputType.emailAddress,
                  onSaved: (v) => email = v!.trim(),
                  // Validación básica de formato de email
                  validator: (v) => v != null && v.contains('@') 
                      ? null 
                      : 'Email inválido',
                ),
                
                const SizedBox(height: 15),
                
                /// Campo: Teléfono
                /// 
                /// Validación: Mínimo 9 dígitos
                /// Útil para contacto de emergencia en app de primeros auxilios
                /// Teclado numérico para facilitar entrada
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  // Teclado numérico con símbolos telefónicos
                  keyboardType: TextInputType.phone,
                  onSaved: (v) => phone = v!.trim(),
                  /// Valida longitud mínima de 9 caracteres
                  /// 
                  /// 9 es un valor razonable porque:
                  /// - Mayoría de países tienen números de 9-11 dígitos
                  /// - Permite números con/sin código de país
                  /// - No es demasiado restrictivo ni permisivo
                  validator: (v) => v != null && v.length >= 9 
                      ? null 
                      : 'Teléfono inválido',
                ),
                
                const SizedBox(height: 15),
                
                /// Campo: Contraseña
                /// 
                /// Validación: Mínimo 6 caracteres (requisito de Firebase)
                /// Texto oculto (obscureText) por seguridad
                /// Se guarda encriptada en Firebase Auth
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  // Oculta el texto ingresado (muestra bullets)
                  obscureText: true,
                  onSaved: (v) => password = v!.trim(),
                  /// Valida longitud mínima de 6 caracteres
                  /// 
                  /// Firebase Auth requiere mínimo 6 caracteres
                  /// En producción, se recomienda mayor longitud
                  /// y complejidad (mayúsculas, números, símbolos)
                  validator: (v) => v != null && v.length >= 6 
                      ? null 
                      : 'Mínimo 6 caracteres',
                ),
                
                const SizedBox(height: 25),
                
                /// Botón de registro
                /// 
                /// Características:
                /// - Ancho completo para fácil acceso
                /// - Se deshabilita durante el proceso de carga
                /// - Muestra indicador de progreso mientras procesa
                /// - Color verde corporativo
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    // Deshabilita el botón si está cargando
                    onPressed: loading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    /// Muestra spinner circular si está cargando,
                    /// sino muestra el texto del botón
                    child: loading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Registrar', 
                            style: TextStyle(fontSize: 16)
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}