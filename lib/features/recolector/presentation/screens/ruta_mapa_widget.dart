import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';

class RutaMapaWidget extends StatelessWidget {
  final List<dynamic> paradas;

  const RutaMapaWidget({super.key, required this.paradas});

  // --- MÉTODOS PRIVADOS (SRP y Código Limpio) ---
  
  /// Transforma la lista de datos crudos (JSON) a entidades seguras (LatLng)
  List<LatLng> _extraerCoordenadas() {
    return paradas.map((p) {
      final lat = double.tryParse(p['latitud'].toString()) ?? 0.0;
      final lng = double.tryParse(p['longitud'].toString()) ?? 0.0;
      return LatLng(lat, lng);
    }).toList();
  }

  /// Construye los marcadores del mapa basados en el estatus de recolección
  List<Marker> _construirMarcadores() {
    return paradas.asMap().entries.map((entry) {
      final p = entry.value;
      final lat = double.tryParse(p['latitud'].toString()) ?? 0.0;
      final lng = double.tryParse(p['longitud'].toString()) ?? 0.0;
      final recolectada = p['estatus'] == 'Recolectada';

      return Marker(
        point: LatLng(lat, lng),
        width: 32,
        height: 32,
        child: Container(
          decoration: BoxDecoration(
            color: recolectada ? AppColors.success : AppColors.accent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3), 
                blurRadius: 4, 
                offset: const Offset(0, 2)
              )
            ],
          ),
          child: Center(
            child: recolectada
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text(
                  '${p['orden_visita'] ?? '-'}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (paradas.isEmpty) return const SizedBox.shrink();

    final points = _extraerCoordenadas();
    
    // Calculamos el encuadre para asegurar que todos los puntos sean visibles
    final bounds = points.length > 1 ? LatLngBounds.fromPoints(points) : null;

    return Container(
      height: 250,
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
            initialCenter: points.length == 1 ? points.first : const LatLng(0, 0),
            initialZoom: points.length == 1 ? 15.0 : 13.0,
            interactionOptions: const InteractionOptions(
              // Permitimos interacción pero bloqueamos rotación para mejor UX del chofer
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
                  points: points,
                  strokeWidth: 4.0,
                  color: AppColors.primary.withValues(alpha: 0.8),
                  // SOLUCIÓN: StrokePattern SIN el modificador const
                  pattern: StrokePattern.dashed(segments: [10.0, 10.0]), 
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