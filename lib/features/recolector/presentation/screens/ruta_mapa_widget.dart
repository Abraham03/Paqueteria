import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';

class RutaMapaWidget extends StatelessWidget {
  final List<dynamic> paradas;

  const RutaMapaWidget({super.key, required this.paradas});

  List<Marker> _construirMarcadores() {
    int contadorFallback = 1; // Solo se usa si por alguna razón la BD no manda el orden
    List<Marker> marcadoresList = [];

    for (var p in paradas) {
      final id = p['id'].toString();
      final lat = double.tryParse(p['latitud'].toString()) ?? 0.0;
      final lng = double.tryParse(p['longitud'].toString()) ?? 0.0;
      
      // 1. Tienda (Inicio)
      if (id == 'START') {
        marcadoresList.add(Marker(
          point: LatLng(lat, lng),
          width: 45, height: 45,
          child: Container(
            decoration: BoxDecoration(color: Colors.black87, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
            child: const Icon(Icons.store, color: Colors.white, size: 20),
          ),
        ));
        continue; 
      }

      // 2. Bandera (Destino)
      if (id == 'END' || id == 'END_FORZADO') {
        marcadoresList.add(Marker(
          point: LatLng(lat, lng),
          width: 45, height: 45,
          child: Container(
            decoration: BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
            child: const Icon(Icons.flag, color: Colors.white, size: 20),
          ),
        ));
        continue; 
      }

      // 3. Pines de Paradas
      final bool completada = p['estatus'] == 'Recolectada' || p['estatus_paquete'] == 'Entregado'; 
      
      // --- SOLUCIÓN: Usar el orden real de la Base de Datos en el Mapa ---
      final String numeroParada = p['orden_visita']?.toString() ?? '$contadorFallback';
      contadorFallback++;

      Color colorFondo = completada ? AppColors.success : AppColors.primary;
      Widget iconoInterno = completada
          ? const Icon(Icons.check, color: Colors.white, size: 18)
          : Text(
              numeroParada, 
              style: const TextStyle(
                  color: Colors.white,
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
            MarkerLayer(
              markers: _construirMarcadores(), 
            ),
          ],
        ),
      ),
    );
  }
}