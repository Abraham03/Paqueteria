import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';

class RutaMapaWidget extends StatelessWidget {
  final List<dynamic> paradas;

  const RutaMapaWidget({super.key, required this.paradas});

  List<LatLng> _decodificarPolyline(String encoded) {
    if (encoded.isEmpty) return [];
    
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    try {
      while (index < len) {
        int b, shift = 0, result = 0;
        do {
          b = encoded.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20);
        int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
        lat += dlat;

        shift = 0;
        result = 0;
        do {
          b = encoded.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20);
        int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
        lng += dlng;

        poly.add(LatLng(lat / 100000.0, lng / 100000.0));
      }
    } catch (e) {
      debugPrint("Error decodificando polyline: $e");
    }
    return poly;
  }

  List<LatLng> _extraerCaminoReal() {
    if (paradas.isEmpty) return [];

    String? polylineCompleta;
    for (var p in paradas) {
      final polyStr = p['ruta_polyline']?.toString() ?? '';
      if (polyStr.length > 20) { 
        polylineCompleta = polyStr;
        break;
      }
    }

    if (polylineCompleta == null) {
      return paradas.map((p) => LatLng(
        double.tryParse(p['latitud'].toString()) ?? 0.0, 
        double.tryParse(p['longitud'].toString()) ?? 0.0
      )).toList();
    }

    return _decodificarPolyline(polylineCompleta);
  }

  // --- ACTUALIZADO: RECIBE EL CAMINO PARA PONER LA TIENDA Y BANDERA ---
  List<Marker> _construirMarcadores(List<LatLng> caminoReal) {
    int contador = 1;
    List<Marker> marcadoresList = [];

    // 1. Dibujar los paquetes
    for (var p in paradas) {
      // Ignorar fantasmas
      if (p['id'] == 'START' || p['id'] == 'END' || p['id'] == 'END_FORZADO') continue;

      final lat = double.tryParse(p['latitud'].toString()) ?? 0.0;
      final lng = double.tryParse(p['longitud'].toString()) ?? 0.0;
      
      // La lógica original que tenías para decidir los colores (pero omitiendo a start y end que dibujaremos aparte)
      final recolectada = p['estatus'] == 'Recolectada';
      final bool esDesordenada = p['orden_visita'] == 999;

      Widget iconoInterno;
      Color colorFondo;

      colorFondo = recolectada ? AppColors.success : (esDesordenada ? Colors.amber : AppColors.primary);
      iconoInterno = recolectada
          ? const Icon(Icons.check, color: Colors.white, size: 18)
          : Text(
              esDesordenada ? "!" : "${contador++}", 
              style: TextStyle(
                  color: esDesordenada ? Colors.black87 : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
            );

      marcadoresList.add(
        Marker(
          point: LatLng(lat, lng),
          width: 35, 
          height: 35,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              color: colorFondo,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Center(child: iconoInterno),
          ),
        ),
      );
    }
    
    // 2. Dibujar Origen y Destino en los extremos del mapa
    if (caminoReal.length > 1) {
       // Marcador de Inicio (Tienda)
       marcadoresList.add(
         Marker(
           point: caminoReal.first, // El primer punto exacto de la carretera
           width: 45, height: 45,
           child: Container(
             decoration: BoxDecoration(color: Colors.black87, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
             child: const Icon(Icons.storefront, color: Colors.white, size: 20),
           ),
         )
       );

       // Marcador de Destino (Bandera)
       marcadoresList.add(
         Marker(
           point: caminoReal.last, // El último punto exacto de la carretera
           width: 45, height: 45,
           child: Container(
             decoration: BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
             child: const Icon(Icons.flag, color: Colors.white, size: 20),
           ),
         )
       );
    }

    return marcadoresList;
  }

  @override
  Widget build(BuildContext context) {
    if (paradas.isEmpty) return const SizedBox.shrink();

    final caminoReal = _extraerCaminoReal();
    
    final allPoints = paradas.map((p) => LatLng(
        double.tryParse(p['latitud'].toString()) ?? 0.0, 
        double.tryParse(p['longitud'].toString()) ?? 0.0
      )).toList();
    final bounds = allPoints.length > 1 ? LatLngBounds.fromPoints(allPoints) : null;

    return Container(
      height: 280, 
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), 
            blurRadius: 8, 
            offset: const Offset(0, 4)
          ),
        ]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: FlutterMap(
          options: MapOptions(
            initialCameraFit: bounds != null 
              ? CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50.0))
              : null,
            initialCenter: allPoints.isNotEmpty ? allPoints.first : const LatLng(0, 0),
            initialZoom: allPoints.length == 1 ? 15.0 : 13.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.techsolutions.paqueteria', 
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: caminoReal,
                  strokeWidth: 6.0, 
                  color: AppColors.primary.withValues(alpha: 0.85), 
                  strokeJoin: StrokeJoin.round, 
                  strokeCap: StrokeCap.round, 
                ),
              ],
            ),
            MarkerLayer(
              // PASAMOS EL CAMINO REAL AQUÍ
              markers: _construirMarcadores(caminoReal), 
            ),
          ],
        ),
      ),
    );
  }
}