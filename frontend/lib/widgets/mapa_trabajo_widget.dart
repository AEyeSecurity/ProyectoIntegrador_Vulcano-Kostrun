// frontend/lib/widgets/mapa_trabajo_widget.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
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
  static const String _apiKey = 'AIzaSyDZ4kxXE3BenwTktcn1ppWE1WJ4ve__ulU';

  final UbicacionService _ubicacionService = UbicacionService();
  Position? _posicionActual;
  double? _distanciaKm;
  String? _duracionAuto;
  String? _duracionCaminando;
  String? _duracionTransporte;
  bool _cargando = true;
  String? _error;
  Set<Polyline> _polylines = {};

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
        });

        // Obtener rutas en paralelo
        await Future.wait([
          _obtenerRuta(posicion, 'driving'),
          _obtenerDuracion(posicion, 'walking'),
          _obtenerDuracion(posicion, 'transit'),
        ]);

        setState(() {
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

  Future<void> _obtenerRuta(Position origen, String mode) async {
    try {
      final url =
          'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origen.latitude},${origen.longitude}'
          '&destination=${widget.latitudTrabajo},${widget.longitudTrabajo}'
          '&mode=$mode'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final polylineEncoded = route['overview_polyline']['points'];
          final leg = route['legs'][0];

          final puntos = _decodificarPolyline(polylineEncoded);

          setState(() {
            _duracionAuto = leg['duration']['text'];
            _polylines = {
              Polyline(
                polylineId: const PolylineId('ruta'),
                points: puntos,
                color: const Color(0xFFC5414B),
                width: 4,
              ),
            };
          });
        }
      }
    } catch (e) {
      print('Error obteniendo ruta ($mode): $e');
    }
  }

  Future<void> _obtenerDuracion(Position origen, String mode) async {
    try {
      final url =
          'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origen.latitude},${origen.longitude}'
          '&destination=${widget.latitudTrabajo},${widget.longitudTrabajo}'
          '&mode=$mode'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final leg = data['routes'][0]['legs'][0];
          final duracion = leg['duration']['text'];

          setState(() {
            if (mode == 'walking') {
              _duracionCaminando = duracion;
            } else if (mode == 'transit') {
              _duracionTransporte = duracion;
            }
          });
        }
      }
    } catch (e) {
      print('Error obteniendo duración ($mode): $e');
    }
  }

  List<LatLng> _decodificarPolyline(String encoded) {
    List<LatLng> puntos = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int b;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      puntos.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return puntos;
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
        // Chips de distancia y tiempos
        if (_distanciaKm != null)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildChip(
                icon: Icons.straighten,
                texto: _distanciaKm! < 1
                    ? '${(_distanciaKm! * 1000).toInt()} m'
                    : '${_distanciaKm!.toStringAsFixed(1)} km',
              ),
              if (_duracionAuto != null)
                _buildChip(
                  icon: Icons.directions_car,
                  texto: _duracionAuto!,
                ),
              if (_duracionTransporte != null)
                _buildChip(
                  icon: Icons.directions_bus,
                  texto: _duracionTransporte!,
                ),
              if (_duracionCaminando != null)
                _buildChip(
                  icon: Icons.directions_walk,
                  texto: _duracionCaminando!,
                ),
            ],
          ),

        if (_distanciaKm != null) const SizedBox(height: 8),

        // El mapa
        SizedBox(
          height: 220,
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
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueRed,
                            ),
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
                              icon: BitmapDescriptor.defaultMarkerWithHue(210),
                            ),
                        },
                        polylines: _polylines,
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

  Widget _buildChip({required IconData icon, required String texto}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
          Icon(icon, size: 14, color: const Color(0xFFC5414B)),
          const SizedBox(width: 4),
          Text(
            texto,
            style: const TextStyle(
              color: Color(0xFFC5414B),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

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