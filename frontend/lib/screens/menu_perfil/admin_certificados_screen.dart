// frontend/lib/screens/menu_perfil/admin_certificados_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/certificado_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminCertificadosScreen extends StatefulWidget {
  const AdminCertificadosScreen({super.key});

  @override
  State<AdminCertificadosScreen> createState() => _AdminCertificadosScreenState();
}

class _AdminCertificadosScreenState extends State<AdminCertificadosScreen> {
  final CertificadoService _certificadoService = CertificadoService();
  final SupabaseClient _client = Supabase.instance.client;

  List<Map<String, dynamic>> _pendientes = [];
  bool _isLoading = true;
  int? _adminUsuarioId;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final authId = _client.auth.currentUser?.id;
      if (authId == null) return;

      final usuario = await _client
          .from('usuario')
          .select('id_usuario')
          .eq('auth_user_id', authId)
          .maybeSingle();

      if (usuario == null) return;
      _adminUsuarioId = usuario['id_usuario'];

      _pendientes = await _certificadoService.obtenerCertificadosPendientes();
    } catch (e) {
      print('Error al cargar certificados pendientes: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _verArchivo(String archivoUrl) async {
    final url = await _certificadoService.obtenerUrlArchivo(archivoUrl);
    if (url != null) {
      final archivoEsPdf = archivoUrl.toLowerCase().endsWith('.pdf');

      if (archivoEsPdf) {
        // Abrir PDF en nueva pestaña
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        // Mostrar imagen en diálogo
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Certificado'),
            content: SizedBox(
              width: 500,
              height: 500,
              child: Image.network(url, fit: BoxFit.contain),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cargar el archivo'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _aprobar(Map<String, dynamic> cert) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aprobar certificado'),
        content: Text(
          '¿Aprobar el certificado de ${cert['usuario_nombre']} para ${cert['rubro']?['nombre'] ?? 'rubro desconocido'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Aprobar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final success = await _certificadoService.aprobarCertificado(
      cert['id'],
      _adminUsuarioId!,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Certificado aprobado'),
          backgroundColor: Colors.green,
        ),
      );
      _cargarDatos();
    }
  }

  Future<void> _rechazar(Map<String, dynamic> cert) async {
    final motivoController = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar certificado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Certificado de ${cert['usuario_nombre']} para ${cert['rubro']?['nombre'] ?? ''}'),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              decoration: const InputDecoration(
                labelText: 'Motivo del rechazo',
                hintText: 'Ej: Archivo ilegible, no corresponde al rubro...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (motivoController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ingresá un motivo de rechazo')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rechazar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final success = await _certificadoService.rechazarCertificado(
      cert['id'],
      _adminUsuarioId!,
      motivoController.text.trim(),
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Certificado rechazado'),
          backgroundColor: Colors.orange,
        ),
      );
      _cargarDatos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Certificados Pendientes'),
        backgroundColor: const Color(0xFFC5414B),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendientes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No hay certificados pendientes',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendientes.length,
                  itemBuilder: (context, index) {
                    final cert = _pendientes[index];
                    final nombre = cert['usuario_nombre'] ?? 'Desconocido';
                    final username = cert['usuario_username'] ?? '';
                    final rubroNombre = cert['rubro']?['nombre'] ?? 'Rubro desconocido';
                    final tipo = cert['archivo_tipo'] ?? 'imagen';
                    final fechaSubida = cert['fecha_subida'] != null
                        ? DateTime.parse(cert['fecha_subida']).toLocal()
                        : null;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: usuario info
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFFC5414B).withOpacity(0.1),
                                  child: const Icon(Icons.person, color: Color(0xFFC5414B)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nombre,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (username.isNotEmpty)
                                        Text(
                                          '@$username',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.hourglass_top, size: 14, color: Colors.orange),
                                      SizedBox(width: 4),
                                      Text(
                                        'Pendiente',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),

                            // Rubro y tipo
                            Row(
                              children: [
                                Icon(Icons.category, size: 18, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text('Rubro: ', style: TextStyle(color: Colors.grey[600])),
                                Text(
                                  rubroNombre,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  tipo == 'pdf' ? Icons.picture_as_pdf : Icons.image,
                                  size: 18,
                                  color: tipo == 'pdf' ? Colors.red : Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Text('Tipo: ', style: TextStyle(color: Colors.grey[600])),
                                Text(
                                  tipo == 'pdf' ? 'Documento PDF' : 'Imagen',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            if (fechaSubida != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Text('Fecha: ', style: TextStyle(color: Colors.grey[600])),
                                  Text(
                                    '${fechaSubida.day}/${fechaSubida.month}/${fechaSubida.year} ${fechaSubida.hour}:${fechaSubida.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),

                            // Botón ver archivo
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _verArchivo(cert['archivo_url']),
                                icon: const Icon(Icons.visibility),
                                label: Text(tipo == 'pdf' ? 'Ver PDF' : 'Ver imagen'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFC5414B),
                                  side: const BorderSide(color: Color(0xFFC5414B)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Botones aprobar / rechazar
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _rechazar(cert),
                                    icon: const Icon(Icons.close, size: 18),
                                    label: const Text('Rechazar'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _aprobar(cert),
                                    icon: const Icon(Icons.check, size: 18),
                                    label: const Text('Aprobar'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}