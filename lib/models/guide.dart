/// Modelo de datos que representa una guía de primeros auxilios
/// 
/// Esta clase encapsula toda la información necesaria para mostrar
/// y gestionar una guía de primeros auxilios en la aplicación.
/// Incluye métodos para serialización y deserialización con Firestore.
class Guide {
  /// Identificador único de la guía en Firestore
  /// 
  /// Es nullable porque se genera automáticamente por Firestore
  /// cuando se crea un nuevo documento. Para guías nuevas que aún
  /// no se han guardado, este valor será null.
  String? id;
  
  /// Título descriptivo de la guía
  /// 
  /// Ejemplo: "RCP - Reanimación Cardiopulmonar"
  /// Este campo es obligatorio y se muestra en la lista de guías
  String title;
  
  /// Contenido detallado con las instrucciones de primeros auxilios
  /// 
  /// Contiene paso a paso las acciones que debe realizar el usuario
  /// Puede incluir múltiples párrafos con instrucciones detalladas
  String content;
  
  /// Ruta o URL de la imagen ilustrativa de la guía
  /// 
  /// Puede ser una ruta local (assets) o una URL remota
  /// Ejemplo: "assets/images/rcp.png"
  /// La imagen ayuda a visualizar el procedimiento descrito
  String imagePath;

  /// Constructor principal de la clase Guide
  /// 
  /// Parámetros:
  /// - [id]: Identificador opcional (generado por Firestore)
  /// - [title]: Título obligatorio de la guía
  /// - [content]: Contenido obligatorio con las instrucciones
  /// - [imagePath]: Ruta obligatoria de la imagen
  Guide({
    this.id,
    required this.title,
    required this.content,
    required this.imagePath,
  });

  /// Convierte el objeto Guide a un mapa de datos para Firestore
  /// 
  /// Este método serializa el objeto para que pueda ser almacenado
  /// en la base de datos de Firebase Firestore. Note que el ID no
  /// se incluye en el mapa porque Firestore lo gestiona automáticamente
  /// como identificador del documento.
  /// 
  /// Retorna un [Map<String, dynamic>] con los campos serializables
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// Guide guide = Guide(title: "RCP", content: "...", imagePath: "...");
  /// Map<String, dynamic> data = guide.toMap();
  /// await firestore.collection('guides').add(data);
  /// ```
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'imagePath': imagePath,
    };
  }

  /// Factory constructor que crea un objeto Guide desde datos de Firestore
  /// 
  /// Este método deserializa los datos recuperados de Firestore y
  /// reconstruye un objeto Guide completo. Utiliza el operador null-aware
  /// (??) para proporcionar valores por defecto vacíos si algún campo
  /// es null, evitando así errores en tiempo de ejecución.
  /// 
  /// Parámetros:
  /// - [map]: Mapa con los datos del documento de Firestore
  /// - [id]: ID del documento (pasado por separado desde Firestore)
  /// 
  /// Retorna una instancia de [Guide] con todos los datos poblados
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// DocumentSnapshot doc = await firestore.collection('guides').doc('abc123').get();
  /// Guide guide = Guide.fromMap(doc.data()!, doc.id);
  /// ```
  factory Guide.fromMap(Map<String, dynamic> map, String id) {
    return Guide(
      // Asigna el ID del documento
      id: id,
      
      // Extrae el título o usa string vacío si es null
      title: map['title'] ?? '',
      
      // Extrae el contenido o usa string vacío si es null
      content: map['content'] ?? '',
      
      // Extrae la ruta de imagen o usa string vacío si es null
      imagePath: map['imagePath'] ?? '',
    );
  }
}