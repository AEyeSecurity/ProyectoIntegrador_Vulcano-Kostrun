// lib/services/calificacion_service.dart

import '../services/supabase_client.dart';
import '../services/auth_service.dart';
import '../models/menu_perfil/calificacion_model.dart';
import '../models/menu_perfil/reputacion_stats_model.dart';

class CalificacionService {
  static final _supabase = SupabaseConfig.client;

  // ✅ 1. Crear calificación
  static Future<void> crearCalificacion({
    required int trabajoId,
    required int idReceptor,
    required String rolReceptor, // 'EMPLEADOR' o 'EMPLEADO'
    required int puntuacion,
    String? comentario,
    bool recomendacion = false,
  }) async {
    try {
      final userData = await AuthService.getCurrentUserData();
      if (userData == null) {
        throw Exception('Usuario no autenticado');
      }

      final idEmisor = userData.idUsuario;

      // Validar que el trabajo esté FINALIZADO
      final trabajo = await _supabase
          .from('trabajo')
          .select('estado_publicacion')
          .eq('id_trabajo', trabajoId)
          .single();

      if (trabajo['estado_publicacion'] != 'FINALIZADO') {
        throw Exception('Solo puedes calificar trabajos finalizados');
      }

      // ✅ CORREGIDO: Validar que el usuario sea parte del trabajo
      final esEmpleador = await _supabase
          .from('trabajo')
          .select('empleador_id')
          .eq('id_trabajo', trabajoId)
          .eq('empleador_id', idEmisor)
          .maybeSingle();

      // ✅ CAMBIAR: Buscar con estado FINALIZADO en lugar de ACEPTADO
      final esEmpleado = await _supabase
          .from('postulacion')
          .select('postulante_id')
          .eq('trabajo_id', trabajoId)
          .eq('postulante_id', idEmisor)
          .eq('estado', 'FINALIZADO') // ✅ CAMBIO AQUÍ
          .maybeSingle();

      if (esEmpleador == null && esEmpleado == null) {
        throw Exception('No puedes calificar este trabajo');
      }

      // Validar que no haya calificado ya
      final yaCalificado = await _supabase
          .from('calificacion')
          .select()
          .eq('id_publicacion', trabajoId)
          .eq('id_emisor', idEmisor)
          .eq('id_receptor', idReceptor)
          .maybeSingle();

      if (yaCalificado != null) {
        throw Exception('Ya calificaste a este usuario en este trabajo');
      }

      // Validar puntuación
      if (puntuacion < 1 || puntuacion > 5) {
        throw Exception('La puntuación debe estar entre 1 y 5');
      }

      // Crear calificación
      await _supabase.from('calificacion').insert({
        'id_publicacion': trabajoId,
        'id_receptor': idReceptor,
        'id_emisor': idEmisor,
        'rol_receptor': rolReceptor,
        'puntuacion': puntuacion,
        'comentario': comentario,
        'recomendacion': recomendacion,
        'fecha': DateTime.now().toIso8601String(),
      });

      // Actualizar promedio del receptor
      final nuevoPromedio = await _supabase.rpc(
        'calcular_promedio_calificaciones',
        params: {
          'p_id_usuario': idReceptor,
          'p_rol': rolReceptor,
        },
      );

      // ✅ Actualizar en la tabla correcta según el tipo de usuario
      final usuarioReceptor = await _supabase
          .from('usuario')
          .select('tipo_usuario')
          .eq('id_usuario', idReceptor)
          .single();

      if (usuarioReceptor['tipo_usuario'] == 'PERSONA') {
        await _supabase.from('usuario_persona').update({
          'puntaje_promedio': nuevoPromedio,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id_usuario', idReceptor);
      } else {
        await _supabase.from('usuario_empresa').update({
          'puntaje_promedio': nuevoPromedio,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id_usuario', idReceptor);
      }

      print('✅ Calificación creada y promedio actualizado');
    } catch (e) {
      print('❌ Error en crearCalificacion: $e');
      rethrow;
    }
  }

  // ✅ 2. Obtener calificaciones pendientes
  static Future<List<CalificacionPendiente>>
      obtenerCalificacionesPendientes() async {
    try {
      print('🔍 Obteniendo calificaciones pendientes...');

      final userData = await AuthService.getCurrentUserData();
      if (userData == null) {
        print('❌ Usuario no autenticado');
        throw Exception('Usuario no autenticado');
      }

      print('✅ Usuario ID: ${userData.idUsuario}');

      final response = await _supabase.rpc(
        'obtener_calificaciones_pendientes',
        params: {'p_id_usuario': userData.idUsuario},
      ) as List<dynamic>;

      print('✅ Respuesta RPC: ${response.length} pendientes');

      final pendientes = response
          .map((item) =>
              CalificacionPendiente.fromJson(item as Map<String, dynamic>))
          .toList();

      print('✅ Calificaciones pendientes: ${pendientes.length}');

      return pendientes;
    } catch (e) {
      print('❌ Error en obtenerCalificacionesPendientes: $e');
      return [];
    }
  }

  // ✅ 3. Verificar si tiene calificaciones pendientes
  static Future<bool> tieneCalificacionesPendientes() async {
    try {
      print('🔍 tieneCalificacionesPendientes() llamado');

      final pendientes = await obtenerCalificacionesPendientes();
      final tiene = pendientes.isNotEmpty;

      print('📊 ¿Tiene pendientes?: $tiene (${pendientes.length} pendientes)');

      return tiene;
    } catch (e) {
      print('❌ Error en tieneCalificacionesPendientes: $e');
      return false;
    }
  }

  // ✅ 4. Puede publicar trabajo (empleador)
  static Future<bool> puedePublicarTrabajo() async {
    try {
      final pendientes = await obtenerCalificacionesPendientes();

      // Verificar si tiene empleados pendientes de calificar
      final empleadosPendientes =
          pendientes.where((p) => p.rolACalificar == 'EMPLEADO').toList();

      return empleadosPendientes.isEmpty;
    } catch (e) {
      print('❌ Error en puedePublicarTrabajo: $e');
      return true;
    }
  }

  // ✅ 5. Puede postularse (empleado)
  static Future<bool> puedePostularse() async {
    try {
      final pendientes = await obtenerCalificacionesPendientes();

      // Verificar si tiene empleadores pendientes de calificar
      final empleadoresPendientes =
          pendientes.where((p) => p.rolACalificar == 'EMPLEADOR').toList();

      return empleadoresPendientes.isEmpty;
    } catch (e) {
      print('❌ Error en puedePostularse: $e');
      return true;
    }
  }

  // ✅ 6. Obtener calificaciones recibidas por rol
  static Future<List<CalificacionModel>> obtenerCalificacionesPorRol({
    required int usuarioId,
    required String rol, // 'EMPLEADOR' o 'EMPLEADO'
  }) async {
    try {
      final response = await _supabase
          .from('calificacion')
          .select('''
            *,
            usuario_persona_receptor:usuario_persona!calificacion_id_receptor_fkey(*),
            usuario_empresa_receptor:usuario_empresa!calificacion_id_receptor_fkey(*),
            usuario_persona_emisor:usuario_persona!calificacion_id_emisor_fkey(*),
            usuario_empresa_emisor:usuario_empresa!calificacion_id_emisor_fkey(*)
          ''')
          .eq('id_receptor', usuarioId)
          .eq('rol_receptor', rol)
          .order('fecha', ascending: false);

      return (response as List)
          .map((item) =>
              CalificacionModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error en obtenerCalificacionesPorRol: $e');
      return [];
    }
  }

  // ✅ 7. Obtener promedio por rol
  static Future<double> obtenerPromedioPorRol({
    required int usuarioId,
    required String rol,
  }) async {
    try {
      final promedio = await _supabase.rpc(
        'calcular_promedio_calificaciones',
        params: {
          'p_id_usuario': usuarioId,
          'p_rol': rol,
        },
      );

      return (promedio as num).toDouble();
    } catch (e) {
      print('❌ Error en obtenerPromedioPorRol: $e');
      return 0.0;
    }
  }

  // ✅ 8. Obtener estadísticas completas
  static Future<Map<String, dynamic>> obtenerEstadisticasReputacion(
      int usuarioId) async {
    try {
      final promedioEmpleador = await obtenerPromedioPorRol(
        usuarioId: usuarioId,
        rol: 'EMPLEADOR',
      );

      final promedioEmpleado = await obtenerPromedioPorRol(
        usuarioId: usuarioId,
        rol: 'EMPLEADO',
      );

      final calificacionesEmpleador = await obtenerCalificacionesPorRol(
        usuarioId: usuarioId,
        rol: 'EMPLEADOR',
      );

      final calificacionesEmpleado = await obtenerCalificacionesPorRol(
        usuarioId: usuarioId,
        rol: 'EMPLEADO',
      );

      return {
        'promedio_empleador': promedioEmpleador,
        'promedio_empleado': promedioEmpleado,
        'total_calificaciones_empleador': calificacionesEmpleador.length,
        'total_calificaciones_empleado': calificacionesEmpleado.length,
        'calificaciones_empleador': calificacionesEmpleador,
        'calificaciones_empleado': calificacionesEmpleado,
      };
    } catch (e) {
      print('❌ Error en obtenerEstadisticasReputacion: $e');
      return {
        'promedio_empleador': 0.0,
        'promedio_empleado': 0.0,
        'total_calificaciones_empleador': 0,
        'total_calificaciones_empleado': 0,
        'calificaciones_empleador': [],
        'calificaciones_empleado': [],
      };
    }
  }

  // ✅ 9. Verificar si ya calificó en un trabajo
  static Future<bool> yaCalificoEnTrabajo({
    required int trabajoId,
    required int idReceptor,
  }) async {
    try {
      final userData = await AuthService.getCurrentUserData();
      if (userData == null) return false;

      final calificacion = await _supabase
          .from('calificacion')
          .select()
          .eq('id_publicacion', trabajoId)
          .eq('id_emisor', userData.idUsuario)
          .eq('id_receptor', idReceptor)
          .maybeSingle();

      return calificacion != null;
    } catch (e) {
      print('❌ Error en yaCalificoEnTrabajo: $e');
      return false;
    }
  }

  // ✅ 10. Obtener estadísticas completas por rol con desglose por rubro
  static Future<ReputacionStats> obtenerEstadisticasReputacionPorRol({
    required int usuarioId,
    required String rol,
  }) async {
    try {
      print('📊 ===== INICIO obtenerEstadisticasReputacionPorRol =====');
      print('📊 Usuario ID: $usuarioId');
      print('📊 Rol: $rol');

      // ✅ PASO 1: Obtener calificaciones básicas
      final calificaciones = await _supabase
          .from('calificacion')
          .select(
              'id_calificacion, puntuacion, comentario, recomendacion, fecha, id_emisor, id_publicacion')
          .eq('id_receptor', usuarioId)
          .eq('rol_receptor', rol)
          .order('fecha', ascending: false);

      print('📊 Total de calificaciones: ${calificaciones.length}');

      if (calificaciones.isEmpty) {
        print('⚠️ No se encontraron calificaciones');
        return ReputacionStats(
          promedioCalificaciones: 0.0,
          totalCalificaciones: 0,
          totalTrabajosFinalizados: 0,
          distribucionEstrellas: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
          comentariosRecientes: [],
          desglosePorRubro: null,
        );
      }

      // ✅ PASO 2: Calcular promedio
      double promedio = 0.0;
      final suma = calificaciones.fold<int>(
          0, (sum, cal) => sum + (cal['puntuacion'] as int));
      promedio = suma / calificaciones.length;
      print('📊 Promedio: $promedio');

      // ✅ PASO 3: Distribución de estrellas
      final distribucion = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      for (var cal in calificaciones) {
        final puntuacion = cal['puntuacion'] as int;
        distribucion[puntuacion] = (distribucion[puntuacion] ?? 0) + 1;
      }
      print('📊 Distribución: $distribucion');

      // ✅ PASO 4: Obtener trabajos finalizados
      int trabajosFinalizados = 0;
      if (rol == 'EMPLEADOR') {
        final trabajosResponse = await _supabase
            .from('trabajo')
            .select('id_trabajo')
            .eq('empleador_id', usuarioId)
            .eq('estado_publicacion', 'FINALIZADO');
        trabajosFinalizados = (trabajosResponse as List).length;
      } else {
        final trabajosResponse = await _supabase
            .from('postulacion')
            .select('trabajo_id, trabajo!inner(estado_publicacion)')
            .eq('postulante_id', usuarioId)
            .inFilter('estado', ['ACEPTADO', 'FINALIZADO'])
            .eq('trabajo.estado_publicacion', 'FINALIZADO');
        trabajosFinalizados = (trabajosResponse as List).length;
      }
      
      // ✅ PASO 5: Desglose por rubro
      // ✅ PASO 5: Desglose por rubro
      Map<String, ReputacionPorRubro> desglosePorRubro = {};

      for (var cal in calificaciones) {
        final idPublicacion = cal['id_publicacion'];

        // Obtener información del trabajo y su rubro
        final trabajo = await _supabase
            .from('trabajo')
            .select('titulo, id_rubro, rubro:id_rubro(nombre)')
            .eq('id_trabajo', idPublicacion)
            .maybeSingle();

        if (trabajo != null) {
          print('📋 Trabajo: ${trabajo['titulo']}');

          String nombreRubro = 'Sin rubro';
          final rubro = trabajo['rubro'];

          // ✅ MANEJO CORRECTO DE TIPOS
          if (rubro != null) {
            if (rubro is Map<String, dynamic>) {
              // Es un Map directo
              final nombre = rubro['nombre'];
              if (nombre != null && nombre is String) {
                nombreRubro = nombre;
                print('   ✅ Rubro (Map): $nombreRubro');
              }
            } else if (rubro is List && rubro.isNotEmpty) {
              // Es una lista
              final primerRubro = rubro[0];
              if (primerRubro is Map<String, dynamic>) {
                final nombre = primerRubro['nombre'];
                if (nombre != null && nombre is String) {
                  nombreRubro = nombre;
                  print('   ✅ Rubro (List): $nombreRubro');
                }
              }
            }
          }

          // Agrupar por rubro
          if (!desglosePorRubro.containsKey(nombreRubro)) {
            desglosePorRubro[nombreRubro] = ReputacionPorRubro(
              nombreRubro: nombreRubro,
              promedioCalificaciones: 0.0,
              totalCalificaciones: 0,
              totalTrabajosRealizados: 0,
            );
          }

          final stats = desglosePorRubro[nombreRubro]!;
          final nuevasCalificaciones = stats.totalCalificaciones + 1;
          final puntuacion = cal['puntuacion'] as int;
          final nuevoPromedio =
              ((stats.promedioCalificaciones * stats.totalCalificaciones) +
                      puntuacion) /
                  nuevasCalificaciones;

          desglosePorRubro[nombreRubro] = ReputacionPorRubro(
            nombreRubro: nombreRubro,
            promedioCalificaciones: nuevoPromedio,
            totalCalificaciones: nuevasCalificaciones,
            totalTrabajosRealizados: stats.totalTrabajosRealizados + 1,
          );

          print(
              '   ✅ Actualizado: ${nuevasCalificaciones} calificaciones, promedio ${nuevoPromedio.toStringAsFixed(1)}');
        }
      }

      print('📊 Desglose por rubro:');
      desglosePorRubro.forEach((key, value) {
        print(
            '   - $key: ${value.totalCalificaciones} calificaciones, promedio ${value.promedioCalificaciones.toStringAsFixed(1)}');
      });

      // ✅ PASO 6: Procesar comentarios
      // ✅ PASO 6: Procesar comentarios
      final comentarios = <ComentarioCalificacion>[];
      for (var cal in calificaciones) {
        if (cal['comentario'] != null &&
            (cal['comentario'] as String).isNotEmpty) {
          // Obtener info del emisor
          final emisor = await _supabase
              .from('usuario_persona')
              .select('nombre, apellido, foto_perfil_url')
              .eq('id_usuario', cal['id_emisor'])
              .maybeSingle();

          String nombreEmisor = 'Usuario';
          String? fotoEmisor;

          if (emisor != null) {
            nombreEmisor = '${emisor['nombre']} ${emisor['apellido']}';
            fotoEmisor = emisor['foto_perfil_url'];
          }

          // Obtener info del trabajo
          final trabajo = await _supabase
              .from('trabajo')
              .select('titulo, rubro:id_rubro(nombre)')
              .eq('id_trabajo', cal['id_publicacion'])
              .maybeSingle();

          String? tituloTrabajo;
          String? nombreRubro;

          if (trabajo != null) {
            tituloTrabajo = trabajo['titulo'] as String?;
            final rubro = trabajo['rubro'];

            // ✅ MANEJO CORRECTO DE TIPOS
            if (rubro != null) {
              if (rubro is Map<String, dynamic>) {
                final nombre = rubro['nombre'];
                if (nombre != null && nombre is String) {
                  nombreRubro = nombre;
                }
              } else if (rubro is List && rubro.isNotEmpty) {
                final primerRubro = rubro[0];
                if (primerRubro is Map<String, dynamic>) {
                  final nombre = primerRubro['nombre'];
                  if (nombre != null && nombre is String) {
                    nombreRubro = nombre;
                  }
                }
              }
            }
          }

          comentarios.add(ComentarioCalificacion(
            idCalificacion: cal['id_calificacion'] as int,
            nombreEmisor: nombreEmisor,
            fotoEmisor: fotoEmisor,
            puntuacion: cal['puntuacion'] as int,
            comentario: cal['comentario'] as String?,
            recomendacion: (cal['recomendacion'] as bool?) ?? false,
            fecha: DateTime.parse(cal['fecha'] as String),
            tituloTrabajo: tituloTrabajo,
            nombreRubro: nombreRubro,
          ));
        }
      }

      print('📊 Comentarios procesados: ${comentarios.length}');
      print('📊 ===== FIN obtenerEstadisticasReputacionPorRol =====');

      print('📊 Comentarios procesados: ${comentarios.length}');
      print('📊 ===== FIN obtenerEstadisticasReputacionPorRol =====');

      return ReputacionStats(
        promedioCalificaciones: promedio,
        totalCalificaciones: calificaciones.length,
        totalTrabajosFinalizados: trabajosFinalizados,
        distribucionEstrellas: distribucion,
        comentariosRecientes: comentarios.take(10).toList(),
        desglosePorRubro: desglosePorRubro.isNotEmpty ? desglosePorRubro : null,
      );
    } catch (e, stackTrace) {
      print('❌ Error en obtenerEstadisticasReputacionPorRol: $e');
      print('❌ Stack trace: $stackTrace');
      return ReputacionStats(
        promedioCalificaciones: 0.0,
        totalCalificaciones: 0,
        totalTrabajosFinalizados: 0,
        distribucionEstrellas: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
        comentariosRecientes: [],
        desglosePorRubro: null,
      );
    }
  }

// ✅ 11. Obtener calificación recibida en un trabajo específico
  static Future<Map<String, dynamic>?> obtenerCalificacionRecibidaEnTrabajo({
    required int trabajoId,
    required int idUsuario,
  }) async {
    try {
      final calificacion = await _supabase
          .from('calificacion')
          .select('puntuacion, comentario, fecha')
          .eq('id_publicacion', trabajoId)
          .eq('id_receptor', idUsuario)
          .maybeSingle();

      return calificacion;
    } catch (e) {
      print('❌ Error en obtenerCalificacionRecibidaEnTrabajo: $e');
      return null;
    }
  }

}
