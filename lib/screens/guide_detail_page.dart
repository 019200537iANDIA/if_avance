// Importaciones necesarias
import 'package:flutter/material.dart';  // Widgets y Material Design
import '../models/guide.dart';           // Modelo de datos Guide

/// Pantalla de detalle que muestra el contenido completo de una guía de primeros auxilios
/// 
/// Esta pantalla es stateless (sin estado) porque solo presenta información
/// que recibe como parámetro, no gestiona estado interno que cambie durante
/// su ciclo de vida. Es optimizada para lectura rápida en situaciones de emergencia.
class GuideDetailPage extends StatelessWidget {
  /// La guía completa que se va a mostrar en detalle
  /// 
  /// Este objeto contiene toda la información necesaria:
  /// título, contenido completo e imagen ilustrativa
  final Guide guide;
  
  /// Constructor que requiere una guía como parámetro obligatorio
  /// 
  /// Esta guía se pasa desde la pantalla anterior mediante la navegación
  /// Ejemplo de navegación:
  /// ```dart
  /// Navigator.push(
  ///   context,
  ///   MaterialPageRoute(
  ///     builder: (context) => GuideDetailPage(guide: selectedGuide)
  ///   )
  /// );
  /// ```
  const GuideDetailPage({super.key, required this.guide});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barra superior que muestra el título de la guía
      appBar: AppBar(
        title: Text(guide.title),
        // Color verde característico de la app de primeros auxilios
        backgroundColor: Colors.green,
        // Texto blanco para buen contraste
        foregroundColor: Colors.white,
      ),
      
      // Cuerpo principal con scroll para contenido largo
      body: SingleChildScrollView(
        // Espaciado uniforme alrededor de todo el contenido
        padding: const EdgeInsets.all(16),
        
        // Columna que organiza los elementos verticalmente
        child: Column(
          // Alinea todo el contenido al inicio (izquierda)
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de imagen centrada
            Center(
              child: Image.asset(
                // Verifica si hay ruta de imagen, sino usa el logo por defecto
                guide.imagePath.isNotEmpty
                    ? guide.imagePath
                    : 'assets/images/logo.png',
                    
                // Altura fija para consistencia visual
                height: 200,
                
                /// Manejo de errores de carga de imagen
                /// 
                /// Si la imagen no existe o falla al cargar, muestra un ícono
                /// médico genérico en lugar de romper la interfaz.
                /// Los tres parámetros (context, error, stackTrace) son requeridos
                /// pero no los usamos aquí, por eso se nombran con guiones bajos.
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.medical_services,
                  size: 100,
                  color: Colors.green,
                ),
              ),
            ),
            
            // Espaciado entre imagen y título
            const SizedBox(height: 20),
            
            /// Título de la guía con estilo destacado
            /// 
            /// Usa el estilo de tema predefinido pero lo personaliza
            /// con negrita para mayor énfasis visual
            Text(
              guide.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            
            /// Línea divisoria decorativa
            /// 
            /// Separa visualmente el título del contenido
            /// El parámetro height incluye el espacio vertical total
            const Divider(height: 30),
            
            /// Contenido completo de la guía con formato legible
            /// 
            /// Características importantes:
            /// - fontSize: 16 - Tamaño cómodo para lectura en móviles
            /// - height: 1.5 - Espaciado entre líneas (150% del tamaño de fuente)
            ///   Esto mejora significativamente la legibilidad, especialmente
            ///   importante en situaciones de estrés o emergencia
            Text(
              guide.content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5, // Interlineado generoso para lectura fácil
              ),
            ),
          ],
        ),
      ),
    );
  }
}