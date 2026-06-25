// lib/screens/menu_perfil/recomendados/agregar_recomendado_screen.dart

import 'package:flutter/material.dart';
import '../../../services/recomendacion_service.dart';

class AgregarRecomendadoScreen extends StatefulWidget {
  const AgregarRecomendadoScreen({Key? key}) : super(key: key);

  @override
  State<AgregarRecomendadoScreen> createState() => _AgregarRecomendadoScreenState();
}

class _AgregarRecomendadoScreenState extends State<AgregarRecomendadoScreen> {
  final _service = RecomendacionService();
  final _searchController = TextEditingController();
  final _comentarioController = TextEditingController();

  List<Map<String, dynamic>> _resultados = [];
  Map<String, dynamic>? _seleccionado;
  bool _buscando = false;
  bool _guardando = false;

  @override
  void dispose() {
    _searchController.dispose();
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _buscar(String query) async {
    if (query.trim().length < 2) {
      setState(() => _resultados = []);
      return;
    }
    setState(() => _buscando = true);
    final resultados = await _service.buscarUsuarios(query.trim());
    if (mounted) {
      setState(() {
        _resultados = resultados;
        _buscando = false;
      });
    }
  }

  Future<void> _guardar() async {
    if (_seleccionado == null) return;

    if (_comentarioController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribí un comentario sobre esta persona')),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      final yaExiste = await _service.yaRecomendeA(_seleccionado!['id_usuario'] as int);
      if (yaExiste) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ya tenés a esta persona en tu lista de recomendados')),
          );
        }
        setState(() => _guardando = false);
        return;
      }

      await _service.agregarRecomendado(
        idRecomendado: _seleccionado!['id_usuario'] as int,
        comentario: _comentarioController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Recomendado agregado correctamente!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _guardando = false);
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
          'Agregar recomendado',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Buscador
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o usuario...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFC5414B)),
                suffixIcon: _buscando
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5414B))),
                        ),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFC5414B)),
                ),
              ),
              onChanged: _seleccionado == null ? _buscar : null,
              enabled: _seleccionado == null,
            ),
            const SizedBox(height: 16),

            // Resultados de búsqueda
            if (_resultados.isNotEmpty && _seleccionado == null)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    itemCount: _resultados.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final u = _resultados[index];
                      final nombre = '${u['nombre'] ?? ''} ${u['apellido'] ?? ''}'.trim();
                      final foto = u['foto_perfil_url'] as String?;
                      final username = u['username'] as String?;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFC5414B).withOpacity(0.2),
                          backgroundImage: foto != null ? NetworkImage(foto) : null,
                          child: foto == null
                              ? Text(
                                  nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Color(0xFFC5414B), fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: username != null ? Text('@$username', style: TextStyle(color: Colors.grey[500])) : null,
                        onTap: () {
                          setState(() {
                            _seleccionado = u;
                            _resultados = [];
                            _searchController.text = nombre;
                          });
                        },
                      );
                    },
                  ),
                ),
              ),

            // Formulario (aparece cuando seleccionó alguien)
            if (_seleccionado != null) ...[
              // Card del seleccionado
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC5414B).withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFFC5414B).withOpacity(0.2),
                      backgroundImage: _seleccionado!['foto_perfil_url'] != null
                          ? NetworkImage(_seleccionado!['foto_perfil_url'])
                          : null,
                      child: _seleccionado!['foto_perfil_url'] == null
                          ? Text(
                              (_seleccionado!['nombre'] as String? ?? '?')[0].toUpperCase(),
                              style: const TextStyle(color: Color(0xFFC5414B), fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_seleccionado!['nombre'] ?? ''} ${_seleccionado!['apellido'] ?? ''}'.trim(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _seleccionado = null;
                          _searchController.clear();
                          _comentarioController.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Comentario
              const Text(
                '¿Por qué lo recomendás?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _comentarioController,
                maxLines: 4,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'Ej: Excelente plomero, muy puntual y responsable...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFC5414B)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC5414B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _guardando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Agregar recomendado', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}