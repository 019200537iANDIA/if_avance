/// Modelo de datos que representa un usuario de la aplicación
/// 
/// Esta clase encapsula toda la información personal y de autenticación
/// de un usuario registrado en el sistema de primeros auxilios.
/// Incluye métodos para serialización y deserialización con la base de datos.
class User {
  /// Identificador único del usuario en la base de datos
  /// 
  /// Es nullable porque se genera automáticamente al insertar
  /// un nuevo usuario. Para usuarios nuevos que aún no se han
  /// guardado en la base de datos, este valor será null.
  int? id;
  
  /// Nombre completo del usuario
  /// 
  /// Ejemplo: "Juan Pérez García"
  /// Este campo es obligatorio y se muestra en el perfil del usuario
  String name;
  
  /// Dirección de correo electrónico del usuario
  /// 
  /// Sirve como identificador único para el inicio de sesión
  /// Debe tener un formato válido (ejemplo: usuario@ejemplo.com)
  /// Este campo es obligatorio y único en el sistema
  String email;
  
  /// Número de teléfono de contacto del usuario
  /// 
  /// Puede ser útil para notificaciones de emergencia o
  /// recuperación de cuenta. Debe incluir código de país si es necesario
  /// Ejemplo: "+51 987654321"
  String phone;
  
  /// Contraseña del usuario para autenticación
  /// 
  /// IMPORTANTE: En producción, esta contraseña debe estar encriptada
  /// antes de almacenarse. Nunca se debe guardar en texto plano.
  /// Se recomienda usar algoritmos como bcrypt, SHA-256, o los
  /// servicios de Firebase Authentication para mayor seguridad.
  String password;

  /// Constructor principal de la clase User
  /// 
  /// Parámetros:
  /// - [id]: Identificador opcional (generado por la base de datos)
  /// - [name]: Nombre completo obligatorio
  /// - [email]: Correo electrónico obligatorio (debe ser único)
  /// - [phone]: Teléfono de contacto obligatorio
  /// - [password]: Contraseña obligatoria (debe ser encriptada)
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// User newUser = User(
  ///   name: "María López",
  ///   email: "maria@ejemplo.com",
  ///   phone: "+51 999888777",
  ///   password: "contraseña_encriptada"
  /// );
  /// ```
  User({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.password
  });

  /// Convierte el objeto User a un mapa de datos para la base de datos
  /// 
  /// Este método serializa el objeto para que pueda ser almacenado
  /// en la base de datos local (SQLite) o sincronizado con un servidor.
  /// A diferencia del modelo Guide, aquí SÍ incluimos el ID porque
  /// puede ser necesario para operaciones de actualización.
  /// 
  /// Retorna un [Map<String, dynamic>] con todos los campos del usuario
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// User user = User(name: "Pedro", email: "pedro@mail.com", ...);
  /// Map<String, dynamic> userData = user.toMap();
  /// await database.insert('users', userData);
  /// ```
  Map<String, dynamic> toMap() {
    return {
      'id': id,           // ID del usuario (puede ser null para nuevos usuarios)
      'name': name,       // Nombre completo
      'email': email,     // Correo electrónico único
      'phone': phone,     // Número de teléfono
      'password': password, // Contraseña (debe estar encriptada)
    };
  }

  /// Factory constructor que crea un objeto User desde datos de la base de datos
  /// 
  /// Este método deserializa los datos recuperados de la base de datos
  /// y reconstruye un objeto User completo. A diferencia del modelo Guide,
  /// aquí NO usamos operadores null-aware (??) porque asumimos que todos
  /// los campos son obligatorios y deben existir en la base de datos.
  /// 
  /// Parámetros:
  /// - [map]: Mapa con los datos del usuario desde la base de datos
  /// 
  /// Retorna una instancia de [User] con todos los datos poblados
  /// 
  /// IMPORTANTE: Si algún campo es null en el mapa, esto causará un error.
  /// En producción, se recomienda agregar validación o valores por defecto.
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// Map<String, dynamic> userData = await database.query('users', where: 'id = ?', whereArgs: [1]);
  /// User user = User.fromMap(userData.first);
  /// ```
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      // Extrae el ID del mapa (puede ser null)
      id: map['id'],
      
      // Extrae el nombre del usuario
      name: map['name'],
      
      // Extrae el correo electrónico
      email: map['email'],
      
      // Extrae el número de teléfono
      phone: map['phone'],
      
      // Extrae la contraseña encriptada
      password: map['password'],
    );
  }
}