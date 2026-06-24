// lib/screens/menu_perfil/admin_solicitudes_screen.dart

import 'package:flutter/material.dart';
import '../../services/baja_cuenta_service.dart';

class AdminSolicitudesScreen extends StatefulWidget {
  const AdminSolicitudesScreen({Key? key}) : super(key: key);

  @override
  State<AdminSolicitudesScreen> createState() => _AdminSolicitudesScreenState();
}

class _AdminSolicitudesScreenState extends State<AdminSolicitudesScreen> {
  List<Map<String, dynamic>> _solicitudes = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
  }

  Future<void> _cargarSolicitudes() async {
    setState(() => _cargando = true);
    try {
      final solicitudes = await BajaCuentaService.obtenerSolicitudesPendientes();
      if (mounted) {
        setState(() {
          _solicitudes = solicitudes;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando solicitudes: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _aprobar(int idBaja, String nombreUsuario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar reactivación'),
        content: Text(
          '¿Estás seguro de reactivar la cuenta de $nombreUsuario?\n\n'
          'Se eliminarán sus calificaciones negativas y podrá volver a usar la app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sí, reactivar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final resultado = await BajaCuentaService.aprobarReactivacion(idBaja);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['exito'] == true
              ? '✅ Cuenta reactivada exitosamente'
              : '❌ ${resultado['mensaje']}'),
          backgroundColor: resultado['exito'] == true ? Colors.green : Colors.red,
        ),
      );
      _cargarSolicitudes();
    }
  }

  Future<void> _rechazar(int idBaja, String nombreUsuario) async {
    final controller = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rechazar solicitud'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Rechazar la solicitud de $nombreUsuario?'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Motivo del rechazo (opcional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final motivo = controller.text.trim().isNotEmpty
        ? controller.text.trim()
        : 'Solicitud rechazada por el administrador';

    final resultado = await BajaCuentaService.rechazarReactivacion(idBaja, motivo);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['exito'] == true
              ? '✅ Solicitud rechazada'
              : '❌ ${resultado['mensaje']}'),
          backgroundColor: resultado['exito'] == true ? Colors.orange : Colors.red,
        ),
      );
      _cargarSolicitudes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes de reactivación'),
        backgroundColor: const Color(0xFFC5414B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarSolicitudes,
          ),
        ],
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5414B)),
              ),
            )
          : _solicitudes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 80, color: Colors.green.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        '¡Todo al día!',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No hay solicitudes pendientes',
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarSolicitudes,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _solicitudes.length,
                    itemBuilder: (context, index) {
                      final solicitud = _solicitudes[index];
                      return _buildSolicitudCard(solicitud);
                    },
                  ),
                ),
    );
  }

  Widget _buildSolicitudCard(Map<String, dynamic> solicitud) {
    final nombre = solicitud['nombre_completo'] ?? 'Usuario desconocido';
    final email = solicitud['email'] ?? '';
    final telefono = solicitud['telefono'] ?? '';
    final dni = solicitud['dni'] ?? '';
    final rol = solicitud['rol_afectado'] == 'EMPLEADOR' ? 'Empleador' : 'Empleado';
    final calificaciones = solicitud['total_calificaciones'] ?? 0;
    final promedio = solicitud['promedio_al_momento'];
    final mensaje = solicitud['mensaje_solicitud'] ?? '';
    final idBaja = solicitud['id_baja'] as int;

    String fechaSolicitud = '';
    if (solicitud['fecha_solicitud'] != null) {
      final fecha = DateTime.parse(solicitud['fecha_solicitud'].toString());
      fechaSolicitud = '${fecha.day}/${fecha.month}/${fecha.year}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con nombre y fecha
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.red.shade100,
                  child: Icon(Icons.person, color: Colors.red.shade700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombre,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(email,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600)),
                  if (telefono.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.phone, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(telefono,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                    ],
                  ),
                ),
                if (fechaSolicitud.isNotEmpty)
                  Text(fechaSolicitud,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),

            const SizedBox(height: 16),

            // Detalles
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoChip('Rol', rol),
                  _buildInfoChip('Negativas', '$calificaciones'),
                  _buildInfoChip('Promedio',
                      promedio != null ? '${(promedio as num).toStringAsFixed(1)}' : '—'),
                ],
              ),
            ),

            // Mensaje del usuario
            if (mensaje.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mensaje del usuario:',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700)),
                    const SizedBox(height: 4),
                    Text(mensaje,
                        style: const TextStyle(fontSize: 14, height: 1.4)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Botones aprobar/rechazar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rechazar(idBaja, nombre),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Rechazar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _aprobar(idBaja, nombre),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Aprobar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}