// lib/screens/menu_perfil/recomendados/recomendados_section.dart

import 'package:flutter/material.dart';
import '../../../services/recomendacion_service.dart';
import 'agregar_recomendado_screen.dart';

class RecomendadosSection extends StatefulWidget {
  final int idUsuarioPerfil;
  final bool esPropioPeril;

  const RecomendadosSection({
    Key? key,
    required this.idUsuarioPerfil,
    required this.esPropioPeril,
  }) : super(key: key);

  @override
  State<RecomendadosSection> createState() => _RecomendadosSectionState();
}

class _RecomendadosSectionState extends State<RecomendadosSection> {
  final _service = RecomendacionService();
  List<Map<String, dynamic>> _recomendados = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    final data = await _service.getRecomendados(widget.idUsuarioPerfil);
    if (mounted) {
      setState(() {
        _recomendados = data;
        _loading = false;
      });
    }
  }

  Future<void> _eliminar(int idRecomendacion, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quitar recomendado'),
        content: Text('¿Querés quitar a $nombre de tu lista de recomendados?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _service.eliminarRecomendado(idRecomendacion);
      _cargar();
    }
  }

  String _formatearFecha(String fechaStr) {
    try {
      final fecha = DateTime.parse(fechaStr);
      final ahora = DateTime.now();
      final diferencia = ahora.difference(fecha);
      if (diferencia.inDays == 0) return 'Hoy';
      if (diferencia.inDays == 1) return 'Ayer';
      if (diferencia.inDays < 7) return 'Hace ${diferencia.inDays} días';
      if (diferencia.inDays < 30) return 'Hace ${(diferencia.inDays / 7).floor()} semanas';
      return 'Hace ${(diferencia.inDays / 30).floor()} meses';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5414B)),
        )),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🏅', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  const Text(
                    'Recomendados',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_recomendados.length}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              if (widget.esPropioPeril)
                TextButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AgregarRecomendadoScreen(),
                      ),
                    );
                    _cargar();
                  },
                  icon: const Icon(Icons.add, size: 18, color: Color(0xFFC5414B)),
                  label: const Text(
                    'Agregar',
                    style: TextStyle(color: Color(0xFFC5414B)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Lista vacía
          if (_recomendados.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.people_outline, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      widget.esPropioPeril
                          ? 'Todavía no recomendaste a nadie.\n¡Agregá tu primer recomendado!'
                          : 'Este usuario aún no tiene recomendados.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recomendados.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _recomendados[index];
                final recomendado = item['recomendado'] as Map<String, dynamic>;
                final personaData = recomendado['usuario_persona'];
                final persona = personaData is List
                    ? (personaData.isNotEmpty ? personaData[0] : null)
                    : personaData;

                if (persona == null) return const SizedBox.shrink();

                final nombre = '${persona['nombre'] ?? ''} ${persona['apellido'] ?? ''}'.trim();
                final foto = persona['foto_perfil_url'] as String?;
                final comentario = item['comentario'] as String? ?? '';
                final fecha = item['fecha'] as String? ?? '';
                final idUsuarioRecomendado = recomendado['id_usuario'] as int;

                // Rubros del recomendado
                final rubrosData = (recomendado['usuario_rubro'] as List? ?? []);
                final rubros = rubrosData
                    .map((ur) => ur['rubro']?['nombre'] as String?)
                    .where((r) => r != null)
                    .cast<String>()
                    .toList();

                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/perfil-publico',
                      arguments: idUsuarioRecomendado,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFC5414B).withOpacity(0.2),
                          backgroundImage: foto != null ? NetworkImage(foto) : null,
                          child: foto == null
                              ? Text(
                                  nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    color: Color(0xFFC5414B),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      nombre,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                                ],
                              ),
                              // Rubros
                              if (rubros.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: rubros.map((rubro) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFC5414B).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFC5414B).withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        rubro,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFC5414B),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                              if (comentario.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  comentario,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
                                ),
                              ],
                              if (fecha.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _formatearFecha(fecha),
                                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Botón eliminar solo en propio perfil
                        if (widget.esPropioPeril) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _eliminar(item['id_recomendacion'] as int, nombre),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.close, size: 16, color: Colors.red),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}