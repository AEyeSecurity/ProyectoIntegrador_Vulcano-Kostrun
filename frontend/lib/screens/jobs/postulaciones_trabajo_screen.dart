// lib/screens/jobs/postulaciones_trabajo_screen.dart

import 'package:flutter/material.dart';
import '../../models/postulacion_model.dart';
import '../../services/postulacion_service.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../../services/certificado_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostulacionesTrabajoScreen extends StatefulWidget {
  final int trabajoId;

  const PostulacionesTrabajoScreen({
    Key? key,
    required this.trabajoId,
  }) : super(key: key);

  @override
  State<PostulacionesTrabajoScreen> createState() =>
      _PostulacionesTrabajoScreenState();
}

class _PostulacionesTrabajoScreenState extends State<PostulacionesTrabajoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PostulacionModel> _todasPostulaciones = [];
  bool _isLoading = true;
  String? _errorMessage;
  final ChatService _chatService = ChatService(); // ✅ NUEVO
  final CertificadoService _certificadoService = CertificadoService();
  int? _rubroIdTrabajo;
  Map<int, bool> _certificadosVerificados = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _cargarPostulaciones();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarPostulaciones() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_rubroIdTrabajo == null) {
        final trabajo = await Supabase.instance.client
            .from('trabajo')
            .select('id_rubro')
            .eq('id_trabajo', widget.trabajoId)
            .maybeSingle();
        _rubroIdTrabajo = trabajo?['id_rubro'];
      }

      final postulaciones = await PostulacionService.getPostulacionesDeTrabajo(
        widget.trabajoId,
      );

      _certificadosVerificados = {};
      if (_rubroIdTrabajo != null) {
        for (var p in postulaciones) {
          final tiene = await _certificadoService.tieneCertificadoVerificado(
            p.postulanteId,
            _rubroIdTrabajo!,
          );
          _certificadosVerificados[p.postulanteId] = tiene;
        }
      }

      setState(() {
        _todasPostulaciones = postulaciones;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<PostulacionModel> _filtrarPorEstado(String? estado) {
    if (estado == null) return _todasPostulaciones;
    return _todasPostulaciones
        .where((p) => p.estado.toUpperCase() == estado.toUpperCase())
        .toList();
  }

  int _contarPorEstado(String estado) {
    return _todasPostulaciones
        .where((p) => p.estado.toUpperCase() == estado.toUpperCase())
        .length;
  }

  void _verPerfil(PostulacionModel postulacion) {
    // Si la postulación tiene empleado_empresa_id, es un empleado de empresa
    // Entonces redirigir al perfil de la EMPRESA (postulanteId es el id de la empresa)
    if (postulacion.empleadoEmpresaId != null) {
      // Es empleado de empresa → mostrar perfil de la empresa
      Navigator.pushNamed(
        context,
        '/perfil-publico',
        arguments: postulacion.postulanteId, // Este es el ID de la empresa
      );
    } else {
      // Es persona → mostrar perfil personal
      Navigator.pushNamed(
        context,
        '/perfil-publico',
        arguments: postulacion.postulanteId,
      );
    }
  }

  // ✅ NUEVO: Abrir chat con postulante
  Future<void> _abrirChat(PostulacionModel postulacion) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFC5414B),
          ),
        ),
      );

      final userData = await AuthService.getCurrentUserData();
      if (userData == null) {
        throw Exception('Usuario no autenticado');
      }

      // Obtener o crear conversación
      final conversacion =
          await _chatService.obtenerOCrearConversacion(postulacion.id);

      if (mounted) Navigator.pop(context); // Cerrar loading

      if (mounted) {
        Navigator.pushNamed(
          context,
          '/chat',
          arguments: {
            'conversacion': conversacion,
            'usuarioId': userData.idUsuario,
          },
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Cerrar loading

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _aceptarPostulacion(PostulacionModel postulacion) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aceptar postulante'),
        content: Text(
          '¿Confirmas que quieres aceptar a ${postulacion.postulante?.nombre ?? "este postulante"}?',
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
            ),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      try {
        await PostulacionService.aceptarPostulacion(postulacion.id);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '✅ Postulante aceptado. Se ha enviado un mensaje automático.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        _cargarPostulaciones();
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

  Future<void> _rechazarPostulacion(PostulacionModel postulacion) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar postulante'),
        content: Text(
          '¿Confirmas que quieres rechazar a ${postulacion.postulante?.nombre ?? "este postulante"}?',
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
            ),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      try {
        await PostulacionService.rechazarPostulacion(postulacion.id);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Postulante rechazado'),
            backgroundColor: Colors.orange,
          ),
        );

        _cargarPostulaciones();
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
          'Postulaciones',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _cargarPostulaciones,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Todas (${_todasPostulaciones.length})'),
            Tab(text: 'Pendientes (${_contarPorEstado('PENDIENTE')})'),
            Tab(text: 'Aceptadas (${_contarPorEstado('ACEPTADO')})'),
            Tab(text: 'Rechazadas (${_contarPorEstado('RECHAZADO')})'),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5414B)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarPostulaciones,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_todasPostulaciones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay postulaciones aún',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildListaPostulaciones(_filtrarPorEstado(null)),
        _buildListaPostulaciones(_filtrarPorEstado('PENDIENTE')),
        _buildListaPostulaciones(_filtrarPorEstado('ACEPTADO')),
        _buildListaPostulaciones(_filtrarPorEstado('RECHAZADO')),
      ],
    );
  }

  Widget _buildListaPostulaciones(List<PostulacionModel> postulaciones) {
    if (postulaciones.isEmpty) {
      return Center(
        child: Text(
          'No hay postulaciones en esta categoría',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: postulaciones.length,
      itemBuilder: (context, index) {
        return _buildPostulacionCard(postulaciones[index]);
      },
    );
  }

  Widget _buildPostulacionCard(PostulacionModel postulacion) {
    final postulante = postulacion.postulante;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con postulante
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _verPerfil(postulacion),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFFC5414B),
                    backgroundImage: postulante?.fotoPerfil != null
                        ? NetworkImage(postulante!.fotoPerfil!)
                        : null,
                    child: postulante?.fotoPerfil == null
                        ? Text(
                            postulante?.getIniciales() ?? 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _verPerfil(postulacion),
                        child: Text(
                          postulante?.nombre ?? 'Usuario',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_certificadosVerificados[postulacion.postulanteId] == true)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withOpacity(0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, size: 14, color: Colors.green),
                              SizedBox(width: 4),
                              Text(
                                'Matriculado',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (postulante?.puntajePromedio != null) ...[
                            const Icon(Icons.star,
                                size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              postulante!.puntajePromedio!.toStringAsFixed(1),
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 12),
                          ],
                          TextButton.icon(
                            onPressed: () => _verPerfil(postulacion),
                            icon: const Icon(Icons.person, size: 14),
                            label: const Text('Ver perfil'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFC5414B),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getEstadoColor(postulacion.estado).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    postulacion.getEstadoLabel(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getEstadoColor(postulacion.estado),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Mensaje del postulante
          if (postulacion.mensaje != null && postulacion.mensaje!.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.message, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Mensaje:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    postulacion.mensaje!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Fecha de postulación
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatFecha(postulacion.fechaPostulacion),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ✅ BOTÓN DE CHAT
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _abrirChat(postulacion),
                icon: const Icon(Icons.chat_bubble_outline, size: 20),
                label: const Text(
                  'Chatear con postulante',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFC5414B),
                  side: const BorderSide(color: Color(0xFFC5414B), width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ✅ BOTONES DE ACCIÓN (Aceptar/Rechazar) - SOLO SI ESTÁ PENDIENTE
          if (postulacion.estado.toUpperCase() == 'PENDIENTE')
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rechazarPostulacion(postulacion),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Rechazar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _aceptarPostulacion(postulacion),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Aceptar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'PENDIENTE':
        return Colors.orange;
      case 'ACEPTADO':
        return Colors.green;
      case 'RECHAZADO':
        return Colors.red;
      case 'CANCELADO':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatFecha(DateTime fecha) {
    final now = DateTime.now();
    final diferencia = now.difference(fecha);

    if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes} minutos';
    } else if (diferencia.inHours < 24) {
      return 'Hace ${diferencia.inHours} horas';
    } else if (diferencia.inDays < 7) {
      return 'Hace ${diferencia.inDays} días';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }
}
