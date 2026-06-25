// lib/services/recomendacion_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class RecomendacionService {
  final _supabase = Supabase.instance.client;

  // Obtener el id_usuario del usuario logueado
  Future<int> _getIdUsuarioActual() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No hay sesión activa');

    final response = await _supabase
        .from('usuario')
        .select('id_usuario')
        .eq('auth_user_id', user.id)
        .single();

    return response['id_usuario'] as int;
  }

  // Obtener la lista de recomendados de un usuario (para mostrar en su perfil)
  Future<List<Map<String, dynamic>>> getRecomendados(int idQuienRecomienda) async {
  try {
    final response = await _supabase
        .from('recomendacion')
        .select('''
          id_recomendacion,
          comentario,
          fecha,
          recomendado:id_recomendado (
            id_usuario,
            usuario_persona (
              nombre,
              apellido,
              foto_perfil_url,
              username,
              puntaje_promedio
            ),
            usuario_rubro (
              rubro (
                nombre
              )
            )
          )
        ''')
        .eq('id_quien_recomienda', idQuienRecomienda)
        .order('fecha', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    print('❌ Error obteniendo recomendados: $e');
    return [];
  }
}

  // Verificar si ya recomendé a alguien
  Future<bool> yaRecomendeA(int idRecomendado) async {
    try {
      final idActual = await _getIdUsuarioActual();

      final response = await _supabase
          .from('recomendacion')
          .select('id_recomendacion')
          .eq('id_quien_recomienda', idActual)
          .eq('id_recomendado', idRecomendado)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Agregar un recomendado a mi lista
  Future<void> agregarRecomendado({
    required int idRecomendado,
    required String comentario,
  }) async {
    final idActual = await _getIdUsuarioActual();

    await _supabase.from('recomendacion').insert({
      'id_quien_recomienda': idActual,
      'id_recomendado': idRecomendado,
      'comentario': comentario,
    });
  }

  // Eliminar un recomendado de mi lista
  Future<void> eliminarRecomendado(int idRecomendacion) async {
    await _supabase
        .from('recomendacion')
        .delete()
        .eq('id_recomendacion', idRecomendacion);
  }

  // Buscar usuarios por nombre para agregar como recomendado
  Future<List<Map<String, dynamic>>> buscarUsuarios(String query) async {
    try {
      final idActual = await _getIdUsuarioActual();

      final response = await _supabase
          .from('usuario_persona')
          .select('''
            id_persona,
            nombre,
            apellido,
            foto_perfil_url,
            username,
            id_usuario
          ''')
          .or('nombre.ilike.%$query%,apellido.ilike.%$query%,username.ilike.%$query%')
          .neq('id_usuario', idActual)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error buscando usuarios: $e');
      return [];
    }
  }
}