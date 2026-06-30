// lib/screens/jobs/detalle_trabajo_propio_screen.dart
// 🟢 PANTALLA PARA TUS TRABAJOS PUBLICADOS (PROPIOS)

import 'package:flutter/material.dart';
import '../../models/menu_perfil/trabajo_model.dart';
import '../../services/postulacion_service.dart';
import '../../theme/estado_trabajo_style.dart';
import '../../services/menu_perfil/trabajo_foto_service.dart';
import '../../models/menu_perfil/trabajo_foto_model.dart';
import '../../services/ubicacion_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DetalleTrabajoPropio extends StatefulWidget {
  final TrabajoModel trabajo;

  const DetalleTrabajoPropio({
    Key? key,
    required this.trabajo,
  }) : super(key: key);

  @override
  State<DetalleTrabajoPropio> createState() => _DetalleTrabajoPropioState();
}

final TrabajoFotoService _fotoService = TrabajoFotoService();
List<TrabajoFoto> _fotos = [];
bool _loadingFotos = true;

class _DetalleTrabajoPropioState extends State<DetalleTrabajoPropio> {
  int _cantidadPostulaciones = 0;
  bool _isLoading = true;
final UbicacionService _ubicacionService = UbicacionService();
  Map<String, dynamic>? _ubicacionData;
  bool _cargandoUbicacion = true;

  @override
  void initState() {
    super.initState();
    _cargarPostulaciones();
    _cargarFotos();
    _cargarUbicacion();
  }

  Future<void> _cargarPostulaciones() async {
    setState(() => _isLoading = true);
    try {
      final postulaciones = await PostulacionService.getPostulacionesDeTrabajo(
        widget.trabajo.id,
      );
      setState(() {
        _cantidadPostulaciones = postulaciones.length;
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando postulaciones: $e');
      setState(() => _isLoading = false);
    }
  }
  // Agregar este método después de _cargarPostulaciones() (línea ~46):

  Future<void> _confirmarEliminacion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar trabajo'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar este trabajo? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      try {
        // TODO: Implementar eliminación en el servicio
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Trabajo eliminado'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cargarFotos() async {
    final fotos = await _fotoService.obtenerFotosTrabajo(widget.trabajo.id);
    if (mounted) {
      setState(() {
        _fotos = fotos;
        _loadingFotos = false;
      });
    }
  }

  Future<void> _cargarUbicacion() async {
    try {
      if (widget.trabajo.ubicacionId != null) {
        final ubicacion = await _ubicacionService
            .obtenerUbicacionConCoordenadas(widget.trabajo.ubicacionId!);
        if (mounted) {
          setState(() {
            _ubicacionData = ubicacion;
            _cargandoUbicacion = false;
          });
        }
      } else {
        setState(() => _cargandoUbicacion = false);
      }
    } catch (e) {
      print('Error cargando ubicación: $e');
      if (mounted) setState(() => _cargandoUbicacion = false);
    }
  }

// Agregar este widget en cualquier parte de la clase (antes del build):

  Widget _buildGaleriaFotos() {
    if (_loadingFotos) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5414B)),
        ),
      );
    }

    if (_fotos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Fotos del trabajo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _fotos.length,
            itemBuilder: (context, index) {
              final foto = _fotos[index];
              return Container(
                width: 150,
                margin: const EdgeInsets.only(right: 12),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        foto.fotoUrl,
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFC5414B),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child:
                                  Icon(Icons.error_outline, color: Colors.red),
                            ),
                          );
                        },
                      ),
                    ),
                    if (foto.esPrincipal)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC5414B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'PRINCIPAL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBotonGestionarFotos() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/gestionar-fotos-trabajo',
            arguments: widget.trabajo.id,
          ).then((_) {
            _cargarFotos();
          });
        },
        icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
        label: Text(
          _fotos.isEmpty
              ? 'Agregar Fotos'
              : 'Gestionar Fotos (${_fotos.length}/5)',
          style: const TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC5414B),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }

  String _getPeriodoPagoLabel(String? periodo) {
    switch (periodo?.toUpperCase()) {
      case 'POR_HORA':
        return 'por hora';
      case 'POR_DIA':
        return 'por día';
      case 'POR_TRABAJO':
        return 'por trabajo completo';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC5414B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mi Trabajo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
              // Navegar a pantalla de edición
              final resultado = await Navigator.pushNamed(
                context,
                '/editar-trabajo',
                arguments: widget.trabajo,
              );

              // Si se editó, recargar
              if (resultado == true && mounted) {
                Navigator.pop(context, true); // Volver y actualizar lista
              }
            },
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Eliminar', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Función $value próximamente')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageSection(),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 16),
                        _buildBotonGestionarFotos(),
                        _buildGaleriaFotos(),
                        const SizedBox(height: 20),
                        _buildQuickStats(),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),
                        _buildSection(
                          '📝 Descripción',
                          widget.trabajo.descripcion,
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),
                        _buildFechasHorarios(),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),
                        _buildDetallesPago(),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),
                        _buildUbicacion(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    // Buscar la foto principal
    TrabajoFoto? fotoPrincipal;

    try {
      fotoPrincipal = _fotos.firstWhere((f) => f.esPrincipal);
    } catch (e) {
      // Si no hay foto principal, tomar la primera si existe
      fotoPrincipal = _fotos.isNotEmpty ? _fotos.first : null;
    }

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        image: fotoPrincipal != null
            ? DecorationImage(
                image: NetworkImage(fotoPrincipal.fotoUrl),
                fit: BoxFit.cover,
              )
            : (widget.trabajo.imagenUrl != null
                ? DecorationImage(
                    image: NetworkImage(widget.trabajo.imagenUrl!),
                    fit: BoxFit.cover,
                  )
                : null),
      ),
      child: fotoPrincipal == null && widget.trabajo.imagenUrl == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, size: 64, color: Colors.grey[500]),
                  const SizedBox(height: 8),
                  Text(
                    'Sin imagen',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    final style =
        EstadoTrabajoStyle.fromEstado(widget.trabajo.estadoPublicacion);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.trabajo.titulo,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: style.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: style.color.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.trabajo.estadoIcono,
                      size: 16, color: style.color),
                  const SizedBox(width: 4),
                  Text(
                    widget.trabajo.estadoTexto,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: style.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.business, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              widget.trabajo.nombreRubro ?? '',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.location_on, size: 16, color: Color(0xFFC5414B)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.trabajo.direccionCompleta ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatChip(
            icon: Icons.payments,
            label: widget.trabajo.salario != null
                ? '\$${widget.trabajo.salario!.toStringAsFixed(0)}'
                : 'A convenir',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatChip(
            icon: Icons.people,
            label: '${widget.trabajo.cantidadEmpleadosRequeridos ?? 1}',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatChip(
            icon: Icons.schedule,
            label: _getDiasRestantes(),
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getDiasRestantes() {
    if (widget.trabajo.fechaInicio == null) return 'N/A';

    final now = DateTime.now();
    final inicio = widget.trabajo.fechaInicio;
    final diferencia = inicio.difference(now).inDays;

    if (diferencia == 0) return 'Hoy';
    if (diferencia == 1) return 'Mañana';
    if (diferencia < 0) return 'Iniciado';
    return 'En $diferencia días';
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFechasHorarios() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📅 Fechas y Horarios',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
            Icons.calendar_today,
            'Fecha inicio',
            widget.trabajo.fechaInicio != null
                ? _formatDate(widget.trabajo.fechaInicio)
                : 'No especificada'),
        _buildInfoRow(
            Icons.event,
            'Fecha fin',
            widget.trabajo.fechaFin != null
                ? _formatDate(widget.trabajo.fechaFin!)
                : 'No especificada'),
        _buildInfoRow(Icons.access_time, 'Horario',
            '${widget.trabajo.horarioInicio ?? 'N/A'} - ${widget.trabajo.horarioFin ?? 'N/A'}'),
      ],
    );
  }

  Widget _buildDetallesPago() {
    final cantidadPersonas = widget.trabajo.cantidadEmpleadosRequeridos ?? 1;
    final esPorPersona = cantidadPersonas > 1;

    String salarioText;
    if (widget.trabajo.salario != null) {
      final monto = widget.trabajo.salario!.toStringAsFixed(0);
      final periodo = _getPeriodoPagoLabel(widget.trabajo.periodoPago);

      if (esPorPersona) {
        salarioText = '\$$monto $periodo por persona';
      } else {
        salarioText = '\$$monto $periodo';
      }
    } else {
      salarioText = 'A convenir';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💵 Detalles de Pago',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoRow(Icons.payments, 'Salario', salarioText),
        if (esPorPersona && widget.trabajo.salario != null)
          _buildInfoRow(
            Icons.calculate,
            'Total estimado (${cantidadPersonas} personas)',
            '\$${(widget.trabajo.salario! * cantidadPersonas).toStringAsFixed(0)} ${_getPeriodoPagoLabel(widget.trabajo.periodoPago)}',
          ),
        _buildInfoRow(
          Icons.payment,
          'Método de pago',
          widget.trabajo.metodoPago ?? 'No especificado',
        ),
        _buildInfoRow(
          Icons.people,
          'Personas necesarias',
          '$cantidadPersonas',
        ),
      ],
    );
  }

