// lib/screens/jobs/mis_postulaciones_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/postulacion_service.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../../services/calificacion_service.dart';
import '../../models/postulacion_model.dart';
import '../user/perfil_publico_screen.dart' show PerfilCompartidoScreen;

class MisPostulacionesScreen extends StatefulWidget {
  const MisPostulacionesScreen({Key? key}) : super(key: key);

  @override
  State<MisPostulacionesScreen> createState() => _MisPostulacionesScreenState();
}

class _MisPostulacionesScreenState extends State<MisPostulacionesScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ChatService _chatService = ChatService();
  List<PostulacionModel> _todasPostulaciones = [];
  bool _isLoading = true;
  bool _esEmpresa = false;
  int? _currentUserId;

  // ✅ NUEVO: Mapa para guardar calificaciones de trabajos finalizados
  Map<int, Map<String, dynamic>?> _calificacionesPorTrabajo = {};

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
    setState(() => _isLoading = true);
    try {
      final userData = await AuthService.getCurrentUserData();
      final postulaciones = await PostulacionService.getMisPostulaciones();
      
      final userId = userData?.idUsuario;

      // ✅ NUEVO: Cargar calificaciones para postulaciones finalizadas
      final Map<int, Map<String, dynamic>?> calificaciones = {};
      if (userId != null) {
        final finalizadas = postulaciones.where(
          (p) => p.estado.toUpperCase() == 'FINALIZADO'
        ).toList();

        for (var p in finalizadas) {
          final cal = await CalificacionService.obtenerCalificacionRecibidaEnTrabajo(
            trabajoId: p.trabajoId,
            idUsuario: userId,
          );
          calificaciones[p.trabajoId] = cal;
        }
      }

      setState(() {
        _esEmpresa = userData?.isEmpresa ?? false;
        _currentUserId = userId;
        _todasPostulaciones = postulaciones;
        _calificacionesPorTrabajo = calificaciones;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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

  // ✅ AGRUPAR POSTULACIONES POR TRABAJO (solo para empresas)
  Map<int, List<PostulacionModel>> _agruparPorTrabajo(List<PostulacionModel> postulaciones) {
    final Map<int, List<PostulacionModel>> agrupadas = {};
    
    for (var postulacion in postulaciones) {
      final trabajoId = postulacion.trabajoId;
      if (!agrupadas.containsKey(trabajoId)) {
        agrupadas[trabajoId] = [];
      }
      agrupadas[trabajoId]!.add(postulacion);
    }
    
    return agrupadas;
  }

  Future<void> _abrirChat(PostulacionModel postulacion) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFC5414B)),
        ),
      );

      final userData = await AuthService.getCurrentUserData();
      if (userData == null) throw Exception('Usuario no autenticado');

      final conversacion = await _chatService.obtenerOCrearConversacion(postulacion.id);

      if (mounted) Navigator.pop(context);

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
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ✅ CANCELAR POSTULACIÓN
  Future<void> _cancelarPostulacion(PostulacionModel postulacion, {String? nombreEmpleado}) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancelar postulación'),
        content: Text(
          nombreEmpleado != null
              ? '¿Confirmas que quieres cancelar la postulación de $nombreEmpleado?'
              : '¿Confirmas que quieres cancelar tu postulación?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      try {
        await PostulacionService.cancelarPostulacion(postulacion.trabajoId);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Postulación cancelada'),
            backgroundColor: Colors.orange,
          ),
        );
        
        _cargarPostulaciones();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ✅ NUEVO: Formatear fecha legible
  String _formatearFecha(String? fechaStr) {
    if (fechaStr == null) return 'Sin fecha';
    try {
      final fecha = DateTime.parse(fechaStr);
      return DateFormat('dd/MM/yyyy').format(fecha);
    } catch (e) {
      return fechaStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 197, 197),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC5414B),
        title: const Text('Mis Postulaciones', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC5414B)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLista(_filtrarPorEstado(null)),
                _buildLista(_filtrarPorEstado('PENDIENTE')),
                _buildLista(_filtrarPorEstado('ACEPTADO')),
                _buildLista(_filtrarPorEstado('RECHAZADO')),
              ],
            ),
    );
  }

  Widget _buildLista(List<PostulacionModel> postulaciones) {
    if (postulaciones.isEmpty) {
      return Center(
        child: Text('No hay postulaciones', style: TextStyle(color: Colors.grey[600])),
      );
    }

    // ✅ SI ES EMPRESA: Agrupar por trabajo
    if (_esEmpresa) {
      final agrupadas = _agruparPorTrabajo(postulaciones);
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: agrupadas.length,
        itemBuilder: (context, index) {
          final trabajoId = agrupadas.keys.elementAt(index);
          final postulacionesTrabajo = agrupadas[trabajoId]!;
          return _buildCardEmpresa(postulacionesTrabajo);
        },
      );
    }

    // ✅ SI ES PERSONA: Mostrar lista normal
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: postulaciones.length,
      itemBuilder: (context, index) => _buildCardPersona(postulaciones[index]),
    );
  }

  // ✅ CARD PARA EMPRESAS (muestra empleados postulados)
  Widget _buildCardEmpresa(List<PostulacionModel> postulaciones) {
    final trabajo = postulaciones.first.trabajo;
    final tituloTrabajo = trabajo?.titulo ?? 'Trabajo';
    
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
          // Header del trabajo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFC5414B).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.work, color: Color(0xFFC5414B)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tituloTrabajo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC5414B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${postulaciones.length} empleado${postulaciones.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de empleados postulados
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: postulaciones.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) {
              final postulacion = postulaciones[index];
              return _buildEmpleadoItem(postulacion);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmpleadoItem(PostulacionModel postulacion) {
    final nombreEmpleado = postulacion.nombreConEmpresa ?? 'Empleado';
    
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFC5414B),
            child: Text(
              nombreEmpleado.substring(0, 1).toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombreEmpleado,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getEstadoColor(postulacion.estado).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    postulacion.getEstadoLabel(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getEstadoColor(postulacion.estado),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // ✅ BOTÓN CANCELAR (solo si está PENDIENTE)
          if (postulacion.estado.toUpperCase() == 'PENDIENTE')
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => _cancelarPostulacion(postulacion, nombreEmpleado: nombreEmpleado),
              tooltip: 'Cancelar postulación',
            ),
          
          // ✅ BOTÓN CHAT (solo si está ACEPTADO)
          if (postulacion.estado.toUpperCase() == 'ACEPTADO')
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFFC5414B)),
              onPressed: () => _abrirChat(postulacion),
              tooltip: 'Chatear',
            ),
        ],
      ),
    );
  }

  // ✅ CARD PARA PERSONAS (ACTUALIZADO con fecha y calificación)
  Widget _buildCardPersona(PostulacionModel postulacion) {
    final esFinalizado = postulacion.estado.toUpperCase() == 'FINALIZADO';
    final calificacion = esFinalizado ? _calificacionesPorTrabajo[postulacion.trabajoId] : null;
    final trabajo = postulacion.trabajo;

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    trabajo?.titulo ?? 'Trabajo',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

            // ✅ NUEVO: Nombre del empleador con link a perfil
            if (trabajo?.nombreEmpleador != null) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: () {
                  if (trabajo?.empleadorId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PerfilCompartidoScreen(
                          userId: trabajo!.empleadorId!,
                        ),
                      ),
                    );
                  }
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFFC5414B),
                      backgroundImage: trabajo?.fotoEmpleador != null
                          ? NetworkImage(trabajo!.fotoEmpleador!)
                          : null,
                      child: trabajo?.fotoEmpleador == null
                          ? Text(
                              trabajo!.nombreEmpleador![0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        trabajo!.nombreEmpleador!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFC5414B),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
                  ],
                ),
              ),
            ],

            // ✅ Info de fecha y calificación para trabajos finalizados
            if (esFinalizado) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    // Fecha de realización
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Realizado: ${_formatearFecha(trabajo?.fechaFin ?? postulacion.updatedAt.toIso8601String())}',
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Calificación recibida
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 18, color: Colors.amber[700]),
                        const SizedBox(width: 6),
                        if (calificacion != null) ...[
                          ...List.generate(5, (i) => Icon(
                            i < (calificacion['puntuacion'] as int) 
                                ? Icons.star_rounded 
                                : Icons.star_outline_rounded,
                            size: 18,
                            color: Colors.amber[700],
                          )),
                          const SizedBox(width: 8),
                          Text(
                            '${calificacion['puntuacion']}/5',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(por ${trabajo?.nombreEmpleador ?? "empleador"})',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                        ] else
                          Text(
                            'Sin calificación aún',
                            style: TextStyle(fontSize: 13, color: Colors.grey[500], fontStyle: FontStyle.italic),
                          ),
                      ],
                    ),
                    // Comentario si existe
                    if (calificacion != null && 
                        calificacion['comentario'] != null && 
                        (calificacion['comentario'] as String).isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.comment_outlined, size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '"${calificacion['comentario']}"',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _abrirChat(postulacion),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Chatear'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC5414B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (postulacion.estado.toUpperCase() == 'PENDIENTE') ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelarPostulacion(postulacion),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Cancelar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'PENDIENTE': return Colors.orange;
      case 'ACEPTADO': return Colors.green;
      case 'RECHAZADO': return Colors.red;
      case 'CANCELADO': return Colors.grey;
      case 'FINALIZADO': return Colors.blueGrey;
      default: return Colors.grey;
    }
  }
}