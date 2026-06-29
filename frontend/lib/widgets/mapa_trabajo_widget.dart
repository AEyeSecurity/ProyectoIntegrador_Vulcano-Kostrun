// frontend/lib/widgets/mapa_trabajo_widget.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/ubicacion_service.dart';

class MapaTrabajoWidget extends StatefulWidget {
  final double latitudTrabajo;
  final double longitudTrabajo;
  final String direccionTrabajo;

  const MapaTrabajoWidget({
    Key? key,
    required this.latitudTrabajo,
    required this.longitudTrabajo,
    required this.direccionTrabajo,
  }) : super(key: key);

  @override
  State<MapaTrabajoWidget> createState() => _MapaTrabajoWidgetState();
}

class _MapaTrabajoWidgetState extends State<MapaTrabajoWidget> {
  final UbicacionService _ubicacionService = UbicacionService();
  Position? _posicionActual;
  double? _distanciaKm;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarUbicacionYDistancia();
  }

  Future<void> _cargarUbicacionYDistancia() async {
    try {
      final posicion = await _ubicacionService.obtenerUbicacionActual();

      if (posicion != null) {
        final distancia = _ubicacionService.calcularDistanciaKm(
          latOrigen: posicion.latitude,
          lngOrigen: posicion.longitude,
          latDestino: widget.latitudTrabajo,
          lngDestino: widget.longitudTrabajo,
        );

        setState(() {
          _posicionActual = posicion;
          _distanciaKm = distancia;
          _cargando = false;
        });
      } else {
        setState(() {
          _error = 'No se pudo obtener tu ubicación';
          _cargando = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al cargar el mapa';
        _cargando = false;
      });
    }
  }

  LatLngBounds _calcularBounds() {
    final latTrabajo = widget.latitudTrabajo;
    final lngTrabajo = widget.longitudTrabajo;

    if (_posicionActual == null) {
      return LatLngBounds(
        southwest: LatLng(latTrabajo - 0.01, lngTrabajo - 0.01),
        northeast: LatLng(latTrabajo + 0.01, lngTrabajo + 0.01),
      );
    }

    final latUsuario = _posicionActual!.latitude;
    final lngUsuario = _posicionActual!.longitude;

    return LatLngBounds(
      southwest: LatLng(
        latTrabajo < latUsuario ? latTrabajo : latUsuario,
        lngTrabajo < lngUsuario ? lngTrabajo : lngUsuario,
      ),
      northeast: LatLng(
        latTrabajo > latUsuario ? latTrabajo : latUsuario,
        lngTrabajo > lngUsuario ? lngTrabajo : lngUsuario,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LatLng posicionTrabajo = LatLng(
      widget.latitudTrabajo,
      widget.longitudTrabajo,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chip de distancia
        if (_distanciaKm != null)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFC5414B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFC5414B).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.directions_walk,
                  size: 16,
                  color: Color(0xFFC5414B),
                ),
                const SizedBox(width: 6),
                Text(
                  _distanciaKm! < 1
                      ? 'A ${(_distanciaKm! * 1000).toInt()} metros de vos'
                      : 'A ${_distanciaKm!.toStringAsFixed(1)} km de vos',
                  style: const TextStyle(
                    color: Color(0xFFC5414B),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

        // El mapa
        SizedBox(
          height: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildMapaSinUbicacion(posicionTrabajo)
                    : GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _posicionActual != null
                              ? LatLng(
                                  (widget.latitudTrabajo +
                                          _posicionActual!.latitude) /
                                      2,
                                  (widget.longitudTrabajo +
                                          _posicionActual!.longitude) /
                                      2,
                                )
                              : posicionTrabajo,
                          zoom: _posicionActual != null ? 11 : 14,
                        ),
                        onMapCreated: (controller) {
                          if (_posicionActual != null) {
                            final bounds = _calcularBounds();
                            Future.delayed(
                              const Duration(milliseconds: 500),
                              () {
                                controller.animateCamera(
                                  CameraUpdate.newLatLngBounds(bounds, 60),
                                );
                              },
                            );
                          }
                        },
                        markers: {
                          Marker(
                            markerId: const MarkerId('trabajo'),
                            position: posicionTrabajo,
                            infoWindow: InfoWindow(
                              title: 'Lugar de trabajo',
                              snippet: widget.direccionTrabajo,
                            ),
                            icon: BitmapDescriptor.defaultMarkerWithHue(210),
                          
                          ),
                          if (_posicionActual != null)
                            Marker(
                              markerId: const MarkerId('usuario'),
                              position: LatLng(
                                _posicionActual!.latitude,
                                _posicionActual!.longitude,
                              ),
                              infoWindow:
                                  const InfoWindow(title: '📍 Estás acá'),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueGreen,
                              ),
                            ),
                        },
                        myLocationEnabled: false,
                        zoomControlsEnabled: true,
                        mapToolbarEnabled: false,
                        liteModeEnabled: false,
                      ),
          ),
        ),
      ],
    );
  }

  /// Muestra el mapa solo con el pin del trabajo (sin ubicación del usuario)
  Widget _buildMapaSinUbicacion(LatLng posicionTrabajo) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: posicionTrabajo,
        zoom: 15,
      ),
      markers: {
        Marker(
          markerId: const MarkerId('trabajo'),
          position: posicionTrabajo,
          infoWindow: InfoWindow(
            title: 'Lugar de trabajo',
            snippet: widget.direccionTrabajo,
          ),
        ),
      },
      myLocationEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }
}