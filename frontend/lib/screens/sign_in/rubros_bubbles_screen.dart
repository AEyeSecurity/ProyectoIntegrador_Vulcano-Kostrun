//lib/screens/login/rubros_bubbles_screen.dart
// ✅ ACTUALIZADO: Soporta modo onboarding y modo edición
import 'package:flutter/material.dart';
import '../../models/menu_perfil/rubro_model.dart';
import '../../services/menu_perfil/rubro_service.dart';
import '../../services/auth_service.dart';
import '../../utils/icon_helper.dart';

class RubrosBubblesScreen extends StatefulWidget {
  const RubrosBubblesScreen({Key? key}) : super(key: key);

  @override
  State<RubrosBubblesScreen> createState() => _RubrosBubblesScreenState();
}

class _RubrosBubblesScreenState extends State<RubrosBubblesScreen> {
  // Variables para roles (solo en modo onboarding)
  bool _esEmpleador = false;
  bool _esEmpleado = false;

  // Variables para modo edición
  bool _modoEdicion = false;
  List<String> _rubrosExistentes = [];

  Set<int> selectedRubros = {};
  Set<int> hoveredRubros = {};
  List<Rubro> rubros = [];
  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRubros();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      // Modo onboarding
      _esEmpleador = args['esEmpleador'] ?? false;
      _esEmpleado = args['esEmpleado'] ?? false;
      
      // Modo edición
      _modoEdicion = args['modoEdicion'] ?? false;
      _rubrosExistentes = List<String>.from(args['rubrosExistentes'] ?? []);
      
