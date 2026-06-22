// lib/models/menu_perfil/baja_cuenta_model.dart

class BajaCuentaInfo {
  final String estado;
  final bool suspendido;
  final double? promedioAlMomento;
  final int? totalCalificaciones;
  final String? rolAfectado;
  final DateTime? fechaBaja;
  final String? motivo;

  BajaCuentaInfo({
    required this.estado,
    required this.suspendido,
    this.promedioAlMomento,
    this.totalCalificaciones,
    this.rolAfectado,
    this.fechaBaja,
    this.motivo,
  });

  factory BajaCuentaInfo.fromJson(Map<String, dynamic> json) {
    return BajaCuentaInfo(
      estado: json['estado'] ?? 'ACTIVO',
      suspendido: json['suspendido'] ?? false,
      promedioAlMomento: json['promedio_al_momento'] != null
          ? (json['promedio_al_momento'] as num).toDouble()
          : null,
      totalCalificaciones: json['total_calificaciones'] as int?,
      rolAfectado: json['rol_afectado'] as String?,
      fechaBaja: json['fecha_baja'] != null
          ? DateTime.parse(json['fecha_baja'] as String)
          : null,
      motivo: json['motivo'] as String?,
    );
  }

  /// Mensaje amigable para mostrar al usuario
  String get mensajeUsuario {
    if (!suspendido) return '';

    final rolTexto = rolAfectado == 'EMPLEADOR' ? 'empleador' : 'empleado';
    final cantidadTexto = totalCalificaciones?.toString() ?? '?';

    return 'Tu cuenta fue suspendida porque acumulaste '
        '$cantidadTexto calificaciones negativas como $rolTexto. '
        'Contactá a un administrador para solicitar la reactivación.';
  }

  /// Fecha formateada para mostrar
  String get fechaBajaFormateada {
    if (fechaBaja == null) return '';
    return '${fechaBaja!.day}/${fechaBaja!.month}/${fechaBaja!.year}';
  }
}