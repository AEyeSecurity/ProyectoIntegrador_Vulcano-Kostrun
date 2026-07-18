//lib/models/notificacion_model.dartimport 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class Notificacion {
  final int idNotificacion;
  final int idUsuario;
  final String titulo;
  final String mensaje;
  final TipoNotificacion tipo;
  final EstadoNotificacion estado;
  final DateTime fecha;
  final Map<String, dynamic>? datosAdicionales;

  Notificacion({
    required this.idNotificacion,
    required this.idUsuario,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.estado,
    required this.fecha,
    this.datosAdicionales,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      idNotificacion: json['id_notificacion'] as int,
      idUsuario: json['id_usuario'] as int,
      titulo: json['titulo'] as String,
      mensaje: json['mensaje'] as String,
      tipo: TipoNotificacion.fromString(json['tipo'] as String),
      estado: EstadoNotificacion.fromString(json['estado'] as String),
      fecha: DateTime.parse(json['fecha'] as String).toLocal(),
      datosAdicionales: json['datos_adicionales'] as Map<String, dynamic>?,
    );
  }

  // Helper: Saber si está no leída
  bool get noLeida => estado == EstadoNotificacion.noLeida;

  // Helper: Obtener ícono según tipo
  IconData get icono {
    switch (tipo) {
      case TipoNotificacion.mensaje:
        return Icons.message;
      case TipoNotificacion.postulacion:
        return Icons.work;
      case TipoNotificacion.trabajo:
        return Icons.schedule;
      case TipoNotificacion.calificacion:
        return Icons.star;
      case TipoNotificacion.sistema:
        return Icons.info;
    }
  }

  // Helper: Obtener color según tipo
  Color get color {
    switch (tipo) {
      case TipoNotificacion.mensaje:
        return Colors.blue;
      case TipoNotificacion.postulacion:
        return const Color(0xFFC5414B);
      case TipoNotificacion.trabajo:
        return Colors.purple;
      case TipoNotificacion.calificacion:
        return Colors.amber;
      case TipoNotificacion.sistema:
        return Colors.grey;
    }
  }

  // Helper: Formatear fecha relativa
  String get fechaRelativa {
    final now = DateTime.now();
    final difference = now.difference(fecha);

    if (difference.inSeconds < 60) {
      return 'Hace un momento';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return 'Hace $minutes ${minutes == 1 ? 'minuto' : 'minutos'}';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'Hace $hours ${hours == 1 ? 'hora' : 'horas'}';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return 'Hace $days ${days == 1 ? 'día' : 'días'}';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }
}

// ENUM: Tipos de notificación
enum TipoNotificacion {
  mensaje,
  postulacion,
  trabajo,
  calificacion,
  sistema;

  static TipoNotificacion fromString(String value) {
    switch (value.toUpperCase()) {
      case 'MENSAJE':
        return TipoNotificacion.mensaje;
      case 'POSTULACION':
        return TipoNotificacion.postulacion;
      case 'TRABAJO':
        return TipoNotificacion.trabajo;
      case 'CALIFICACION':
        return TipoNotificacion.calificacion;
      case 'SISTEMA':
        return TipoNotificacion.sistema;
      default:
        return TipoNotificacion.sistema;
    }
  }
}

// ENUM: Estados de notificación
enum EstadoNotificacion {
  noLeida,
  leida;

  static EstadoNotificacion fromString(String value) {
    return value.toUpperCase() == 'LEIDA'
        ? EstadoNotificacion.leida
        : EstadoNotificacion.noLeida;
  }

  String toDb() {
    return this == EstadoNotificacion.leida ? 'LEIDA' : 'NO_LEIDA';
  }
}