class UbicacionModel {
  final int id;
  final String nombre;

  UbicacionModel({
    required this.id,
    required this.nombre,
  });

  factory UbicacionModel.fromJson(Map<String, dynamic> json) {
    return UbicacionModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nombre: json['nombre'] ?? '',
    );
  }
}