// lib/services/baja_cuenta_service.dart

import '../services/supabase_client.dart';
import '../services/auth_service.dart';
import '../models/menu_perfil/baja_cuenta_model.dart';

class BajaCuentaService {
  static final _supabase = SupabaseConfig.client;

  // ============================================================
  // 1. VERIFICAR ESTADO DE CUENTA
  // ============================================================
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

      print('📋 Respuesta verificar estado cuenta: $response');

      if (response == null) {
        return BajaCuentaInfo(estado: 'ACTIVO', suspendido: false);
      }

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
      return BajaCuentaInfo(estado: 'ACTIVO', suspendido: false);
    }
  }

  // ============================================================
  // 2. VERIFICAR RÁPIDO (solo true/false)
  // ============================================================
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
  // 4. SOLICITAR REACTIVACIÓN
  // ============================================================
  static Future<Map<String, dynamic>> solicitarReactivacion(String mensaje) async {
    try {
      final userData = await AuthService.getCurrentUserData();
      if (userData == null) {
        return {'exito': false, 'mensaje': 'Usuario no autenticado'};
      }

      print('📨 Solicitando reactivación para usuario: ${userData.idUsuario}');

      final response = await _supabase.rpc(
        'solicitar_reactivacion',
        params: {
          'p_id_usuario': userData.idUsuario,
          'p_mensaje': mensaje,
        },
      );

      print('📋 Respuesta solicitar reactivación: $response');

      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }

      return {'exito': false, 'mensaje': 'Respuesta inesperada del servidor'};
    } catch (e) {
      print('❌ Error en solicitarReactivacion: $e');
      return {'exito': false, 'mensaje': 'Error al enviar solicitud: $e'};
    }
  }

  // ============================================================
  // 5. OBTENER HISTORIAL DE BAJAS
  // ============================================================
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
  // 6. OBTENER CONFIGURACIÓN ACTUAL
  // ============================================================
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

  // ============================================================
  // 7. FUNCIONES DE ADMIN
  // ============================================================

  /// Obtener solicitudes pendientes (solo admin)
  static Future<List<Map<String, dynamic>>> obtenerSolicitudesPendientes() async {
    try {
      final userData = await AuthService.getCurrentUserData();
      if (userData == null) return [];

      final response = await _supabase.rpc(
        'obtener_solicitudes_reactivacion',
        params: {'p_id_admin': userData.idUsuario},
      );

      if (response is List) {
        return List<Map<String, dynamic>>.from(
            response.map((e) => Map<String, dynamic>.from(e as Map)));
      }

      return [];
    } catch (e) {
      print('❌ Error en obtenerSolicitudesPendientes: $e');
      return [];
    }
  }

  /// Aprobar reactivación (solo admin)
  static Future<Map<String, dynamic>> aprobarReactivacion(int idBaja) async {
    try {
      final userData = await AuthService.getCurrentUserData();
      if (userData == null) {
        return {'exito': false, 'mensaje': 'No autenticado'};
      }

      final response = await _supabase.rpc(
        'aprobar_reactivacion',
        params: {
          'p_id_baja': idBaja,
          'p_id_admin': userData.idUsuario,
        },
      );

      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return {'exito': false, 'mensaje': 'Respuesta inesperada'};
    } catch (e) {
      print('❌ Error en aprobarReactivacion: $e');
      return {'exito': false, 'mensaje': 'Error: $e'};
    }
  }

  /// Rechazar reactivación (solo admin)
  static Future<Map<String, dynamic>> rechazarReactivacion(
      int idBaja, String motivo) async {
    try {
      final userData = await AuthService.getCurrentUserData();
      if (userData == null) {
        return {'exito': false, 'mensaje': 'No autenticado'};
      }

      final response = await _supabase.rpc(
        'rechazar_reactivacion',
        params: {
          'p_id_baja': idBaja,
          'p_id_admin': userData.idUsuario,
          'p_motivo_rechazo': motivo,
        },
      );

      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return {'exito': false, 'mensaje': 'Respuesta inesperada'};
    } catch (e) {
      print('❌ Error en rechazarReactivacion: $e');
      return {'exito': false, 'mensaje': 'Error: $e'};
    }
  }

  /// Verificar si el usuario actual es admin
  static Future<bool> esAdmin() async {
    try {
      final userData = await AuthService.getCurrentUserData();
      if (userData == null) return false;

      final response = await _supabase
          .from('usuario')
          .select('es_admin')
          .eq('id_usuario', userData.idUsuario)
          .maybeSingle();

      return response?['es_admin'] == true;
    } catch (e) {
      print('❌ Error en esAdmin: $e');
      return false;
    }
  }
}