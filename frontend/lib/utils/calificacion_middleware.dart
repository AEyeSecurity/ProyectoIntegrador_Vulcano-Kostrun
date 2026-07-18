// lib/utils/calificacion_middleware.dart

import 'package:flutter/material.dart';
import 'dart:ui'; // Para ImageFilter.blur
import '../services/calificacion_service.dart';
import '../screens/menu_perfil/calificaciones_pendientes_screen.dart';

class CalificacionMiddleware {
  /// Verifica si hay calificaciones pendientes y bloquea la navegación si es necesario
  static Future<bool> verificarYBloquear(BuildContext parentContext) async {
    print('🔍 CalificacionMiddleware.verificarYBloquear() llamado');
    
    final tienePendientes = await CalificacionService.tieneCalificacionesPendientes();
    
    print('📊 ¿Tiene pendientes?: $tienePendientes');
    
    if (tienePendientes && parentContext.mounted) {
      print('🚫 BLOQUEANDO - Mostrando diálogo');
      
      await showDialog<bool>(
        context: parentContext,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.6),
        builder: (dialogContext) => PopScope(
          canPop: false,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: Colors.white,
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      size: 48,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '¡Tu opinión es importante!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tienes trabajos finalizados esperando tu calificación.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC5414B).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFC5414B).withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: const Color(0xFFC5414B),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Calificar a tus compañeros de trabajo ayuda a mantener la calidad de nuestra comunidad.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        print('✅ Usuario presionó "Calificar Ahora"');
                        Navigator.pop(dialogContext);
                        
                        if (parentContext.mounted) {
                          // ✅ Reemplazar LoginScreen por CalificacionesPendientes
                          // Así el login nunca se ve de fondo
                          Navigator.pushReplacement(
                            parentContext,
                            MaterialPageRoute(
                              builder: (_) => const CalificacionesPendientesScreen(fromLogin: true),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC5414B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.star_rounded, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Calificar Ahora',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Solo te tomará un minuto ⏱️',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      
      return true;
    }
    
    print('✅ NO hay pendientes - Permitir acceso');
    return false;
  }

  /// Verificar y mostrar badge en pantallas
  static Future<int> obtenerCantidadPendientes() async {
    try {
      final pendientes = await CalificacionService.obtenerCalificacionesPendientes();
      return pendientes.length;
    } catch (e) {
      print('❌ Error obteniendo cantidad de pendientes: $e');
      return 0;
    }
  }
}