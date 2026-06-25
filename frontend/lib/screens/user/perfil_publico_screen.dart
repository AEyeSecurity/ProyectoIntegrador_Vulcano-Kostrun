// lib/screens/profile/perfil_compartido_screen.dart
// 🌐 PANTALLA DE PERFIL PÚBLICO (compartido)

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/menu_perfil/perfil_service.dart';
import '../../models/menu_perfil/perfil_model.dart';
import '../menu_perfil/recomendados/recomendados_section.dart';

class PerfilCompartidoScreen extends StatefulWidget {
  final int userId;

  const PerfilCompartidoScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<PerfilCompartidoScreen> createState() => _PerfilCompartidoScreenState();
}

class _PerfilCompartidoScreenState extends State<PerfilCompartidoScreen> {
  final PerfilService _perfilService = PerfilService();

  bool _isLoading = true;
  String _nombre = '';
  String? _ubicacion;
  String? _fotoPerfil; // ✅ NUEVO
  double _calificacionPromedio = 0.0;
  int _totalResenias = 0;
  int _trabajosCompletados = 0;
  List<ReseniaModel> _resenias = [];
  List<CategoriaModel> _categorias = [];
  bool _esEmpleado = false;
  int? _idUsuarioLogueado;

  @override
  void initState() {
    super.initState();
    _cargarDatosPerfil();
  }

