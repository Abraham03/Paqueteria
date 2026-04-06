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
  final int? idLotePrincipal;
  final int? idLoteReparto; // <--- NUEVO: Faltaba agregar este campo
  final String guiaRastreo;
  final String remitenteNombre;
  final String? remitenteTelefono;     
  final String? remitenteOrigen;       
  final String destinatarioNombre;
  final String? destinatarioContacto;  
  
  // Este campo lo seguimos usando porque PHP lo concatena bonito para la vista
  final String? destinatarioOrigen; 
  
  // --- NUEVOS CAMPOS DEL CATÁLOGO ---
  final int? idEstadoDestino;
  final int? idMunicipioDestino;
  final int? idLocalidadDestino;

  final double pesoCantidad;
  final String pesoUnidad;
  final String estatusPaquete;
  final String fechaRegistro;
  final List<PaqueteItemModel>? items;

  PaqueteModel({
    required this.id,
    this.idLotePrincipal,
    this.idLoteReparto, // <--- NUEVO
    required this.guiaRastreo,
    required this.remitenteNombre,
    this.remitenteTelefono,            
    this.remitenteOrigen,              
    required this.destinatarioNombre,
    this.destinatarioContacto, 
    this.destinatarioOrigen,        
    this.idEstadoDestino,      
    this.idMunicipioDestino,   
    this.idLocalidadDestino,   
    required this.pesoCantidad,
    required this.pesoUnidad,
    required this.estatusPaquete,
    required this.fechaRegistro,
    this.items,
  });

  factory PaqueteModel.fromJson(Map<String, dynamic> json) {
    return PaqueteModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      idLotePrincipal: json['id_lote_principal'] != null ? int.tryParse(json['id_lote_principal'].toString()) : null,
      
      // <--- NUEVO: Lo extraemos del JSON
      idLoteReparto: json['id_lote_reparto'] != null ? int.tryParse(json['id_lote_reparto'].toString()) : null, 
      
      guiaRastreo: json['guia_rastreo'] ?? '',
      remitenteNombre: json['remitente_nombre'] ?? 'Sin remitente',
      remitenteTelefono: json['remitente_telefono']?.toString(),               
      remitenteOrigen: json['remitente_origen']?.toString(),                   
      destinatarioNombre: json['destinatario_nombre'] ?? 'Sin dest.',
      destinatarioContacto: json['destinatario_contacto']?.toString(),   
      destinatarioOrigen: json['destinatario_origen']?.toString(),      
      
      // --- MAPEANDO LOS NUEVOS IDs GEOGRÁFICOS ---
      idEstadoDestino: json['id_estado_destino'] != null ? int.tryParse(json['id_estado_destino'].toString()) : null,
      idMunicipioDestino: json['id_municipio_destino'] != null ? int.tryParse(json['id_municipio_destino'].toString()) : null,
      idLocalidadDestino: json['id_localidad_destino'] != null ? int.tryParse(json['id_localidad_destino'].toString()) : null,

      pesoCantidad: json['peso_cantidad'] is double
          ? json['peso_cantidad']
          : double.tryParse(json['peso_cantidad'].toString()) ?? 0.0,
      pesoUnidad: json['peso_unidad'] ?? 'Kg',
      // Actualizamos el estatus por defecto para que empate con el nuevo flujo
      estatusPaquete: json['estatus_paquete'] ?? 'Recibido USA', 
      fechaRegistro: json['fecha_registro'] ?? '',
      items: json['items'] != null
          ? (json['items'] as List).map((i) => PaqueteItemModel.fromJson(i)).toList()
          : null,
    );
  }
}