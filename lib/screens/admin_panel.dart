// Importaciones necesarias para la pantalla de administración
import 'package:flutter/material.dart';      // Widgets y Material Design
import '../services/guide_service.dart';     // Servicio para operaciones CRUD de guías
import '../models/guide.dart';               // Modelo de datos Guide

/// Pantalla de administración para gestionar las guías de primeros auxilios
/// 
/// Esta pantalla permite a los administradores realizar operaciones CRUD
/// (Crear, Leer, Actualizar, Eliminar) sobre las guías disponibles en la app.
/// Utiliza Firebase Firestore para persistencia de datos en tiempo real.
class AdminPanel extends StatefulWidget {
  /// Constructor constante para optimización de rendimiento
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

/// Estado del panel de administración
/// 
/// Gestiona la lógica de la interfaz y las operaciones sobre las guías
class _AdminPanelState extends State<AdminPanel> {
  /// Instancia del servicio que gestiona las operaciones CRUD con Firebase
  /// 
  /// Este servicio proporciona métodos para crear, leer, actualizar
  /// y eliminar guías de la base de datos Firestore
  final _guideService = GuideService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barra superior de la aplicación
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        // Color naranja intenso para identificar el área administrativa
        backgroundColor: Colors.deepOrange,
        // Texto blanco para buen contraste
        foregroundColor: Colors.white,
      ),
      
      // Cuerpo principal con StreamBuilder para actualizaciones en tiempo real
      body: StreamBuilder<List<Guide>>(
        // Stream que escucha cambios en la colección de guías de Firebase
        // Se actualiza automáticamente cuando hay cambios en la base de datos
        stream: _guideService.getGuides(),
        
        // Constructor que se ejecuta cada vez que hay nuevos datos
        builder: (context, snapshot) {
          // Estado de carga: muestra un indicador circular
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Estado de error: muestra el mensaje de error
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Extrae la lista de guías o una lista vacía si no hay datos
          final guides = snapshot.data ?? [];

          // Construye una lista desplazable con todas las guías
          return ListView.builder(
            // Espaciado alrededor de la lista
            padding: const EdgeInsets.all(8),
            // Número de elementos en la lista
            itemCount: guides.length,
            
            // Constructor de cada elemento de la lista
            itemBuilder: (context, i) {
              final guide = guides[i];
              
              // Tarjeta para cada guía con diseño Material Design
              return Card(
                // Espaciado vertical entre tarjetas
                margin: const EdgeInsets.symmetric(vertical: 8),
                
                // Contenido de la tarjeta
                child: ListTile(
                  // Ícono de servicios médicos a la izquierda
                  leading: const Icon(
                    Icons.medical_services, 
                    color: Colors.deepOrange
                  ),
                  
                  // Título de la guía en negrita
                  title: Text(
                    guide.title, 
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  
                  // Vista previa del contenido (truncado a 50 caracteres)
                  subtitle: Text(
                    guide.content.length > 50
                        ? '${guide.content.substring(0, 50)}...'
                        : guide.content,
                  ),
                  
                  // Botones de acción a la derecha
                  trailing: Row(
                    // Ocupa solo el espacio necesario
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón para editar la guía
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditDialog(guide),
                      ),
                      
                      // Botón para eliminar la guía
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(guide),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      
      // Botón flotante para crear nuevas guías
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: Colors.deepOrange,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Guía'),
      ),
    );
  }

  /// Muestra un diálogo para crear una nueva guía
  /// 
  /// Presenta un formulario con tres campos:
  /// - Título de la guía (obligatorio)
  /// - Contenido con las instrucciones (obligatorio)
  /// - Ruta de la imagen (opcional, usa logo por defecto)
  void _showCreateDialog() {
    // Controladores para capturar el texto de cada campo
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final imagePathController = TextEditingController();

    // Muestra el diálogo modal
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Nueva Guía'),
        
        // Contenido desplazable para pantallas pequeñas
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Campo para el título
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              
              // Campo para el contenido (multilínea)
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Contenido',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5, // Permite múltiples líneas
              ),
              const SizedBox(height: 10),
              
              // Campo para la ruta de la imagen
              TextField(
                controller: imagePathController,
                decoration: const InputDecoration(
                  labelText: 'Ruta de imagen (ej: assets/images/ejemplo.png)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        
        // Botones de acción del diálogo
        actions: [
          // Botón para cancelar la operación
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          
          // Botón para crear la guía
          ElevatedButton(
            onPressed: () async {
              // Validación: verifica que los campos obligatorios no estén vacíos
              if (titleController.text.isNotEmpty && 
                  contentController.text.isNotEmpty) {
                
                // Crea la guía en Firebase
                await _guideService.createGuide(
                  titleController.text,
                  contentController.text,
                  // Usa logo por defecto si no se especifica imagen
                  imagePathController.text.isEmpty 
                      ? 'assets/images/logo.png' 
                      : imagePathController.text,
                );
                
                // Cierra el diálogo
                Navigator.pop(context);
                
                // Muestra mensaje de confirmación
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Guía creada exitosamente')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange
            ),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  /// Muestra un diálogo para editar una guía existente
  /// 
  /// Similar al diálogo de creación, pero con los campos prellenados
  /// con los datos actuales de la guía
  /// 
  /// Parámetro:
  /// - [guide]: La guía que se va a editar
  void _showEditDialog(Guide guide) {
    // Controladores inicializados con los valores actuales
    final titleController = TextEditingController(text: guide.title);
    final contentController = TextEditingController(text: guide.content);
    final imagePathController = TextEditingController(text: guide.imagePath);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Guía'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Campo para editar el título
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              
              // Campo para editar el contenido
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Contenido',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 10),
              
              // Campo para editar la ruta de imagen
              TextField(
                controller: imagePathController,
                decoration: const InputDecoration(
                  labelText: 'Ruta de imagen',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Botón para cancelar la edición
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          
          // Botón para guardar los cambios
          ElevatedButton(
            onPressed: () async {
              // Validación de campos obligatorios
              if (titleController.text.isNotEmpty && 
                  contentController.text.isNotEmpty) {
                
                // Actualiza la guía en Firebase
                await _guideService.updateGuide(
                  guide.id!, // ID de la guía a actualizar
                  titleController.text,
                  contentController.text,
                  imagePathController.text.isEmpty 
                      ? 'assets/images/logo.png' 
                      : imagePathController.text,
                );
                
                Navigator.pop(context);
                
                // Confirmación visual
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Guía actualizada')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  /// Muestra un diálogo de confirmación antes de eliminar una guía
  /// 
  /// Importante: Solicita confirmación para evitar borrados accidentales
  /// ya que esta acción no se puede deshacer
  /// 
  /// Parámetro:
  /// - [guide]: La guía que se va a eliminar
  void _confirmDelete(Guide guide) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Guía'),
        
        // Mensaje personalizado con el título de la guía
        content: Text('¿Estás seguro de eliminar "${guide.title}"?'),
        
        actions: [
          // Botón para cancelar la eliminación
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          
          // Botón para confirmar la eliminación
          ElevatedButton(
            onPressed: () async {
              // Elimina la guía de Firebase
              await _guideService.deleteGuide(guide.id!);
              
              Navigator.pop(context);
              
              // Confirmación de eliminación exitosa
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Guía eliminada')),
              );
            },
            // Color rojo para indicar acción destructiva
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}