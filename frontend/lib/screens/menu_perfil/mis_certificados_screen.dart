// frontend/lib/screens/menu_perfil/mis_certificados_screen.dart

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/certificado_service.dart';
import 'package:url_launcher/url_launcher.dart';

class MisCertificadosScreen extends StatefulWidget {
  const MisCertificadosScreen({super.key});

  @override
  State<MisCertificadosScreen> createState() => _MisCertificadosScreenState();
}

class _MisCertificadosScreenState extends State<MisCertificadosScreen> {
  final CertificadoService _certificadoService = CertificadoService();
  final SupabaseClient _client = Supabase.instance.client;

  List<Map<String, dynamic>> _certificados = [];
  List<Map<String, dynamic>> _misRubros = [];
  bool _isLoading = true;
  bool _isUploading = false;

  int? _usuarioId;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      // Obtener id del usuario logueado
      final authId = _client.auth.currentUser?.id;
      if (authId == null) return;

      final usuario = await _client
          .from('usuario')
          .select('id_usuario')
          .eq('auth_user_id', authId)
          .maybeSingle();

      if (usuario == null) return;
      _usuarioId = usuario['id_usuario'];

      // Obtener rubros del usuario
      final rubrosResponse = await _client
          .from('usuario_rubro')
          .select('id_rubro, rubro:id_rubro(id_rubro, nombre)')
          .eq('id_usuario', _usuarioId!);

      _misRubros = List<Map<String, dynamic>>.from(rubrosResponse);

      // Obtener certificados existentes
      print('DEBUG usuario_id: $_usuarioId');
      _certificados = await _certificadoService.obtenerMisCertificados(_usuarioId!);
      print('DEBUG certificados: $_certificados');
    } catch (e) {
      print('Error al cargar datos: $e');
    }
    setState(() => _isLoading = false);
  }

  // Verificar si ya tiene certificado para un rubro
  bool _tieneCertificadoParaRubro(int rubroId) {
    return _certificados.any((c) =>
        c['rubro_id'] == rubroId &&
        (c['estado'] == 'PENDIENTE' || c['estado'] == 'VERIFICADO'));
  }

  // Rubros disponibles para subir (sin certificado pendiente o verificado)
  List<Map<String, dynamic>> get _rubrosDisponibles {
    return _misRubros.where((r) {
      final rubroId = r['id_rubro'] ?? r['rubro']?['id_rubro'];
      return rubroId != null && !_tieneCertificadoParaRubro(rubroId);
    }).toList();
  }

  Future<void> _subirCertificado() async {
    if (_rubrosDisponibles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya tenés certificados cargados o en revisión para todos tus rubros.'),
        ),
      );
      return;
    }

    // 1. Seleccionar rubro
    final rubroSeleccionado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Para qué rubro es el certificado?'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _rubrosDisponibles.length,
            itemBuilder: (context, index) {
              final rubro = _rubrosDisponibles[index];
              final nombre = rubro['rubro']?['nombre'] ?? 'Sin nombre';
              final rubroId = rubro['rubro_id'] ?? rubro['rubro']?['id_rubro'];
              return ListTile(
                title: Text(nombre),
                leading: const Icon(Icons.work_outline),
                onTap: () => Navigator.pop(context, {'id': rubroId, 'nombre': nombre}),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (rubroSeleccionado == null) return;

    // 2. Seleccionar archivo
  final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true, // necesario para web
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final fileName = file.name;
    final esPdf = fileName.toLowerCase().endsWith('.pdf');

    setState(() => _isUploading = true);

    bool success = false;

    if (file.bytes != null) {
      // Web o plataforma que devuelve bytes
      success = await _certificadoService.subirCertificadoBytes(
        usuarioId: _usuarioId!,
        rubroId: rubroSeleccionado['id'],
        fileBytes: file.bytes!,
        fileName: fileName,
        esPdf: esPdf,
      );
    } else if (file.path != null) {
      // Mobile/Desktop con path
      success = await _certificadoService.subirCertificado(
        usuarioId: _usuarioId!,
        rubroId: rubroSeleccionado['id'],
        filePath: file.path!,
        fileName: fileName,
        esPdf: esPdf,
      );
    }

    setState(() => _isUploading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Certificado subido correctamente. Está pendiente de revisión.'),
          backgroundColor: Colors.green,
        ),
      );
      _cargarDatos(); // Recargar lista
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Error al subir el certificado. Intentá de nuevo.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verArchivo(String archivoUrl) async {
    final url = await _certificadoService.obtenerUrlArchivo(archivoUrl);
    if (url != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Certificado'),
          content: SizedBox(
            width: 400,
            height: 400,
            child: archivoUrl.endsWith('.pdf')
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text('Archivo PDF'),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            final uri = Uri.parse(url);
                            launchUrl(uri, mode: LaunchMode.externalApplication);
                          },
                          child: const Text('Abrir en navegador'),
                        ),
                      ],
                    ),
                  )
                : Image.network(url, fit: BoxFit.contain),
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
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'PENDIENTE':
        return Colors.orange;
      case 'VERIFICADO':
        return Colors.green;
      case 'RECHAZADO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _iconoEstado(String estado) {
    switch (estado) {
      case 'PENDIENTE':
        return Icons.hourglass_top;
      case 'VERIFICADO':
        return Icons.verified;
      case 'RECHAZADO':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _textoEstado(String estado) {
    switch (estado) {
      case 'PENDIENTE':
        return 'En revisión';
      case 'VERIFICADO':
        return 'Verificado ✅';
      case 'RECHAZADO':
        return 'Rechazado';
      default:
        return estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Certificados'),
        backgroundColor: const Color(0xFFC5414B),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _subirCertificado,
        backgroundColor: const Color(0xFFC5414B),
        icon: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.upload_file, color: Colors.white),
        label: Text(
          _isUploading ? 'Subiendo...' : 'Subir certificado',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _certificados.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_user_outlined, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No tenés certificados cargados',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Subí tu certificado de matriculación para que los empleadores vean que estás habilitado.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _certificados.length,
                  itemBuilder: (context, index) {
                    final cert = _certificados[index];
                    final rubroNombre = cert['rubro']?['nombre'] ?? 'Rubro desconocido';
                    final estado = cert['estado'] ?? 'PENDIENTE';
                    final tipo = cert['archivo_tipo'] ?? 'imagen';
                    final motivoRechazo = cert['motivo_rechazo'];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: _colorEstado(estado), width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  tipo == 'pdf' ? Icons.picture_as_pdf : Icons.image,
                                  color: tipo == 'pdf' ? Colors.red : Colors.blue,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    rubroNombre,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _colorEstado(estado).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_iconoEstado(estado), size: 16, color: _colorEstado(estado)),
                                      const SizedBox(width: 4),
                                      Text(
                                        _textoEstado(estado),
                                        style: TextStyle(
                                          color: _colorEstado(estado),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (estado == 'RECHAZADO' && motivoRechazo != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Motivo: $motivoRechazo',
                                  style: const TextStyle(color: Colors.red, fontSize: 13),
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () => _verArchivo(cert['archivo_url']),
                                  icon: const Icon(Icons.visibility, size: 18),
                                  label: const Text('Ver archivo'),
                                ),
                                if (estado == 'RECHAZADO')
                                  TextButton.icon(
                                    onPressed: _subirCertificado,
                                    icon: const Icon(Icons.refresh, size: 18),
                                    label: const Text('Volver a subir'),
                                    style: TextButton.styleFrom(foregroundColor: Colors.orange),
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