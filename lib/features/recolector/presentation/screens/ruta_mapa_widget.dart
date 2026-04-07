import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';

class RutaMapaWidget extends StatelessWidget {
  final List<dynamic> paradas;

  const RutaMapaWidget({super.key, required this.paradas});

  // --- NUEVA FUNCIÓN: Decodificador Matemático (Sin paquetes de terceros) ---
  List<LatLng> _decodificarPolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

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

      // Mapbox Polyline v5 usa 5 decimales (1E5)
      poly.add(LatLng(lat / 100000.0, lng / 100000.0));
    }
    return poly;
  }

  // --- FUNCIÓN: Extraer la carretera ---
  List<LatLng> _extraerCaminoReal() {
    if (paradas.isEmpty || paradas[0]['ruta_polyline'] == null) {
      // Respaldo: Si no hay geometría, hace líneas rectas
      return paradas.map((p) => LatLng(
        double.tryParse(p['latitud'].toString()) ?? 0.0, 
        double.tryParse(p['longitud'].toString()) ?? 0.0
      )).toList();
    }

    final polyline = paradas[0]['ruta_polyline'] as String;
    return _decodificarPolyline(polyline);
  }

  List<Marker> _construirMarcadores() {
    return paradas.asMap().entries.map((entry) {
      final p = entry.value;
      final lat = double.tryParse(p['latitud'].toString()) ?? 0.0;
      final lng = double.tryParse(p['longitud'].toString()) ?? 0.0;
      final recolectada = p['estatus'] == 'Recolectada';

      return Marker(
        point: LatLng(lat, lng),
        width: 35, // Ligeramente más grandes
        height: 35,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            color: recolectada ? AppColors.success : AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2), 
                blurRadius: 6, 
                offset: const Offset(0, 3)
              )
            ],
          ),
          child: Center(
            child: recolectada
              ? const Icon(Icons.check, color: Colors.white, size: 18)
              : Text(
                  '${p['orden_visita'] ?? '-'}',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (paradas.isEmpty) return const SizedBox.shrink();

    final caminoReal = _extraerCaminoReal();
    
    // Calculamos el encuadre para asegurar que TODOs EL CAMINO sea visible
    final bounds = caminoReal.length > 1 ? LatLngBounds.fromPoints(caminoReal) : null;

    return Container(
      height: 280, // Ligeramente más alto para mejor visibilidad
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
              ? CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40.0))
              : null,
            initialCenter: caminoReal.length == 1 ? caminoReal.first : const LatLng(0, 0),
            initialZoom: caminoReal.length == 1 ? 15.0 : 13.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.techsolutions.paqueteria', 
            ),
            // LÍNEA DE CARRETERA REALISTA
            PolylineLayer(
              polylines: [
                Polyline(
                  points: caminoReal,
                  strokeWidth: 5.0,
                  color: AppColors.primary.withValues(alpha: 0.8), // Color sólido y un poco más gruesa
                  // Borramos la línea punteada para que se vea como GPS real
                ),
              ],
            ),
            MarkerLayer(
              markers: _construirMarcadores(),
            ),
          ],
        ),
      ),
    );
  }
}