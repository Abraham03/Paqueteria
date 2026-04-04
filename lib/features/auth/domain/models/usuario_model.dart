class UsuarioModel {
  final int id;
  final String nombreCompleto;
  final String usuario;
  final String rol;

  UsuarioModel({
    required this.id,
    required this.nombreCompleto,
    required this.usuario,
    required this.rol,
  });

  // Fábrica para convertir el JSON de PHP a un objeto de Dart
  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nombreCompleto: json['nombre_completo'] ?? '',
      usuario: json['usuario'] ?? '',
      rol: json['rol'] ?? 'Empleado',
    );
  }
}