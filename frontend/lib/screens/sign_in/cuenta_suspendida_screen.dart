// lib/screens/sign_in/cuenta_suspendida_screen.dart

import 'package:flutter/material.dart';
import '../../models/menu_perfil/baja_cuenta_model.dart';

class CuentaSuspendidaScreen extends StatelessWidget {
  final BajaCuentaInfo? bajaCuentaInfo;

  const CuentaSuspendidaScreen({Key? key, this.bajaCuentaInfo})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final info = bajaCuentaInfo;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Column(
        children: [
          // Sección superior oscura (mismo estilo que login)
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

          // Sección inferior con información
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
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red.shade700,
                            size: 36,
                          ),
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

                    // Detalles de la suspensión
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
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildDetalleRow(
                              Icons.person_outline,
                              'Rol afectado',
                              info.rolAfectado == 'EMPLEADOR'
                                  ? 'Empleador'
                                  : 'Empleado',
                            ),
                            const SizedBox(height: 12),
                            _buildDetalleRow(
                              Icons.star_border,
                              'Calificaciones negativas',
                              '${info.totalCalificaciones ?? "—"}',
                            ),
                            const SizedBox(height: 12),
                            _buildDetalleRow(
                              Icons.trending_down,
                              'Promedio al momento',
                              info.promedioAlMomento != null
                                  ? '${info.promedioAlMomento!.toStringAsFixed(1)} / 5.0'
                                  : '—',
                            ),
                            if (info.fechaBajaFormateada.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildDetalleRow(
                                Icons.calendar_today,
                                'Fecha de suspensión',
                                info.fechaBajaFormateada,
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],

                    // Qué hacer
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.support_agent,
                            color: Colors.blue.shade700,
                            size: 36,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '¿Cómo reactivar tu cuenta?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Contactá a un administrador para solicitar '
                            'la reactivación de tu cuenta. El administrador '
                            'evaluará tu caso y podrá restablecer tu acceso.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade800,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Botón volver al login
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 39, 38, 38),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Volver al inicio',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}