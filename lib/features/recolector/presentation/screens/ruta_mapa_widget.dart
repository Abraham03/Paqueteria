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

    List<LatLng> caminoCompleto = [];
    Set<String> polylinesVistas = {};

    // Ordenamos las paradas por orden_visita para pegar los pedazos de carretera en el orden correcto
    final paradasOrdenadas = List.from(paradas);
    paradasOrdenadas.sort((a, b) => (a['orden_visita'] ?? 999).compareTo(b['orden_visita'] ?? 999));

    for (var p in paradasOrdenadas) {
      final polyStr = p['ruta_polyline']?.toString() ?? '';
      
      // Si la parada tiene una línea azul y no la hemos decodificado antes...
      if (polyStr.length > 20 && !polylinesVistas.contains(polyStr)) {
        polylinesVistas.add(polyStr);
        // Pegamos este pedazo de carretera al camino total
        caminoCompleto.addAll(_decodificarPolyline(polyStr));
      }
    }

    if (caminoCompleto.isEmpty) {
      // Fallback: Si Mapbox falló por completo, unimos los puntos con líneas rectas
      final fallback = paradas.where((p) => p['id'] != 'END_FORZADO').toList();
      fallback.sort((a, b) => (a['orden_visita'] ?? 999).compareTo(b['orden_visita'] ?? 999));
      
      return fallback.map((p) => LatLng(
        double.tryParse(p['latitud'].toString()) ?? 0.0, 
        double.tryParse(p['longitud'].toString()) ?? 0.0
      )).toList();
    }

    return caminoCompleto;
  }

  // --- ACTUALIZADO: Dibuja exactamente leyendo el ID (START/END) ---
  List<Marker> _construirMarcadores() {
    int contador = 1;
    List<Marker> marcadoresList = [];

    for (var p in paradas) {
      final id = p['id'].toString();
      final lat = double.tryParse(p['latitud'].toString()) ?? 0.0;
      final lng = double.tryParse(p['longitud'].toString()) ?? 0.0;
      
      // 1. Si es el INICIO, dibujamos la Tienda
      if (id == 'START') {
        marcadoresList.add(Marker(
          point: LatLng(lat, lng),
          width: 45, height: 45,
          child: Container(
            decoration: BoxDecoration(color: Colors.black87, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
            child: const Icon(Icons.home, color: Colors.white, size: 20),
          ),
        ));
        continue; // Saltamos al siguiente punto
      }

      // 2. Si es el DESTINO, dibujamos la Bandera
      if (id == 'END' || id == 'END_FORZADO') {
        marcadoresList.add(Marker(
          point: LatLng(lat, lng),
          width: 45, height: 45,
          child: Container(
            decoration: BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
            child: const Icon(Icons.flag, color: Colors.white, size: 20),
          ),
        ));
        continue; // Saltamos al siguiente punto
      }

      // 3. Lógica original para los PAQUETES
      final recolectada = p['estatus'] == 'Recolectada';
      final bool esDesordenada = p['orden_visita'] == 999;

      Color colorFondo = recolectada ? AppColors.success : (esDesordenada ? Colors.amber : AppColors.primary);
      Widget iconoInterno = recolectada
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
              // Ahora construimos los marcadores sin necesidad de mandarle el caminoReal
              markers: _construirMarcadores(), 
            ),
          ],
        ),
      ),
    );
  }
}