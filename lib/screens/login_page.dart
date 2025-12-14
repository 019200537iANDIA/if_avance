// Importaciones necesarias
import 'package:flutter/material.dart';   // Framework UI de Flutter
import '../services/auth_service.dart';   // Servicio de autenticación
import 'home_page.dart';                  // Pantalla principal post-login

/// Pantalla de inicio de sesión de la aplicación
/// 
/// Primera pantalla que ven los usuarios al abrir la app.
/// Proporciona dos métodos de autenticación:
/// 1. Email y contraseña tradicional
/// 2. Google Sign-In (OAuth 2.0)
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  
  @override
  State<LoginPage> createState() => _LoginPageState();
}

/// Estado de la página de inicio de sesión
/// 
/// Gestiona el formulario, la validación, el estado de carga
/// y la lógica de autenticación
class _LoginPageState extends State<LoginPage> {
  /// Clave global para identificar y validar el formulario
  /// 
  /// Permite acceder al estado del formulario desde cualquier parte
  /// del widget para ejecutar validaciones y guardar datos
  final _formKey = GlobalKey<FormState>();
  
  /// Servicio que maneja toda la lógica de autenticación
  /// 
  /// Incluye métodos para login con email/contraseña y Google
  final _authService = AuthService();

  /// Email ingresado por el usuario
  /// Se actualiza al guardar el formulario
  String email = '';
  
  /// Contraseña ingresada por el usuario
  /// Se actualiza al guardar el formulario
  String password = '';
  
  /// Bandera que indica si se está procesando una autenticación
  /// 
  /// Controla:
  /// - La deshabilitación de botones durante el proceso
  /// - La visualización del indicador de carga
  /// - Previene múltiples envíos simultáneos
  bool loading = false;

  /// Inicia sesión usando email y contraseña
  /// 
  /// Proceso:
  /// 1. Valida el formulario (verifica formato de email y longitud de contraseña)
  /// 2. Guarda los valores de los campos
  /// 3. Activa el estado de carga
  /// 4. Intenta autenticar con Firebase
  /// 5. Navega al home si es exitoso o muestra error si falla
  Future<void> _loginWithEmail() async {
    // Obtiene el estado actual del formulario
    final form = _formKey.currentState!;
    
    // Valida todos los campos según sus validators
    if (form.validate()) {
      // Guarda los valores de los campos (ejecuta onSaved de cada campo)
      form.save();
      
      // Activa el estado de carga
      setState(() => loading = true);

      // Intenta autenticar con el servicio de Firebase
      final user = await _authService.signInWithEmail(email, password);

      // Desactiva el estado de carga
      setState(() => loading = false);

      // Verifica si la autenticación fue exitosa
      if (user != null) {
        /// Login exitoso: navega al home
        /// 
        /// Usa pushReplacement en lugar de push para:
        /// - Reemplazar la pantalla de login en la pila de navegación
        /// - Prevenir que el usuario vuelva al login con el botón atrás
        /// - Mantener limpio el historial de navegación
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        /// Login fallido: muestra mensaje de error
        /// 
        /// SnackBar es ideal para mensajes temporales no intrusivos
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credenciales incorrectas')),
        );
      }
    }
  }

  /// Inicia sesión usando Google Sign-In (OAuth 2.0)
  /// 
  /// Proceso:
  /// 1. Activa el estado de carga
  /// 2. Abre el flujo de autenticación de Google
  /// 3. Navega al home si es exitoso o muestra error si falla
  /// 
  /// Ventajas de Google Sign-In:
  /// - No requiere crear contraseña
  /// - Más rápido y conveniente
  /// - Más seguro (gestión de credenciales por Google)
  Future<void> _loginWithGoogle() async {
    // Activa el estado de carga
    setState(() => loading = true);

    // Inicia el flujo de autenticación de Google
    final user = await _authService.signInWithGoogle();

    // Desactiva el estado de carga
    setState(() => loading = false);

    // Verifica si la autenticación fue exitosa
    if (user != null) {
      // Login exitoso: navega al home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      // Login fallido: muestra mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al iniciar sesión con Google')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// Cuerpo centrado con scroll para pantallas pequeñas
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              /// Logo circular de la aplicación
              /// 
              /// Avatar circular verde con ícono médico blanco
              /// Identifica visualmente la aplicación de primeros auxilios
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.green,
                child: Icon(
                  Icons.medical_services, 
                  size: 60, 
                  color: Colors.white
                ),
              ),
              
              const SizedBox(height: 20),
              
              /// Nombre de la aplicación en texto grande y negrita
              Text(
                'First Aid App',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              
              const SizedBox(height: 10),
              
              /// Eslogan de la aplicación
              const Text('Primeros auxilios al alcance de todos'),
              
              const SizedBox(height: 30),

              /// Formulario de inicio de sesión
              /// 
              /// El Form widget agrupa campos y permite validación centralizada
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    /// Campo de correo electrónico
                    /// 
                    /// Características:
                    /// - Ícono de email para claridad visual
                    /// - Teclado optimizado para emails
                    /// - Validación de formato básica (contiene @)
                    /// - Trimming automático de espacios
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      // Teclado con @ y .com accesibles
                      keyboardType: TextInputType.emailAddress,
                      // Guarda el valor eliminando espacios
                      onSaved: (v) => email = v!.trim(),
                      // Valida formato básico de email
                      validator: (v) => v != null && v.contains('@')
                          ? null
                          : 'Email inválido',
                    ),
                    
                    const SizedBox(height: 15),
                    
                    /// Campo de contraseña
                    /// 
                    /// Características:
                    /// - Ícono de candado para indicar campo seguro
                    /// - Texto oculto (obscureText)
                    /// - Validación de longitud mínima (6 caracteres)
                    /// - Trimming automático de espacios
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      // Oculta el texto ingresado (bullets)
                      obscureText: true,
                      onSaved: (v) => password = v!.trim(),
                      // Valida longitud mínima de seguridad
                      validator: (v) => v != null && v.length >= 6
                          ? null
                          : 'Mínimo 6 caracteres',
                    ),
                    
                    const SizedBox(height: 20),

                    /// Botón principal de inicio de sesión
                    /// 
                    /// Características:
                    /// - Ancho completo para fácil acceso
                    /// - Se deshabilita durante la carga
                    /// - Muestra indicador de progreso mientras carga
                    /// - Color verde característico de la app
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        // Deshabilita el botón si está cargando
                        onPressed: loading ? null : _loginWithEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        // Muestra spinner si está cargando, sino muestra texto
                        child: loading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Iniciar Sesión',
                                style: TextStyle(fontSize: 16)
                              ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    /// Divisor visual decorativo
                    /// 
                    /// Separa el login tradicional del social login
                    /// Mejora la comprensión de las opciones disponibles
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('O continuar con'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 15),

                    /// Botón de inicio de sesión con Google
                    /// 
                    /// Características:
                    /// - Diseño outlined (borde, sin relleno)
                    /// - Logo de Google para reconocimiento inmediato
                    /// - Se deshabilita durante la carga
                    /// - Alternativa moderna y conveniente
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        // Deshabilita el botón si está cargando
                        onPressed: loading ? null : _loginWithGoogle,
                        // Favicon de Google como ícono
                        icon: Image.network(
                          'https://www.google.com/favicon.ico',
                          height: 24,
                        ),
                        label: const Text('Iniciar con Google'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// Enlace a la página de registro
                    /// 
                    /// Proporciona acceso rápido al registro para usuarios nuevos
                    /// Combina texto normal con TextButton para claridad
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('¿No tienes cuenta? '),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/signup'),
                          child: const Text('Regístrate'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}