// lib/services/baja_cuenta_service.dart

import '../services/supabase_client.dart';
import '../services/auth_service.dart';
import '../models/menu_perfil/baja_cuenta_model.dart';

class BajaCuentaService {
  static final _supabase = SupabaseConfig.client;

  // ============================================================
  // 1. VERIFICAR ESTADO DE CUENTA (llama al RPC de Supabase)
  // ============================================================
  /// Verifica si la cuenta del usuario actual está suspendida por puntuación.
  /// Retorna un BajaCuentaInfo con toda la información de la suspensión.
  static Future<BajaCuentaInfo> verificarEstadoCuenta() async {
    try {
      final userData = await AuthService.getCurrentUserData();
      if (userData == null) {
        print('❌ BajaCuentaService: Usuario no autenticado');
        return BajaCuentaInfo(estado: 'ACTIVO', suspendido: false);
      }

      print('🔍 Verificando estado de cuenta para usuario: ${userData.idUsuario}');

      final response = await _supabase.rpc(
        'verificar_estado_cuenta',
        params: {'p_id_usuario': userData.idUsuario},
      );

      print('📋 Respuesta verificar_estado_cuenta: $response');

      if (response == null) {
        return BajaCuentaInfo(estado: 'ACTIVO', suspendido: false);
      }

      // La función RPC retorna JSON
      final info = BajaCuentaInfo.fromJson(
        response is Map<String, dynamic> 
            ? response 
            : Map<String, dynamic>.from(response as Map),
      );

      if (info.suspendido) {
        print('⚠️ CUENTA SUSPENDIDA - Rol: ${info.rolAfectado}, '
            'Promedio: ${info.promedioAlMomento}, '
            'Fecha: ${info.fechaBajaFormateada}');
      } else {
        print('✅ Cuenta activa');
      }

      return info;
    } catch (e) {
      print('❌ Error en verificarEstadoCuenta: $e');
      // En caso de error, no bloquear al usuario
      return BajaCuentaInfo(estado: 'ACTIVO', suspendido: false);
    }
  }

  // ============================================================
  // 2. VERIFICAR RÁPIDO (solo true/false)
  // ============================================================
  /// Verificación rápida para usar en guards/middleware.
  /// Retorna true si la cuenta está suspendida.
  static Future<bool> estaSuspendidoPorPuntuacion() async {
    try {
      final info = await verificarEstadoCuenta();
      return info.suspendido;
    } catch (e) {
      print('❌ Error en estaSuspendidoPorPuntuacion: $e');
      return false;
    }
  }

  // ============================================================
  // 3. CERRAR SESIÓN POR SUSPENSIÓN
  // ============================================================
  /// Cierra la sesión del usuario suspendido.
  static Future<void> cerrarSesionPorSuspension() async {
    try {
      print('🔒 Cerrando sesión por suspensión de cuenta...');
      await AuthService.signOut();
      print('✅ Sesión cerrada por suspensión');
    } catch (e) {
      print('❌ Error cerrando sesión por suspensión: $e');
    }
  }

  // ============================================================
  // 4. OBTENER HISTORIAL DE BAJAS DEL USUARIO
  // ============================================================
  /// Obtiene el historial de suspensiones del usuario actual.
  static Future<List<Map<String, dynamic>>> obtenerHistorialBajas() async {
    try {
      final userData = await AuthService.getCurrentUserData();
      if (userData == null) return [];

      final response = await _supabase
          .from('baja_por_puntuacion')
          .select()
          .eq('id_usuario', userData.idUsuario)
          .order('fecha_baja', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('❌ Error en obtenerHistorialBajas: $e');
      return [];
    }
  }

  // ============================================================
  // 5. OBTENER CONFIGURACIÓN ACTUAL DE UMBRALES
  // ============================================================
  /// Obtiene los umbrales configurados para mostrar al usuario.
  static Future<Map<String, dynamic>?> obtenerConfiguracion() async {
    try {
      final response = await _supabase
          .from('configuracion_baja_puntuacion')
          .select()
          .eq('activo', true)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      print('❌ Error en obtenerConfiguracion: $e');
      return null;
    }
  }
}