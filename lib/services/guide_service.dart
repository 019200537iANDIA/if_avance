// Importaciones necesarias
import 'package:cloud_firestore/cloud_firestore.dart';  // Base de datos NoSQL de Firebase
import '../models/guide.dart';                          // Modelo de datos Guide

/// Servicio centralizado para gestionar guías de primeros auxilios
/// 
/// Esta clase maneja todas las operaciones CRUD (Crear, Leer, Actualizar, Eliminar)
/// sobre las guías almacenadas en Cloud Firestore. Proporciona:
/// - Stream en tiempo real de todas las guías
/// - Métodos para crear, actualizar y eliminar guías
/// - Inicialización automática de guías predeterminadas
/// 
/// Todas las operaciones son asíncronas ya que interactúan con Firebase
class GuideService {
  /// Instancia de Cloud Firestore
  /// 
  /// Base de datos NoSQL de Firebase donde se almacenan las guías.
  /// Firestore organiza datos en colecciones y documentos.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Nombre de la colección de guías en Firestore
  /// 
  /// Todas las guías se almacenan en esta colección.
  /// Usar una constante evita errores tipográficos y facilita cambios futuros.
  final String collection = 'guides';

  /// Obtiene todas las guías como un Stream en tiempo real
  /// 
  /// Este método es fundamental para la arquitectura reactiva de la app.
  /// Retorna un Stream que emite automáticamente la lista actualizada
  /// cada vez que hay cambios en la colección de Firestore.
  /// 
  /// Características:
  /// - Ordenado alfabéticamente por título
  /// - Actualizaciones en tiempo real (sin polling)
  /// - Transformación automática de documentos a objetos Guide
  /// 
  /// Retorna:
  /// Stream<List<Guide>> que emite la lista completa de guías
  /// cada vez que la colección cambia
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// StreamBuilder<List<Guide>>(
  ///   stream: guideService.getGuides(),
  ///   builder: (context, snapshot) {
  ///     final guides = snapshot.data ?? [];
  ///     return ListView.builder(...);
  ///   }
  /// )
  /// ```
  Stream<List<Guide>> getGuides() {
    return _firestore
        .collection(collection)
        /// Ordena las guías alfabéticamente por título
        /// 
        /// Esto asegura que las guías siempre se muestren
        /// en orden consistente en todas las pantallas
        .orderBy('title')
        /// Escucha cambios en tiempo real
        /// 
        /// snapshots() crea un Stream que emite cada vez que:
        /// - Se agrega un documento
        /// - Se modifica un documento
        /// - Se elimina un documento
        .snapshots()
        /// Transforma cada snapshot en una lista de objetos Guide
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            /// Extrae los datos del documento
            final data = doc.data();
            
            /// Crea un objeto Guide desde los datos
            /// 
            /// Usa el operador null-aware (??) para proporcionar
            /// valores por defecto si algún campo es null,
            /// evitando errores en tiempo de ejecución
            return Guide(
              id: doc.id,                            // ID del documento Firestore
              title: data['title'] ?? '',            // Título con fallback a vacío
              content: data['content'] ?? '',        // Contenido con fallback
              imagePath: data['imagePath'] ?? '',    // Ruta de imagen con fallback
            );
          }).toList(),
        );
  }

  /// Crea una nueva guía en Firestore
  /// 
  /// Agrega un nuevo documento a la colección de guías con todos
  /// los campos necesarios más un timestamp de creación.
  /// 
  /// Parámetros:
  /// - [title]: Título descriptivo de la guía
  /// - [content]: Contenido con instrucciones paso a paso
  /// - [imagePath]: Ruta del asset o URL de la imagen
  /// 
  /// El ID del documento se genera automáticamente por Firestore.
  /// El método agrega automáticamente un campo 'createdAt' con
  /// el timestamp del servidor para auditoría.
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// await guideService.createGuide(
  ///   'Primeros Auxilios para Ahogamiento',
  ///   '1. Saca a la persona del agua...',
  ///   'assets/images/ahogamiento.png'
  /// );
  /// ```
  Future<void> createGuide(
    String title, 
    String content, 
    String imagePath
  ) async {
    await _firestore.collection(collection).add({
      'title': title,
      'content': content,
      'imagePath': imagePath,
      /// Timestamp del servidor
      /// 
      /// FieldValue.serverTimestamp() usa la hora del servidor de Firebase
      /// en lugar de la hora del dispositivo. Esto es importante porque:
      /// - Evita problemas con relojes desincronizados
      /// - Garantiza consistencia entre todos los usuarios
      /// - Proporciona una fuente única de verdad para el tiempo
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Actualiza una guía existente en Firestore
  /// 
  /// Modifica los campos especificados del documento.
  /// Solo actualiza los campos proporcionados, no reemplaza
  /// el documento completo.
  /// 
  /// Parámetros:
  /// - [id]: ID del documento Firestore a actualizar
  /// - [title]: Nuevo título de la guía
  /// - [content]: Nuevo contenido de la guía
  /// - [imagePath]: Nueva ruta de imagen
  /// 
  /// Agrega automáticamente un campo 'updatedAt' con el
  /// timestamp del servidor para rastrear la última modificación.
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// await guideService.updateGuide(
  ///   'abc123',
  ///   'RCP - Actualizado',
  ///   'Nuevas instrucciones...',
  ///   'assets/images/rcp_v2.png'
  /// );
  /// ```
  Future<void> updateGuide(
    String id, 
    String title, 
    String content, 
    String imagePath
  ) async {
    await _firestore.collection(collection).doc(id).update({
      'title': title,
      'content': content,
      'imagePath': imagePath,
      /// Timestamp de última actualización
      /// 
      /// Útil para:
      /// - Auditoría de cambios
      /// - Ordenar por recién actualizado
      /// - Sincronización de datos
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Elimina una guía de Firestore
  /// 
  /// Elimina permanentemente el documento especificado.
  /// Esta operación no se puede deshacer.
  /// 
  /// Parámetro:
  /// - [id]: ID del documento Firestore a eliminar
  /// 
  /// IMPORTANTE: No hay confirmación adicional en este nivel.
  /// La UI debe solicitar confirmación al usuario antes de llamar
  /// este método (como lo hace AdminPanel._confirmDelete).
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// await guideService.deleteGuide('abc123');
  /// ```
  Future<void> deleteGuide(String id) async {
    await _firestore.collection(collection).doc(id).delete();
  }

  /// Inicializa la base de datos con guías predeterminadas
  /// 
  /// Este método se ejecuta al iniciar la aplicación (desde main.dart).
  /// Verifica si la colección de guías está vacía, y si lo está,
  /// carga automáticamente 9 guías esenciales de primeros auxilios.
  /// 
  /// Características:
  /// - Solo ejecuta si la colección está vacía (primera instalación)
  /// - No sobrescribe guías existentes
  /// - Proporciona contenido inicial útil
  /// - Cada guía incluye pasos claros y numerados
  /// 
  /// Las guías predeterminadas cubren:
  /// 1. Quemaduras
  /// 2. Fracturas
  /// 3. Atragantamiento
  /// 4. RCP (Reanimación Cardiopulmonar)
  /// 5. Cortes y Hemorragias
  /// 6. Desmayos
  /// 7. Picaduras y Mordeduras
  /// 8. Hipotermia
  /// 9. Intoxicaciones
  /// 
  /// Todas las guías incluyen:
  /// - Instrucciones paso a paso numeradas
  /// - Cuándo llamar al 105 (número de emergencias en Perú)
  /// - Ruta a imagen ilustrativa
  Future<void> initializeDefaultGuides() async {
    /// Verifica si ya existen guías
    /// 
    /// get() obtiene un snapshot estático (no en tiempo real)
    /// de la colección para verificar si está vacía
    final snapshot = await _firestore.collection(collection).get();
    
    /// Solo inicializa si la colección está completamente vacía
    if (snapshot.docs.isEmpty) {
      /// Lista de guías predeterminadas
      /// 
      /// Cada guía es un mapa con tres campos:
      /// - title: Nombre de la emergencia
      /// - content: Instrucciones paso a paso
      /// - imagePath: Ruta al asset de imagen
      final defaultGuides = [
        {
          'title': 'Quemaduras',
          'content': 
              '1. Enfría el área con agua limpia durante 10 minutos.\n'
              '2. No revientes ampollas.\n'
              '3. Cubre con un paño limpio.\n'
              '4. Llama al 105 si es grave.',
          'imagePath': 'assets/images/quemadura.png'
        },
        {
          'title': 'Fracturas (Huesos rotos)',
          'content': 
              '1. Inmoviliza el área afectada.\n'
              '2. No intentes alinear el hueso.\n'
              '3. Aplica hielo envuelto.\n'
              '4. Llama al 105.',
          'imagePath': 'assets/images/fractura.png'
        },
        {
          'title': 'Atragantamiento',
          'content': 
              '1. Anima a toser.\n'
              '2. Si no respira, aplica maniobra de Heimlich.\n'
              '3. Llama al 105 si no mejora.',
          'imagePath': 'assets/images/atragantamiento.png'
        },
        {
          'title': 'RCP (Reanimación)',
          'content': 
              '1. Comprueba respiración.\n'
              '2. Aplica 30 compresiones y 2 ventilaciones.\n'
              '3. Mantén el ritmo hasta que llegue ayuda.',
          'imagePath': 'assets/images/rcp.png'
        },
        {
          'title': 'Cortes y Hemorragias',
          'content': 
              '1. Aplica presión directa con una gasa limpia.\n'
              '2. No retires objetos clavados.\n'
              '3. Llama al 105 si sangra mucho.',
          'imagePath': 'assets/images/cortes.png'
        },
        {
          'title': 'Desmayos',
          'content': 
              '1. Acuesta a la persona y eleva sus piernas.\n'
              '2. Afloja su ropa.\n'
              '3. Si no despierta en 1 minuto, llama al 105.',
          'imagePath': 'assets/images/desmayo.png'
        },
        {
          'title': 'Picaduras y Mordeduras',
          'content': 
              '1. Lava la zona.\n'
              '2. Aplica hielo.\n'
              '3. Si hay reacción grave, llama al 105.',
          'imagePath': 'assets/images/picadura.png'
        },
        {
          'title': 'Hipotermia',
          'content': 
              '1. Lleva a la persona a un lugar cálido.\n'
              '2. Cubre con mantas.\n'
              '3. No apliques calor directo.\n'
              '4. Llama al 105.',
          'imagePath': 'assets/images/hipotermia.png'
        },
        {
          'title': 'Intoxicaciones',
          'content': 
              '1. No provoques el vómito.\n'
              '2. Identifica la sustancia.\n'
              '3. Llama al 105 o acude a emergencias.',
          'imagePath': 'assets/images/intoxicacion.png'
        },
      ];

      /// Itera sobre cada guía predeterminada y la crea
      /// 
      /// Usa el método createGuide para mantener consistencia
      /// en la creación de documentos (incluye timestamp, etc.)
      for (var guide in defaultGuides) {
        await createGuide(
          guide['title'] as String,
          guide['content'] as String,
          guide['imagePath'] as String,
        );
      }
    }
  }
}