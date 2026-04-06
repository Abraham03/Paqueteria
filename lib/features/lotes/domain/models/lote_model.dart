import '../../../paquetes/domain/models/paquete_model.dart';

class LoteModel {
  final int id;
  final String nombreViaje;
  final String tipoViaje; // <--- NUEVO CAMPO
  final String estatusLote;
  final String ubicacionActual;
  final String fechaCreacion;
  final List<PaqueteModel>? paquetes;

  LoteModel({
    required this.id,
    required this.nombreViaje,
    required this.tipoViaje, 
    required this.estatusLote,
    required this.ubicacionActual,
    required this.fechaCreacion,
    this.paquetes,
  });

  factory LoteModel.fromJson(Map<String, dynamic> json) {
    return LoteModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nombreViaje: json['nombre_viaje'] ?? '',
      tipoViaje: json['tipo_viaje'] ?? 'Principal', 
      estatusLote: json['estatus_lote'] ?? 'Preparación',
      ubicacionActual: json['ubicacion_actual'] ?? '',
      fechaCreacion: json['fecha_creacion'] ?? '',
      // Si vienen paquetes en el JSON, los convertimos
      paquetes: json['paquetes'] != null
          ? (json['paquetes'] as List)
              .map((p) => PaqueteModel.fromJson(p))
              .toList()
          : null,
    );
  }
}