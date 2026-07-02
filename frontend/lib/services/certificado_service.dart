import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

class CertificadoService {
  final SupabaseClient _client = Supabase.instance.client;

  // ─── Subir certificado ───
Future<bool> subirCertificado({
    required int usuarioId,
    required int rubroId,
    required String filePath,
    required String fileName,
    required bool esPdf,
  }) async {
    try {
      final extension = esPdf ? 'pdf' : fileName.split('.').last;
      final storagePath = '$usuarioId/${rubroId}_${DateTime.now().millisecondsSinceEpoch}.$extension';

      await _client.storage.from('certificados').upload(
        storagePath,
        File(filePath),
        fileOptions: FileOptions(
          contentType: esPdf ? 'application/pdf' : 'image/$extension',
        ),
      );

      await _client.rpc('insertar_certificado', params: {
        'p_usuario_id': usuarioId,
        'p_rubro_id': rubroId,
        'p_archivo_url': storagePath,
        'p_archivo_tipo': esPdf ? 'pdf' : 'imagen',
      });

      return true;
    } catch (e) {
      print('Error al subir certificado: $e');
      return false;
    }
  }

  // ─── Subir certificado desde bytes (para web) ───
Future<bool> subirCertificadoBytes({
    required int usuarioId,
    required int rubroId,
    required Uint8List fileBytes,
    required String fileName,
    required bool esPdf,
  }) async {
    try {
      final extension = esPdf ? 'pdf' : fileName.split('.').last;
      final storagePath = '$usuarioId/${rubroId}_${DateTime.now().millisecondsSinceEpoch}.$extension';

      await _client.storage.from('certificados').uploadBinary(
        storagePath,
        fileBytes,
        fileOptions: FileOptions(
          contentType: esPdf ? 'application/pdf' : 'image/$extension',
        ),
      );

      // Insertar/actualizar via RPC
      await _client.rpc('insertar_certificado', params: {
        'p_usuario_id': usuarioId,
        'p_rubro_id': rubroId,
        'p_archivo_url': storagePath,
        'p_archivo_tipo': esPdf ? 'pdf' : 'imagen',
      });

      return true;
    } catch (e) {
      print('Error al subir certificado (web): $e');
      return false;
    }
  }

  // ─── Obtener MIS certificados (todos los estados) ───
Future<List<Map<String, dynamic>>> obtenerMisCertificados(int usuarioId) async {
    try {
      final response = await _client.rpc('obtener_mis_certificados', params: {
        'p_usuario_id': usuarioId,
      });

      final List<Map<String, dynamic>> certificados = List<Map<String, dynamic>>.from(response);

      // Traer nombre del rubro para cada certificado
      for (var cert in certificados) {
        final rubro = await _client
            .from('rubro')
            .select('id_rubro, nombre')
            .eq('id_rubro', cert['rubro_id'])
            .maybeSingle();

        cert['rubro'] = rubro;
      }

      return certificados;
    } catch (e) {
      print('Error al obtener certificados: $e');
      return [];
    }
  }

  // ─── Obtener certificados VERIFICADOS de un usuario (para perfil público) ───
  Future<List<Map<String, dynamic>>> obtenerCertificadosVerificados(int usuarioId) async {
    try {
      final response = await _client.rpc('obtener_certificados_verificados', params: {
        'p_usuario_id': usuarioId,
      });

      final List<Map<String, dynamic>> certificados = List<Map<String, dynamic>>.from(response);

      for (var cert in certificados) {
        final rubro = await _client
            .from('rubro')
            .select('id_rubro, nombre')
            .eq('id_rubro', cert['rubro_id'])
            .maybeSingle();
        cert['rubro'] = rubro;
      }

      return certificados;
    } catch (e) {
      print('Error al obtener certificados verificados: $e');
      return [];
    }
  }

  // ─── Verificar si tiene certificado verificado para un rubro específico ───
  // (para mostrar badge en postulaciones)
  Future<bool> tieneCertificadoVerificado(int usuarioId, int rubroId) async {
    try {
      final response = await _client
          .from('certificado_matriculacion')
          .select('id')
          .eq('usuario_id', usuarioId)
          .eq('rubro_id', rubroId)
          .eq('estado', 'VERIFICADO')
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error al verificar certificado: $e');
      return false;
    }
  }

  // ─── Obtener URL firmada para ver el archivo (privado) ───
  Future<String?> obtenerUrlArchivo(String archivoUrl) async {
    try {
      final response = await _client.storage
          .from('certificados')
          .createSignedUrl(archivoUrl, 60 * 5); // 5 minutos de validez
      return response;
    } catch (e) {
      print('Error al obtener URL del archivo: $e');
      return null;
    }
  }

  // ─── ADMIN: Obtener certificados pendientes ───
  Future<List<Map<String, dynamic>>> obtenerCertificadosPendientes() async {
    try {
      final response = await _client
          .from('certificado_matriculacion')
          .select('*, rubro:rubro_id(id_rubro, nombre)')
          .eq('estado', 'PENDIENTE')
          .order('fecha_subida', ascending: true);

      // Traer datos del usuario para cada certificado
      final List<Map<String, dynamic>> certificados = List<Map<String, dynamic>>.from(response);

      for (var cert in certificados) {
        final usuario = await _client
            .from('usuario_persona')
            .select('nombre, apellido, username')
            .eq('id_usuario', cert['usuario_id'])
            .maybeSingle();

        cert['usuario_nombre'] = usuario != null
            ? '${usuario['nombre']} ${usuario['apellido']}'
            : 'Usuario desconocido';
        cert['usuario_username'] = usuario?['username'] ?? '';
      }

      return certificados;
    } catch (e) {
      print('Error al obtener certificados pendientes: $e');
      return [];
    }
  }

  // ─── ADMIN: Aprobar certificado ───
  Future<bool> aprobarCertificado(int certificadoId, int adminUsuarioId) async {
    try {
      await _client.from('certificado_matriculacion').update({
        'estado': 'VERIFICADO',
        'fecha_revision': DateTime.now().toIso8601String(),
        'revisado_por': adminUsuarioId,
        'motivo_rechazo': null,
      }).eq('id', certificadoId);

      return true;
    } catch (e) {
      print('Error al aprobar certificado: $e');
      return false;
    }
  }

  // ─── ADMIN: Rechazar certificado ───
  Future<bool> rechazarCertificado(int certificadoId, int adminUsuarioId, String motivo) async {
    try {
      await _client.from('certificado_matriculacion').update({
        'estado': 'RECHAZADO',
        'fecha_revision': DateTime.now().toIso8601String(),
        'revisado_por': adminUsuarioId,
        'motivo_rechazo': motivo,
      }).eq('id', certificadoId);

      return true;
    } catch (e) {
      print('Error al rechazar certificado: $e');
      return false;
    }
  }
}