      print('📋 Modo: ${_modoEdicion ? "EDICIÓN" : "ONBOARDING"}');
      if (_modoEdicion) {
        print('📋 Rubros existentes: $_rubrosExistentes');
      } else {
        print('📋 Roles: empleador=$_esEmpleador, empleado=$_esEmpleado');
      }
    }
  }

  Future<void> _loadRubros() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final loadedRubros = await RubroService.getRubros();

      setState(() {
        rubros = loadedRubros;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  void _handleBubbleTap(int rubroId) {
    setState(() {
      if (selectedRubros.contains(rubroId)) {
        selectedRubros.remove(rubroId);
      } else {
        selectedRubros.add(rubroId);
      }
    });
  }

  void _handleBubbleHover(int rubroId, bool isHovering) {
    setState(() {
      if (isHovering) {
        hoveredRubros.add(rubroId);
      } else {
        hoveredRubros.remove(rubroId);
      }
    });
  }

  Future<void> _refreshRubros() async {
    await _loadRubros();
  }

  // ✅ CONTINUAR EN MODO ONBOARDING
  Future<void> _continuarOnboarding() async {
    if (selectedRubros.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona al menos un rubro'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      // 1. Guardar roles
      print('💾 Guardando roles: empleador=$_esEmpleador, empleado=$_esEmpleado');
      await AuthService.updateUserRoles(
        esEmpleador: _esEmpleador,
        esEmpleado: _esEmpleado,
      );

      // 2. Guardar rubros
      final nombresSeleccionados = rubros
          .where((r) => selectedRubros.contains(r.idRubro))
          .map((r) => r.nombre)
          .toList();

      print('💾 Guardando rubros: $nombresSeleccionados');
      await RubroService.saveUserRubros(nombresSeleccionados);

      // 3. Marcar onboarding completado
      print('✅ Marcando onboarding como completado');
      await AuthService.markOnboardingCompleted();

      if (mounted) {
        print('🚀 Navegando a /main-nav');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/main-nav',
              (route) => false,
              arguments: {'initialTab': 0},
            );
          }
        });
      }
    } catch (error) {
      print('❌ Error en onboarding: $error');

      if (mounted) {
        setState(() => isSaving = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // ✅ GUARDAR EN MODO EDICIÓN
  Future<void> _guardarEdicion() async {
    if (selectedRubros.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona al menos un rubro'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      for (var rubroId in selectedRubros) {
        await RubroService.addUserRubro(rubroId);
      }

      if (mounted) {
        // ✅ Resetear estado ANTES de hacer pop
        setState(() => isSaving = false);
        Navigator.pop(context, true);
      }
    } catch (error) {
      print('❌ Error al guardar rubros: $error');

      if (mounted) {
        setState(() => isSaving = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // ✅ MÉTODO UNIFICADO PARA CONTINUAR
  Future<void> _continuar() async {
    if (_modoEdicion) {
      await _guardarEdicion();
    } else {
      await _continuarOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF374151),
      appBar: AppBar(
        backgroundColor: const Color(0xFF374151),
        elevation: 0,
        // ✅ En modo edición mostrar botón back, en onboarding no
        automaticallyImplyLeading: _modoEdicion,
        leading: _modoEdicion
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          _modoEdicion ? 'Agregar Rubros' : 'Selecciona Rubros',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: isSaving ? null : _refreshRubros,
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text(
                        _modoEdicion
                            ? 'Agrega Nuevos Rubros'
                            : 'Explora Nuestros Rubros',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _modoEdicion
                            ? 'Selecciona rubros adicionales a tu perfil'
                            : 'Selecciona uno o más rubros de tu interés',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[300],
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // Contador de seleccionados
                      if (selectedRubros.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC5414B),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${selectedRubros.length} seleccionado${selectedRubros.length != 1 ? 's' : ''}',
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

                // Content
                Expanded(
                  child: _buildContent(),
                ),

                // Bottom Button
                if (selectedRubros.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    child: ElevatedButton(
                      onPressed: isSaving ? null : _continuar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC5414B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isSaving
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Guardando...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              _modoEdicion
                                  ? 'Guardar (${selectedRubros.length})'
                                  : 'Continuar (${selectedRubros.length})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
              ],
            ),

            // Overlay de loading
            if (isSaving)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFFC5414B)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _modoEdicion
                            ? 'Guardando rubros...'
                            : 'Completando configuración...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5414B)),
            ),
            SizedBox(height: 16),
            Text(
              'Cargando rubros...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Color(0xFFC5414B),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar los rubros',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshRubros,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC5414B),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (rubros.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inbox_outlined,
              color: Colors.grey,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay rubros disponibles',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    // ✅ Filtrar rubros en modo edición (no mostrar los que ya tiene)
    final rubrosDisponibles = _modoEdicion
        ? rubros.where((r) => !_rubrosExistentes.contains(r.nombre)).toList()
        : rubros;

    if (_modoEdicion && rubrosDisponibles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Color(0xFFC5414B),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              '¡Ya tienes todos los rubros!',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No hay rubros adicionales disponibles',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0,
        ),
        itemCount: rubrosDisponibles.length,
        itemBuilder: (context, index) {
          final rubro = rubrosDisponibles[index];
          final isSelected = selectedRubros.contains(rubro.idRubro);
          final isHovered = hoveredRubros.contains(rubro.idRubro);

          return _buildBubble(rubro, isSelected, isHovered);
        },
      ),
    );
  }

  Widget _buildBubble(Rubro rubro, bool isSelected, bool isHovered) {
    return MouseRegion(
      onEnter: (_) => _handleBubbleHover(rubro.idRubro, true),
      onExit: (_) => _handleBubbleHover(rubro.idRubro, false),
      child: GestureDetector(
        onTap: () => _handleBubbleTap(rubro.idRubro),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFC5414B) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFC5414B)
                  : const Color(0xFFE5E7EB),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFFC5414B).withOpacity(0.4)
                    : Colors.black.withOpacity(0.15),
                blurRadius: isSelected ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isHovered
                ? _buildDescriptionContent(rubro, isSelected)
                : _buildNormalContent(rubro, isSelected),
          ),
        ),
      ),
    );
  }

  Widget _buildNormalContent(Rubro rubro, bool isSelected) {
    return Column(
      key: const ValueKey('normal'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          IconHelper.getIcon(rubro.iconName),
          size: 42,
          color: isSelected ? Colors.white : const Color(0xFFC5414B),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            rubro.nombre,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFFC5414B),
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionContent(Rubro rubro, bool isSelected) {
    return Container(
      key: const ValueKey('description'),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 28,
            color: isSelected ? Colors.white : const Color(0xFFC5414B),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Center(
              child: Text(
                rubro.descripcion,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF374151),
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}