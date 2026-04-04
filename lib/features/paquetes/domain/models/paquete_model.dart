// 1. Creamos el modelo para los objetos dentro de la caja
class PaqueteItemModel {
  final String descripcion;
  final int cantidad;

  PaqueteItemModel({required this.descripcion, required this.cantidad});

  factory PaqueteItemModel.fromJson(Map<String, dynamic> json) {
    return PaqueteItemModel(
      descripcion: json['descripcion'] ?? '',
      cantidad: json['cantidad'] is int ? json['cantidad'] : int.tryParse(json['cantidad'].toString()) ?? 1,
    );
  }
}

class PaqueteModel {
  final int id;
  final String guiaRastreo;
  final String remitenteNombre;
  final String? remitenteTelefono;     
  final String? remitenteOrigen;       
  final String destinatarioNombre;
  final String? destinatarioContacto;  
  final String? destinatarioOrigen; 
  final double pesoCantidad;
  final String pesoUnidad;
  final String estatusPaquete;
  final String fechaRegistro;
  final List<PaqueteItemModel>? items;

  PaqueteModel({
    required this.id,
    required this.guiaRastreo,
    required this.remitenteNombre,
    this.remitenteTelefono,            
    this.remitenteOrigen,              
    required this.destinatarioNombre,
    this.destinatarioContacto, 
    this.destinatarioOrigen,        
    required this.pesoCantidad,
    required this.pesoUnidad,
    required this.estatusPaquete,
    required this.fechaRegistro,
    this.items,
  });

  factory PaqueteModel.fromJson(Map<String, dynamic> json) {
    return PaqueteModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      guiaRastreo: json['guia_rastreo'] ?? '',
      remitenteNombre: json['remitente_nombre'] ?? 'Sin remitente',
      remitenteTelefono: json['remitente_telefono'],               
      remitenteOrigen: json['remitente_origen'],                   
      destinatarioNombre: json['destinatario_nombre'] ?? 'Sin dest.',
      destinatarioContacto: json['destinatario_contacto'],   
      destinatarioOrigen: json['destinatario_origen'],      
      pesoCantidad: json['peso_cantidad'] is double
          ? json['peso_cantidad']
          : double.tryParse(json['peso_cantidad'].toString()) ?? 0.0,
      pesoUnidad: json['peso_unidad'] ?? 'Kg',
      estatusPaquete: json['estatus_paquete'] ?? 'Recibido',
      fechaRegistro: json['fecha_registro'] ?? '',
      items: json['items'] != null
          ? (json['items'] as List).map((i) => PaqueteItemModel.fromJson(i)).toList()
          : null,
    );
  }
}