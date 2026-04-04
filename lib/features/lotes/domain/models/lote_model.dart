import '../../../paquetes/domain/models/paquete_model.dart';

class LoteModel {
  final int id;
  final String nombreViaje;
  final String estatusLote;
  final String ubicacionActual;
  final String fechaCreacion;
  final List<PaqueteModel>? paquetes; // Opcional, solo viene en el detalle

  LoteModel({
    required this.id,
    required this.nombreViaje,
    required this.estatusLote,
    required this.ubicacionActual,
    required this.fechaCreacion,
    this.paquetes,
  });

  factory LoteModel.fromJson(Map<String, dynamic> json) {
    return LoteModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nombreViaje: json['nombre_viaje'] ?? '',
      estatusLote: json['estatus_lote'] ?? 'Preparación',
      ubicacionActual: json['ubicacion_actual'] ?? '',
      fechaCreacion: json['fecha_creacion'] ?? '',
      // Si vienen paquetes en el JSON, los convertimos usando el modelo que ya teníamos
      paquetes: json['paquetes'] != null
          ? (json['paquetes'] as List)
              .map((p) => PaqueteModel.fromJson(p))
              .toList()
          : null,
    );
  }
}