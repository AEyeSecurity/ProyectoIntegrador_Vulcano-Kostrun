//lib/screens/menu_perfil/user_menu_screen.dart

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart' as AppUser;
import '../../components/primary_button.dart';
import '../../services/calificacion_service.dart';
import 'calificaciones_pendientes_screen.dart';
import '../../services/baja_cuenta_service.dart';

class UserMenuScreen extends StatefulWidget {
  const UserMenuScreen({Key? key}) : super(key: key);

  @override
  State<UserMenuScreen> createState() => _UserMenuScreenState();
}

class _UserMenuScreenState extends State<UserMenuScreen> {
  AppUser.User? currentUser;
  bool isLoading = true;
  bool _esAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await AuthService.getCurrentUserData();
      final admin = await BajaCuentaService.esAdmin();
      setState(() {
        currentUser = userData;
        isLoading = false;
        _esAdmin = admin;
      });
    } catch (e) {
      print('Error cargando datos del usuario: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _logout() async {
    try {
      await AuthService.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cerrar sesión: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToScreen(String screenName) {
    switch (screenName) {
      case 'Mi Perfil':
        Navigator.pushNamed(context, '/perfil');
        break;
      case 'Mis Empleados':
        Navigator.pushNamed(context, '/mis-empleados');
        break;
      case 'Mis Trabajos':
        Navigator.pushNamed(context, '/trabajos');
        break;
      case 'Calificar':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CalificacionesPendientesScreen(),
          ),
        );
        break;
      case 'Mis Postulaciones':
        Navigator.pushNamed(context, '/mis-postulaciones');
        break;
      case 'Mis Rubros':
        Navigator.pushNamed(context, '/mis-rubros');
        break;
      case 'Mis Ubicaciones':
        Navigator.pushNamed(context, '/ubicaciones');
        break;
      case 'Agenda':
        Navigator.pushNamed(context, '/agenda');
        break;
      case 'Calendario':
        Navigator.pushNamed(context, '/calendario');
        break;
      case 'Configuración':
        Navigator.pushNamed(context, '/configuracion');
        break;
      case 'Solicitudes':
        Navigator.pushNamed(context, '/admin-solicitudes');
        break;

      default:
        _showComingSoon(screenName);
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Próximamente: $feature'),
        backgroundColor: const Color(0xFFC5414B),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC5414B),
        elevation: 0,
        title: const Text(
          'Inicio',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Cerrar Sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5414B)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeHeader(),
                  const SizedBox(height: 24),
                  _buildReputacionDual(),
                  const SizedBox(height: 24),
                  _buildExpandedMenu(),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: 'Cerrar Sesión',
                    onPressed: _logout,
                    variant: 'secondary',
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeHeader() {
    final nombre = currentUser?.displayName ?? 'Usuario';

    // ✅ Obtener foto/logo según tipo de usuario
    String? fotoUrl;
    if (currentUser?.isPersona == true && currentUser?.persona != null) {
      fotoUrl = currentUser?.persona?.fotoPerfil;
    } else if (currentUser?.isEmpresa == true && currentUser?.empresa != null) {
      fotoUrl = currentUser?.empresa?.logoUrl;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC5414B), Color(0xFFE85A4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC5414B).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white.withOpacity(0.3),
              backgroundImage: fotoUrl != null && fotoUrl.isNotEmpty
                  ? NetworkImage(fotoUrl)
                  : null,
              child: fotoUrl == null || fotoUrl.isEmpty
                  ? Icon(
                      currentUser?.isEmpresa == true
                          ? Icons.business
                          : Icons.person,
                      size: 40,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¡Bienvenido!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'Accede a todas tus herramientas desde aquí',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReputacionDual() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tu Reputación',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<Map<String, dynamic>>(
          future: _obtenerReputacionGeneral(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!;
            final esEmpleado = data['es_empleado'] as bool;
            final esEmpleador = data['es_empleador'] as bool;

            if (esEmpleador && !esEmpleado) {
              return _buildReputacionCard(
                titulo: 'Como Empleador',
                icono: Icons.business_center,
                color: const Color(0xFF2196F3),
                rol: 'EMPLEADOR',
              );
            }

            if (esEmpleado && !esEmpleador) {
              return _buildReputacionCard(
                titulo: 'Como Empleado',
                icono: Icons.work_outline,
                color: const Color(0xFF4CAF50),
                rol: 'EMPLEADO',
              );
            }

            return Row(
              children: [
                Expanded(
                  child: _buildReputacionCard(
                    titulo: 'Como Empleador',
                    icono: Icons.business_center,
                    color: const Color(0xFF2196F3),
                    rol: 'EMPLEADOR',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildReputacionCard(
                    titulo: 'Como Empleado',
                    icono: Icons.work_outline,
                    color: const Color(0xFF4CAF50),
                    rol: 'EMPLEADO',
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _obtenerReputacionGeneral() async {
    final esEmpleado = currentUser?.persona?.esEmpleado ?? false;
    final esEmpleador = currentUser?.persona?.esEmpleador ?? false;

    return {
      'es_empleado': esEmpleado,
      'es_empleador': esEmpleador,
    };
  }

  Widget _buildReputacionCard({
    required String titulo,
    required IconData icono,
    required Color color,
    required String rol,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/reputacion-detalle',
          arguments: rol,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            FutureBuilder<double>(
              future: CalificacionService.obtenerPromedioPorRol(
                usuarioId: currentUser?.idUsuario ?? 0,
                rol: rol,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFC5414B)),
                    ),
                  );
                }

                final rating = snapshot.data!;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedMenu() {
    final esEmpresa = currentUser?.isEmpresa ?? false;

    final menuItems = [
      {'title': 'Mi Perfil', 'icon': Icons.person, 'color': Colors.blue},

      // ✅ NUEVO: Solo mostrar para empresas
      if (esEmpresa)
        {'title': 'Mis Empleados', 'icon': Icons.people, 'color': Colors.teal},

      {'title': 'Mis Rubros', 'icon': Icons.category, 'color': Colors.purple},
      {
        'title': 'Mis Ubicaciones',
        'icon': Icons.location_on,
        'color': Colors.orange
      },
      {'title': 'Mis Trabajos', 'icon': Icons.work, 'color': Colors.green},
      {
        'title': 'Mis Postulaciones',
        'icon': Icons.assignment,
        'color': Colors.pink
      },
      {'title': 'Calificar', 'icon': Icons.star_rate, 'color': Colors.amber},
      {'title': 'Agenda', 'icon': Icons.event_note, 'color': Colors.indigo},
      {
        'title': 'Calendario',
        'icon': Icons.calendar_today,
        'color': Colors.red
      },
      {'title': 'Configuración', 'icon': Icons.settings, 'color': Colors.grey},

      // ✅ Solo mostrar para administradores
      if (_esAdmin)
        {'title': 'Solicitudes', 'icon': Icons.admin_panel_settings, 'color': Colors.deepOrange},

    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menú Principal',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: menuItems.length,
          itemBuilder: (context, index) {
            final item = menuItems[index];

            return _buildMenuCard(
              item['title'] as String,
              item['icon'] as IconData,
              item['color'] as Color,
              () => _navigateToScreen(item['title'] as String),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