Widget _buildUbicacion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📍 Ubicación',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.trabajo.direccionCompleta ?? '',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              if (_cargandoUbicacion)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                )
              else if (_ubicacionData != null &&
                  _ubicacionData!['latitud'] != null &&
                  _ubicacionData!['longitud'] != null)
                SizedBox(
                  height: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          _ubicacionData!['latitud'],
                          _ubicacionData!['longitud'],
                        ),
                        zoom: 15,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('trabajo'),
                          position: LatLng(
                            _ubicacionData!['latitud'],
                            _ubicacionData!['longitud'],
                          ),
                          infoWindow: InfoWindow(
                            title: 'Tu publicación',
                            snippet: widget.trabajo.direccionCompleta ?? '',
                          ),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed,
                          ),
                        ),
                      },
                      myLocationEnabled: false,
                      zoomControlsEnabled: true,
                      mapToolbarEnabled: false,
                    ),
                  ),
                )
              else
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text('Ubicación no disponible',
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFFC5414B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🟢 BOTONES DE ACCIÓN PARA TRABAJOS PROPIOS
  Widget _buildActionButtons() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: const SafeArea(
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5414B)),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador de postulaciones
            if (_cantidadPostulaciones > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFC5414B).withOpacity(0.1),
                      const Color(0xFFE85A4F).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFC5414B).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC5414B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_cantidadPostulaciones',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _cantidadPostulaciones == 1
                                ? 'Nueva postulación'
                                : 'Nuevas postulaciones',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Personas interesadas en tu trabajo',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFFC5414B),
                    ),
                  ],
                ),
              ),

            // Botón principal
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/postulaciones-trabajo',
                  arguments: widget.trabajo.id,
                );
              },
              icon: const Icon(Icons.people),
              label: Text(
                _cantidadPostulaciones > 0
                    ? 'Ver postulaciones ($_cantidadPostulaciones)'
                    : 'Sin postulaciones aún',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC5414B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
