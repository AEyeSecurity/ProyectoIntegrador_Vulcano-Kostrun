// lib/models/postulacion_model.dart

class PostulacionModel {
  final int id;
  final int trabajoId;
  final int postulanteId;
  final int? empleadoEmpresaId;
  final String estado;
  final String? mensaje;
  final double? ofertaPago;
  final DateTime fechaPostulacion;
  final DateTime? fechaRespuesta;
  final DateTime? fechaCancelacion;
  final DateTime createdAt;
  final DateTime updatedAt;

  final TrabajoInfo? trabajo;
  final PostulanteInfo? postulante;

  PostulacionModel({
    required this.id,
    required this.trabajoId,
    required this.postulanteId,
    this.empleadoEmpresaId,
    required this.estado,
    this.mensaje,
    this.ofertaPago,
    required this.fechaPostulacion,
    this.fechaRespuesta,
    this.fechaCancelacion,
    required this.createdAt,
    required this.updatedAt,
    this.trabajo,
    this.postulante,
  });

  factory PostulacionModel.fromJson(Map<String, dynamic> json) {
    return PostulacionModel(
      id: json['id_postulacion'] ?? 0,
      trabajoId: json['trabajo_id'] ?? 0,
      postulanteId: json['postulante_id'] ?? 0,
      empleadoEmpresaId: json['empleado_empresa_id'],
      estado: json['estado'] ?? 'PENDIENTE',
      mensaje: json['mensaje'],
      ofertaPago: json['oferta_pago']?.toDouble(),
      fechaPostulacion: json['fecha_postulacion'] != null
          ? DateTime.parse(json['fecha_postulacion'])
          : DateTime.now(),
      fechaRespuesta: json['fecha_respuesta'] != null
          ? DateTime.parse(json['fecha_respuesta'])
          : null,
      fechaCancelacion: json['fecha_cancelacion'] != null
          ? DateTime.parse(json['fecha_cancelacion'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      trabajo: json['trabajo'] != null
          ? TrabajoInfo.fromJson(json['trabajo'])
          : null,
      postulante: json['postulante'] != null
          ? PostulanteInfo.fromJson(json['postulante'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_postulacion': id,
      'trabajo_id': trabajoId,
      'postulante_id': postulanteId,
      'empleado_empresa_id': empleadoEmpresaId,
      'estado': estado,
      'mensaje': mensaje,
      'oferta_pago': ofertaPago,
      'fecha_postulacion': fechaPostulacion.toIso8601String(),
      'fecha_respuesta': fechaRespuesta?.toIso8601String(),
      'fecha_cancelacion': fechaCancelacion?.toIso8601String(),
    };
  }

  String getEstadoColor() {
    switch (estado.toUpperCase()) {
      case 'PENDIENTE':
        return '#FFA500';
      case 'ACEPTADO':
        return '#4CAF50';
      case 'RECHAZADO':
        return '#F44336';
      case 'CANCELADO':
        return '#9E9E9E';
      default:
        return '#9E9E9E';
    }
  }

  String getEstadoLabel() {
    switch (estado.toUpperCase()) {
      case 'PENDIENTE':
        return 'Pendiente';
      case 'ACEPTADO':
        return 'Aceptado';
      case 'RECHAZADO':
        return 'Rechazado';
      case 'CANCELADO':
        return 'Cancelado';
      default:
        return estado;
    }
  }

  bool puedeCancelarse() {
    return estado.toUpperCase() == 'PENDIENTE' ||
        estado.toUpperCase() == 'ACEPTADO';
  }

  // ✅ NUEVO: Getter para acceder al nombre con empresa
  String? get nombreConEmpresa {
    return postulante?.nombreConEmpresa;
  }

  PostulacionModel copyWith({
    int? id,
    int? trabajoId,
    int? postulanteId,
    int? empleadoEmpresaId,
    String? estado,
    String? mensaje,
    double? ofertaPago,
    DateTime? fechaPostulacion,
    DateTime? fechaRespuesta,
    DateTime? fechaCancelacion,
    DateTime? createdAt,
    DateTime? updatedAt,
    TrabajoInfo? trabajo,
    PostulanteInfo? postulante,
  }) {
    return PostulacionModel(
      id: id ?? this.id,
      trabajoId: trabajoId ?? this.trabajoId,
      postulanteId: postulanteId ?? this.postulanteId,
      empleadoEmpresaId: empleadoEmpresaId ?? this.empleadoEmpresaId,
      estado: estado ?? this.estado,
      mensaje: mensaje ?? this.mensaje,
      ofertaPago: ofertaPago ?? this.ofertaPago,
      fechaPostulacion: fechaPostulacion ?? this.fechaPostulacion,
      fechaRespuesta: fechaRespuesta ?? this.fechaRespuesta,
      fechaCancelacion: fechaCancelacion ?? this.fechaCancelacion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      trabajo: trabajo ?? this.trabajo,
      postulante: postulante ?? this.postulante,
    );
  }
}

// ========================================
// CLASE AUXILIAR: Información del Trabajo
// ========================================
class TrabajoInfo {
  final int id;
  final String titulo;
  final String descripcion;
  final double? salario;
  final String? fechaInicio;
  final String? fechaFin;
  final String? horarioInicio;
  final String? horarioFin;
  final int? cantidadEmpleadosRequeridos;
  final String nombreRubro;
  final String direccion;
  // ✅ NUEVO: Datos del empleador
  final int? empleadorId;
  final String? nombreEmpleador;
  final String? fotoEmpleador;

  TrabajoInfo({
    required this.id,
    required this.titulo,
    required this.descripcion,
    this.salario,
    this.fechaInicio,
    this.fechaFin,
    this.horarioInicio,
    this.horarioFin,
    this.cantidadEmpleadosRequeridos,
    required this.nombreRubro,
    required this.direccion,
    this.empleadorId,
    this.nombreEmpleador,
    this.fotoEmpleador,
  });

  factory TrabajoInfo.fromJson(Map<String, dynamic> json) {
    String direccion = 'Ubicación no disponible';
    if (json['ubicacion'] != null) {
      final ubi = json['ubicacion'];
      if (ubi is Map<String, dynamic>) {
        direccion = '${ubi['calle']} ${ubi['numero']}, ${ubi['ciudad']}';
      } else if (ubi is List && ubi.isNotEmpty) {
        final u = ubi[0];
        direccion = '${u['calle']} ${u['numero']}, ${u['ciudad']}';
      }
    }

    // ✅ NUEVO: Parsear datos del empleador
    String? nombreEmpleador;
    String? fotoEmpleador;
    int? empleadorId;

    if (json['empleador'] != null) {
      final emp = json['empleador'];
      if (emp is Map<String, dynamic>) {
        empleadorId = emp['id_usuario'];
        
        // Intentar persona primero
        final persona = emp['usuario_persona'];
        if (persona != null) {
          if (persona is List && persona.isNotEmpty) {
            nombreEmpleador = '${persona[0]['nombre']} ${persona[0]['apellido']}'.trim();
            fotoEmpleador = persona[0]['foto_perfil_url'];
          } else if (persona is Map<String, dynamic>) {
            nombreEmpleador = '${persona['nombre']} ${persona['apellido']}'.trim();
            fotoEmpleador = persona['foto_perfil_url'];
          }
        }
        
        // Si no hay persona, intentar empresa
        if (nombreEmpleador == null || nombreEmpleador.isEmpty) {
          final empresa = emp['usuario_empresa'];
          if (empresa != null) {
            if (empresa is List && empresa.isNotEmpty) {
              nombreEmpleador = empresa[0]['nombre_corporativo'];
            } else if (empresa is Map<String, dynamic>) {
              nombreEmpleador = empresa['nombre_corporativo'];
            }
          }
        }
      }
    }
    
    // Fallback: si no hay join de empleador, usar empleador_id del json
    empleadorId ??= json['empleador_id'];

    return TrabajoInfo(
      id: json['id_trabajo'] ?? 0,
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      salario: json['salario']?.toDouble(),
      fechaInicio: json['fecha_inicio'],
      fechaFin: json['fecha_fin'],
      horarioInicio: json['horario_inicio'],
      horarioFin: json['horario_fin'],
      cantidadEmpleadosRequeridos: json['cantidad_empleados_requeridos'],
      nombreRubro: json['rubro']?['nombre'] ?? 'Sin rubro',
      direccion: direccion,
      empleadorId: empleadorId,
      nombreEmpleador: nombreEmpleador,
      fotoEmpleador: fotoEmpleador,
    );
  }
}

// ========================================
// CLASE AUXILIAR: Información del Postulante
// ========================================
class PostulanteInfo {
  final int id;
  final String nombre;
  final String? fotoPerfil;
  final double? puntajePromedio;
  final bool esEmpresa;
  final String? nombreEmpresa;

  PostulanteInfo({
    required this.id,
    required this.nombre,
    this.fotoPerfil,
    this.puntajePromedio,
    required this.esEmpresa,
    this.nombreEmpresa,
  });

  factory PostulanteInfo.fromJson(Map<String, dynamic> json) {
    String nombre = 'Usuario';
    String? fotoPerfil;
    double? puntaje;
    bool esEmpresa = false;
    String? nombreEmpresa;

    try {
      print('🔍 PostulanteInfo - JSON completo: $json');

      // ✅ PRIMERO: Verificar si hay empleado_empresa (viene del padre, no del postulante)
      // Este campo viene directamente del SELECT de postulacion, NO de usuario
      if (json['empleado_empresa'] != null) {
        final empleadoData = json['empleado_empresa'];
        print('🔍 EMPLEADO_EMPRESA detectado: $empleadoData');

        if (empleadoData is Map<String, dynamic>) {
          final nombreEmpleado = empleadoData['nombre'] ?? '';
          final apellidoEmpleado = empleadoData['apellido'] ?? '';

          if (nombreEmpleado.isNotEmpty || apellidoEmpleado.isNotEmpty) {
            nombre = '$nombreEmpleado $apellidoEmpleado'.trim();
            fotoPerfil = empleadoData['foto_de_perfil'];
            esEmpresa = true;

            // Intentar obtener nombre de empresa del postulante
            if (json['usuario_empresa'] != null) {
              final empresaData = json['usuario_empresa'];
              if (empresaData is List && empresaData.isNotEmpty) {
                nombreEmpresa = empresaData[0]['nombre_corporativo'];
              } else if (empresaData is Map<String, dynamic>) {
                nombreEmpresa = empresaData['nombre_corporativo'];
              }
            }

            print('✅ Empleado de empresa detectado: $nombre de $nombreEmpresa');

            return PostulanteInfo(
              id: json['id_usuario'] ?? 0,
              nombre: nombre,
              fotoPerfil: fotoPerfil,
              puntajePromedio: puntaje,
              esEmpresa: esEmpresa,
              nombreEmpresa: nombreEmpresa,
            );
          }
        }
      }

      // ✅ SEGUNDO: Verificar usuario_persona
      if (json['usuario_persona'] != null) {
        final personaData = json['usuario_persona'];

        if (personaData is List && personaData.isNotEmpty) {
          final persona = personaData[0];
          if (persona is Map<String, dynamic>) {
            nombre = '${persona['nombre']} ${persona['apellido']}'.trim();
            fotoPerfil = persona['foto_perfil_url'];
            puntaje = persona['puntaje_promedio']?.toDouble();
            esEmpresa = false;
          }
        } else if (personaData is Map<String, dynamic>) {
          nombre = '${personaData['nombre']} ${personaData['apellido']}'.trim();
          fotoPerfil = personaData['foto_perfil_url'];
          puntaje = personaData['puntaje_promedio']?.toDouble();
          esEmpresa = false;
        }
      }
      // ✅ TERCERO: Si NO hay persona, verificar empresa
      else if (json['usuario_empresa'] != null) {
        final empresaData = json['usuario_empresa'];

        if (empresaData is List && empresaData.isNotEmpty) {
          final empresa = empresaData[0];
          if (empresa is Map<String, dynamic>) {
            nombreEmpresa = empresa['nombre_corporativo'] ?? 'Empresa';
            puntaje = empresa['puntaje_promedio']?.toDouble();
            nombre = nombreEmpresa ?? 'Empresa';
            esEmpresa = true;
          }
        } else if (empresaData is Map<String, dynamic>) {
          nombreEmpresa = empresaData['nombre_corporativo'] ?? 'Empresa';
          puntaje = empresaData['puntaje_promedio']?.toDouble();
          nombre = nombreEmpresa ?? 'Empresa';
          esEmpresa = true;
        }
      }
    } catch (e) {
      print('⚠️ Error parseando PostulanteInfo: $e');
    }

    return PostulanteInfo(
      id: json['id_usuario'] ?? 0,
      nombre: nombre,
      fotoPerfil: fotoPerfil,
      puntajePromedio: puntaje,
      esEmpresa: esEmpresa,
      nombreEmpresa: nombreEmpresa,
    );
  }

  String getIniciales() {
    if (nombre.isEmpty || nombre == 'Usuario') return '?';

    final palabras = nombre.split(' ');
    if (palabras.length >= 2 &&
        palabras[0].isNotEmpty &&
        palabras[1].isNotEmpty) {
      return '${palabras[0][0]}${palabras[1][0]}'.toUpperCase();
    }
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
  }

  String get nombreConEmpresa {
    if (nombreEmpresa != null && nombreEmpresa!.isNotEmpty) {
      return '$nombre ($nombreEmpresa)';
    }
    return nombre;
  }
}
