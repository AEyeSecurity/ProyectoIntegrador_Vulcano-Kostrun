//lib/services/notificacion/notificacion_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/menu_perfil/notificacion_model.dart';

class NotificacionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ========== OBTENER ID DEL USUARIO ACTUAL ==========
  Future<int?> _obtenerIdUsuarioActual() async {
    try {
      final authUserId = _supabase.auth.currentUser?.id;
      if (authUserId == null) return null;

      final response = await _supabase
          .from('usuario')
          .select('id_usuario')
          .eq('auth_user_id', authUserId)
          .maybeSingle();

      return response?['id_usuario'] as int?;
    } catch (e) {
      print('Error obteniendo ID de usuario: $e');
      return null;
    }
  }

  // ========== OBTENER TODAS LAS NOTIFICACIONES DEL USUARIO ==========
  Future<List<Notificacion>> obtenerNotificaciones() async {
    try {
      final idUsuario = await _obtenerIdUsuarioActual();
      if (idUsuario == null) return [];

      final response = await _supabase
          .from('notificacion')
          .select()
          .eq('id_usuario', idUsuario)
          .order('fecha', ascending: false);

      return (response as List)
          .map((json) => Notificacion.fromJson(json))
          .toList();
    } catch (e) {
      print('Error obteniendo notificaciones: $e');
      return [];
    }
  }

  // ========== STREAM DE NOTIFICACIONES EN TIEMPO REAL ==========
  Stream<List<Notificacion>> streamNotificaciones() async* {
    final idUsuario = await _obtenerIdUsuarioActual();
    if (idUsuario == null) {
      yield [];
      return;
    }

    // Stream inicial con datos actuales
    yield await obtenerNotificaciones();

    // Escuchar cambios en tiempo real
    yield* _supabase
        .from('notificacion')
        .stream(primaryKey: ['id_notificacion'])
        .eq('id_usuario', idUsuario)
        .order('fecha', ascending: false)
        .map((data) => data.map((json) => Notificacion.fromJson(json)).toList());
  }

  // ========== CONTAR NOTIFICACIONES NO LEÍDAS ==========
  Future<int> contarNoLeidas() async {
    try {
      final idUsuario = await _obtenerIdUsuarioActual();
      if (idUsuario == null) return 0;

      final response = await _supabase
          .from('notificacion')
          .select()
          .eq('id_usuario', idUsuario)
          .eq('estado', 'NO_LEIDA')
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      print('Error contando notificaciones no leídas: $e');
      return 0;
    }
  }

  // ========== STREAM DE CONTADOR DE NO LEÍDAS ==========
  Stream<int> streamContadorNoLeidas() async* {
    final idUsuario = await _obtenerIdUsuarioActual();
    if (idUsuario == null) {
      yield 0;
      return;
    }

    // Valor inicial
    yield await contarNoLeidas();

    // Escuchar cambios - filtrar en el stream
    yield* _supabase
        .from('notificacion')
        .stream(primaryKey: ['id_notificacion'])
        .eq('id_usuario', idUsuario)
        .map((data) {
          // Filtrar solo NO_LEIDA
          final noLeidas = data.where((item) => item['estado'] == 'NO_LEIDA').toList();
          return noLeidas.length;
        });
  }

  // ========== MARCAR UNA NOTIFICACIÓN COMO LEÍDA ==========
  Future<bool> marcarComoLeida(int idNotificacion) async {
    try {
      await _supabase
          .from('notificacion')
          .update({'estado': 'LEIDA'})
          .eq('id_notificacion', idNotificacion);

      return true;
    } catch (e) {
      print('Error marcando notificación como leída: $e');
      return false;
    }
  }

  // ========== MARCAR TODAS COMO LEÍDAS ==========
  Future<bool> marcarTodasComoLeidas() async {
    try {
      final idUsuario = await _obtenerIdUsuarioActual();
      if (idUsuario == null) return false;

      await _supabase
          .from('notificacion')
          .update({'estado': 'LEIDA'})
          .eq('id_usuario', idUsuario)
          .eq('estado', 'NO_LEIDA');

      return true;
    } catch (e) {
      print('Error marcando todas como leídas: $e');
      return false;
    }
  }

  // ========== ELIMINAR UNA NOTIFICACIÓN ==========
  Future<bool> eliminarNotificacion(int idNotificacion) async {
    try {
      await _supabase
          .from('notificacion')
          .delete()
          .eq('id_notificacion', idNotificacion);

      return true;
    } catch (e) {
      print('Error eliminando notificación: $e');
      return false;
    }
  }

  // ========== CREAR NOTIFICACIÓN (MÉTODO ESTÁTICO) ==========
  static Future<void> crearNotificacion({
    required int usuarioId,
    required String tipo,
    required String mensaje,
    int? trabajoId,
    int? postulacionId,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      
      await supabase.from('notificacion').insert({
        'id_usuario': usuarioId,
        'tipo': tipo,
        'titulo': tipo,
        'mensaje': mensaje,
        'estado': 'NO_LEIDA',
        'fecha': DateTime.now().toIso8601String(),
      });

      print('✅ Notificación creada para usuario $usuarioId');
    } catch (e) {
      print('❌ Error creando notificación: $e');
      rethrow;
    }
  }
}