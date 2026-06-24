// lib/screens/sign_in/cuenta_suspendida_screen.dart

import 'package:flutter/material.dart';
import '../../models/menu_perfil/baja_cuenta_model.dart';
import '../../services/baja_cuenta_service.dart';
import '../../services/auth_service.dart';

class CuentaSuspendidaScreen extends StatefulWidget {
  final BajaCuentaInfo? bajaCuentaInfo;

  const CuentaSuspendidaScreen({Key? key, this.bajaCuentaInfo})
      : super(key: key);

  @override
  State<CuentaSuspendidaScreen> createState() => _CuentaSuspendidaScreenState();
}

class _CuentaSuspendidaScreenState extends State<CuentaSuspendidaScreen> {
  bool _solicitudEnviada = false;
  bool _enviando = false;

  void _mostrarDialogoSolicitud() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Solicitar reactivación',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Escribí un mensaje para el administrador explicando por qué debería reactivarse tu cuenta.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: 'Ej: Me comprometo a mejorar mi desempeño...',
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final mensaje = controller.text.trim();
              if (mensaje.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Escribí un mensaje para continuar'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              _enviarSolicitud(mensaje);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC5414B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Enviar solicitud'),
          ),
        ],
      ),
    );
  }

  Future<void> _enviarSolicitud(String mensaje) async {
    setState(() => _enviando = true);

    try {
      final resultado = await BajaCuentaService.solicitarReactivacion(mensaje);

      if (mounted) {
        if (resultado['exito'] == true) {
          setState(() => _solicitudEnviada = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Solicitud enviada correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resultado['mensaje'] ?? 'Error al enviar solicitud'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _cerrarSesionYVolver() async {
    await BajaCuentaService.cerrarSesionPorSuspension();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.bajaCuentaInfo;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Column(
        children: [
          // Sección superior oscura
          Container(
            height: screenHeight * 0.35,
            width: double.infinity,
            color: const Color.fromARGB(255, 39, 38, 38),
            child: SafeArea(
              bottom: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.block_rounded,
                        size: 60,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Cuenta Suspendida',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Sección inferior
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Mensaje principal
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.red.shade700, size: 36),
                          const SizedBox(height: 12),
                          Text(
                            info?.mensajeUsuario ??
                                'Tu cuenta ha sido suspendida debido a múltiples calificaciones negativas.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.red.shade900,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Detalles
                    if (info != null && info.suspendido) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Detalles de la suspensión',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87),
                            ),
                            const SizedBox(height: 16),
                            _buildDetalleRow(Icons.person_outline, 'Rol afectado',
                                info.rolAfectado == 'EMPLEADOR' ? 'Empleador' : 'Empleado'),
                            const SizedBox(height: 12),
                            _buildDetalleRow(Icons.star_border, 'Calificaciones negativas',
                                '${info.totalCalificaciones ?? "—"}'),
                            const SizedBox(height: 12),
                            _buildDetalleRow(
                                Icons.trending_down,
                                'Promedio al momento',
                                info.promedioAlMomento != null
                                    ? '${info.promedioAlMomento!.toStringAsFixed(1)} / 5.0'
                                    : '—'),
                            if (info.fechaBajaFormateada.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildDetalleRow(Icons.calendar_today,
                                  'Fecha de suspensión', info.fechaBajaFormateada),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Solicitar reactivación
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _solicitudEnviada
                            ? Colors.green.shade50
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _solicitudEnviada
                              ? Colors.green.shade200
                              : Colors.blue.shade200,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _solicitudEnviada
                                ? Icons.check_circle
                                : Icons.support_agent,
                            color: _solicitudEnviada
                                ? Colors.green.shade700
                                : Colors.blue.shade700,
                            size: 36,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _solicitudEnviada
                                ? 'Solicitud enviada'
                                : '¿Cómo reactivar tu cuenta?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _solicitudEnviada
                                  ? Colors.green.shade900
                                  : Colors.blue.shade900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _solicitudEnviada
                                ? 'Tu solicitud fue enviada al administrador. Te notificaremos cuando sea revisada.'
                                : 'Podés enviar una solicitud al administrador para que evalúe la reactivación de tu cuenta.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: _solicitudEnviada
                                  ? Colors.green.shade800
                                  : Colors.blue.shade800,
                              height: 1.5,
                            ),
                          ),
                          if (!_solicitudEnviada) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed:
                                    _enviando ? null : _mostrarDialogoSolicitud,
                                icon: _enviando
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.send),
                                label: Text(
                                    _enviando ? 'Enviando...' : 'Solicitar reactivación'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC5414B),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Botón volver
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _cerrarSesionYVolver,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 39, 38, 38),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Volver al inicio',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        ),
        Text(value,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
      ],
    );
  }
}