// lib/screens/menu_perfil/calificaciones_pendientes_screen.dart

import 'package:flutter/material.dart';
import '../../models/menu_perfil/calificacion_model.dart';
import '../../services/calificacion_service.dart';
import '../jobs/calificar_trabajo_screen.dart';

class CalificacionesPendientesScreen extends StatefulWidget {
  final bool fromLogin;
  const CalificacionesPendientesScreen({Key? key, this.fromLogin = false}) : super(key: key);

  @override
  State<CalificacionesPendientesScreen> createState() =>
      _CalificacionesPendientesScreenState();
}

class _CalificacionesPendientesScreenState
    extends State<CalificacionesPendientesScreen> {
  List<CalificacionPendiente> _pendientes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarPendientes();
  }

  Future<void> _cargarPendientes() async {
    setState(() => _isLoading = true);
    try {
      final pendientes =
          await CalificacionService.obtenerCalificacionesPendientes();
      setState(() {
        _pendientes = pendientes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _irACalificar(CalificacionPendiente pendiente) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CalificarTrabajoScreen(
          calificacionPendiente: pendiente,
        ),
      ),
    );

    // Si completó la calificación, recargar lista
    if (resultado == true) {
      await _cargarPendientes();

      // ✅ Si ya no hay pendientes, navegar según contexto
      if (_pendientes.isEmpty && mounted) {
        if (widget.fromLogin) {
          // Vino del login → entrar directo a la app
          Navigator.pushReplacementNamed(context, '/main-nav');
        } else {
          // Vino del menú → volver atrás
          Navigator.pop(context, true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC5414B),
        elevation: 0,
        leading: widget.fromLogin
            ? null  // Sin botón atrás durante login (debe calificar)
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
        automaticallyImplyLeading: !widget.fromLogin,
        title: const Text(
          'Calificaciones Pendientes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5414B)),
              ),
            )
          : _pendientes.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _cargarPendientes,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pendientes.length,
                    itemBuilder: (context, index) {
                      return _buildPendienteCard(_pendientes[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 80, color: Colors.green[300]),
          const SizedBox(height: 16),
          const Text(
            '¡Todo al día!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No tienes calificaciones pendientes',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendienteCard(CalificacionPendiente pendiente) {
    final esEmpleador = pendiente.rolACalificar == 'EMPLEADO';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFC5414B).withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con ícono de alerta
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pendiente.tituloTrabajo,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Finalizado el ${_formatFecha(pendiente.fechaFinalizacion)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Persona a calificar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFC5414B),
                    child: Text(
                      _getIniciales(pendiente.nombreContraparte),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          esEmpleador
                              ? 'Calificar a tu empleado'
                              : 'Calificar a tu empleador',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pendiente.nombreContraparte,
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
            ),
            const SizedBox(height: 16),

            // Botón calificar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _irACalificar(pendiente),
                icon: const Icon(Icons.star, size: 20),
                label: const Text(
                  'Calificar Ahora',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC5414B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getIniciales(String nombre) {
    if (nombre.isEmpty) return 'U';
    final palabras = nombre.split(' ');
    if (palabras.length >= 2) {
      return '${palabras[0][0]}${palabras[1][0]}'.toUpperCase();
    }
    return nombre[0].toUpperCase();
  }

  String _formatFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}
