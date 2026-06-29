//frontend/lib/services/ubicacion_service.dart
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UbicacionService {
  final _supabase = Supabase.instance.client;

  /// Convierte una dirección de texto a coordenadas (lat/lng)
  Future<Map<String, double>?> geocodificarDireccion({
    required String calle,
    required String numero,
    required String ciudad,
    required String provincia,
  }) async {
    try {
      final direccionCompleta =
          '$calle $numero, $ciudad, $provincia, Argentina';
      List<Location> locations =
          await locationFromAddress(direccionCompleta);

      if (locations.isNotEmpty) {
        return {
          'latitud': locations.first.latitude,
          'longitud': locations.first.longitude,
        };
      }
      return null;
    } catch (e) {
      print('Error geocodificando: $e');
      return null;
    }
  }

  /// Actualiza lat/lng de una ubicación existente en Supabase
  Future<bool> actualizarCoordenadas({
    required int idUbicacion,
    required double latitud,
    required double longitud,
  }) async {
    try {
      await _supabase.from('ubicacion').update({
        'latitud': latitud,
        'longitud': longitud,
      }).eq('id_ubicacion', idUbicacion);
      return true;
    } catch (e) {
      print('Error actualizando coordenadas: $e');
      return false;
    }
  }

  /// Obtiene la ubicación actual del dispositivo (GPS)
  Future<Position?> obtenerUbicacionActual() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Calcula la distancia en km entre dos puntos geográficos
  double calcularDistanciaKm({
    required double latOrigen,
    required double lngOrigen,
    required double latDestino,
    required double lngDestino,
  }) {
    return Geolocator.distanceBetween(
          latOrigen,
          lngOrigen,
          latDestino,
          lngDestino,
        ) /
        1000;
  }

  /// Obtiene una ubicación por su ID con lat/lng, geocodificando si es necesario
  Future<Map<String, dynamic>?> obtenerUbicacionConCoordenadas(
      int idUbicacion) async {
    try {
      final ubicacion = await _supabase
          .from('ubicacion')
          .select()
          .eq('id_ubicacion', idUbicacion)
          .single();

      // Si no tiene coordenadas, intentamos geocodificar
      if (ubicacion['latitud'] == null || ubicacion['longitud'] == null) {
        final coords = await geocodificarDireccion(
          calle: ubicacion['calle'] ?? '',
          numero: ubicacion['numero'] ?? '',
          ciudad: ubicacion['ciudad'] ?? '',
          provincia: ubicacion['provincia'] ?? '',
        );

        if (coords != null) {
          await actualizarCoordenadas(
            idUbicacion: idUbicacion,
            latitud: coords['latitud']!,
            longitud: coords['longitud']!,
          );
          ubicacion['latitud'] = coords['latitud'];
          ubicacion['longitud'] = coords['longitud'];
        }
      }

      return ubicacion;
    } catch (e) {
      print('Error obteniendo ubicación: $e');
      return null;
    }
  }
}