  Future<void> _cargarDatosPerfil() async {
    setState(() => _isLoading = true);

    try {
      print('🔍 Cargando perfil del usuario: ${widget.userId}');

      // Obtener id del usuario logueado para saber si es propio perfil
      try {
        final supabase = Supabase.instance.client;
        final authUser = supabase.auth.currentUser;
        if (authUser != null) {
          final usuarioResp = await supabase
              .from('usuario')
              .select('id_usuario')
              .eq('auth_user_id', authUser.id)
              .single();
          _idUsuarioLogueado = usuarioResp['id_usuario'] as int;
        }
      } catch (_) {}

      final datosBasicos =
          await _perfilService.getDatosBasicosUsuario(widget.userId);
      print('📊 datosBasicos recibidos: $datosBasicos');

      String nombreCompleto = '';

      if (datosBasicos['usuario_persona'] != null) {
        print('   👤 Tiene usuario_persona');
        final personaData = datosBasicos['usuario_persona'];
        final persona = personaData is List && (personaData as List).isNotEmpty
            ? personaData[0]
            : personaData;

        if (persona != null && persona is Map<String, dynamic>) {
          final nombre = persona['nombre']?.toString() ?? '';
          final apellido = persona['apellido']?.toString() ?? '';
          nombreCompleto = '$nombre $apellido'.trim();
          _fotoPerfil = persona['foto_perfil_url']?.toString(); // ✅
          print('      ✅ Nombre construido: "$nombreCompleto"');
        }
      } else if (datosBasicos['usuario_empresa'] != null) {
        print('   🏢 Tiene usuario_empresa');
        final empresaData = datosBasicos['usuario_empresa'];
        final empresa = empresaData is List && (empresaData as List).isNotEmpty
            ? empresaData[0]
            : empresaData;

        if (empresa != null && empresa is Map<String, dynamic>) {
          nombreCompleto = empresa['nombre_corporativo']?.toString() ?? '';
          _fotoPerfil = empresa['logo_url']?.toString(); // ✅
          print('      ✅ Nombre empresa: "$nombreCompleto"');
        }
      }

      if (nombreCompleto.isEmpty) {
        nombreCompleto = 'Usuario';
      }

      _nombre = nombreCompleto;

      _resenias = await _perfilService.getReseniasUsuario(widget.userId);
      _totalResenias = _resenias.length;
      _calificacionPromedio =
          await _perfilService.getPromedioCalificacion(widget.userId);
      _ubicacion = await _perfilService.getUbicacionUsuario(widget.userId);
      _esEmpleado = await _perfilService.esEmpleado(widget.userId);

      if (_esEmpleado) {
        _categorias = await _perfilService.getCategoriasEmpleado(widget.userId);
        _trabajosCompletados =
            await _perfilService.contarTrabajosCompletados(widget.userId);
      }

      print('✅ Perfil cargado completamente');
      setState(() => _isLoading = false);
    } catch (e, stackTrace) {
      print('❌ ERROR cargando perfil: $e');
      print('   Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _nombre = 'Error al cargar';
      });
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
          'Perfil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Compartir próximamente')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5414B)),
              ),
            )
          : RefreshIndicator(
              onRefresh: _cargarDatosPerfil,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildEstadisticas(),
                    const SizedBox(height: 20),
                    if (_categorias.isNotEmpty) _buildCategorias(),
                    if (_categorias.isNotEmpty) const SizedBox(height: 20),
                    _buildResenias(),
                    const SizedBox(height: 20),
                    RecomendadosSection(
                      idUsuarioPerfil: widget.userId,
                      esPropioPeril: _idUsuarioLogueado == widget.userId,
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    String getIniciales() {
      if (_nombre.isEmpty ||
          _nombre == 'Usuario' ||
          _nombre == 'Error al cargar') {
        return '?';
      }
      final palabras = _nombre.split(' ');
      if (palabras.length >= 2 &&
          palabras[0].isNotEmpty &&
          palabras[1].isNotEmpty) {
        return '${palabras[0][0]}${palabras[1][0]}'.toUpperCase();
      }
      return _nombre[0].toUpperCase();
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFC5414B),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          // ✅ CircleAvatar con foto de perfil
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white,
            backgroundImage:
                _fotoPerfil != null ? NetworkImage(_fotoPerfil!) : null,
            child: _fotoPerfil == null
                ? Text(
                    getIniciales(),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC5414B),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            _nombre,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (_ubicacion != null && _ubicacion!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Text(
                  _ubicacion!,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 28),
              const SizedBox(width: 8),
              Text(
                _calificacionPromedio.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '($_totalResenias ${_totalResenias == 1 ? 'reseña' : 'reseñas'})',
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticas() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (_esEmpleado)
            Expanded(
              child: _buildStatCard(
                icon: Icons.work,
                label: 'Trabajos\nCompletados',
                value: '$_trabajosCompletados',
                color: Colors.green,
              ),
            ),
          if (_esEmpleado) const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.star,
              label: 'Calificación\nPromedio',
              value: _calificacionPromedio.toStringAsFixed(1),
              color: Colors.amber,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.chat_bubble,
              label: 'Reseñas\nRecibidas',
              value: '$_totalResenias',
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
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
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorias() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏷️ Especialidades',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categorias.map((categoria) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFC5414B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFC5414B).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  categoria.nombre,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFC5414B),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResenias() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '⭐ Reseñas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '$_totalResenias ${_totalResenias == 1 ? 'reseña' : 'reseñas'}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_resenias.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.star_border, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Aún no hay reseñas',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _resenias.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildReseniaCard(_resenias[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildReseniaCard(ReseniaModel resenia) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFC5414B).withOpacity(0.2),
                backgroundImage: resenia.fotoPerfilEmisor != null
                    ? NetworkImage(resenia.fotoPerfilEmisor!)
                    : null,
                child: resenia.fotoPerfilEmisor == null
                    ? Text(
                        resenia.getIniciales(),
                        style: const TextStyle(
                          color: Color(0xFFC5414B),
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resenia.nombreEmisor,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      _formatearFecha(resenia.fecha),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < resenia.puntuacion ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  );
                }),
              ),
            ],
          ),
          if (resenia.comentario != null && resenia.comentario!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              resenia.comentario!,
              style:
                  TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    try {
      final ahora = DateTime.now();
      final diferencia = ahora.difference(fecha);

      if (diferencia.inDays == 0) return 'Hoy';
      if (diferencia.inDays == 1) return 'Ayer';
      if (diferencia.inDays < 7) return 'Hace ${diferencia.inDays} días';
      if (diferencia.inDays < 30)
        return 'Hace ${(diferencia.inDays / 7).floor()} semanas';
      if (diferencia.inDays < 365)
        return 'Hace ${(diferencia.inDays / 30).floor()} meses';
      return 'Hace ${(diferencia.inDays / 365).floor()} años';
    } catch (e) {
      return 'Fecha desconocida';
    }
  }
}