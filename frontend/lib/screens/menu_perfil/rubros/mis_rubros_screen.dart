// lib/screens/user/menu_perfil/mis_rubros_screen.dart
import 'package:flutter/material.dart';
import '../../../services/menu_perfil/rubro_service.dart';
import '../../../models/menu_perfil/rubro_model.dart';
import '../../../utils/icon_helper.dart';

class MisRubrosScreen extends StatefulWidget {
  const MisRubrosScreen({Key? key}) : super(key: key);

  @override
  State<MisRubrosScreen> createState() => _MisRubrosScreenState();
}

class _MisRubrosScreenState extends State<MisRubrosScreen> {
  List<Rubro> _misRubros = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarRubros();
  }

  Future<void> _cargarRubros() async {
    setState(() => _isLoading = true);
    
    try {
      final rubros = await RubroService.getUserRubros();
      setState(() {
        _misRubros = rubros;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar rubros: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _eliminarRubro(Rubro rubro) async {
    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Rubro'),
        content: Text('¿Estás seguro de que deseas eliminar "${rubro.nombre}" de tus rubros?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await RubroService.removeUserRubro(rubro.idRubro);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Rubro eliminado correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      _cargarRubros(); // Recargar lista
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar rubro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _agregarRubros() async {
    final result = await Navigator.pushNamed(
      context,
      '/rubros-bubbles',
      arguments: {
        'modoEdicion': true, // Indicar que está en modo edición
        'rubrosExistentes': _misRubros.map((r) => r.nombre).toList(),
      },
    );

    if (result == true) {
      _cargarRubros();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Rubros agregados correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 235, 176, 181),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC5414B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mis Rubros',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _misRubros.isEmpty
              ? _buildEmptyState()
              : _buildRubrosList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarRubros,
        backgroundColor: const Color(0xFFC5414B),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Agregar Rubros',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFC5414B).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.work_outline,
                size: 60,
                color: Color(0xFFC5414B),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No tienes rubros asignados',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Agrega rubros para que los empleadores puedan encontrarte más fácilmente',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _agregarRubros,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC5414B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text(
                'Agregar Rubros',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRubrosList() {
    return Column(
      children: [
        // Header con información
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC5414B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.work,
                      color: Color(0xFFC5414B),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tienes ${_misRubros.length} ${_misRubros.length == 1 ? "rubro" : "rubros"}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Los empleadores pueden encontrarte por estos rubros',
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
            ],
          ),
        ),

        // Lista de rubros
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: _misRubros.length,
            itemBuilder: (context, index) {
              final rubro = _misRubros[index];
              return _buildRubroCard(rubro);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRubroCard(Rubro rubro) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Opcional: Mostrar detalles del rubro
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Ícono
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC5414B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    IconHelper.getIcon(rubro.iconName),
                    color: const Color(0xFFC5414B),
                    size: 28,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Información
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rubro.nombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (rubro.descripcion.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          rubro.descripcion,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Botón eliminar
                IconButton(
                  onPressed: () => _eliminarRubro(rubro),
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                  tooltip: 'Eliminar rubro',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}