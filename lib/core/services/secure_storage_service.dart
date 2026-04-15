import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/auth/domain/models/usuario_model.dart'; // Ajusta esta ruta a tu modelo

class SecureStorageService {
  final _storage = const FlutterSecureStorage();
  final String _userKey = 'user_data';

  // Guardamos el objeto completo convirtiéndolo a JSON
  Future<void> guardarUsuario(UsuarioModel user) async {
    // Nota: Asegúrate de que tu UsuarioModel tenga un método toJson() o toMap()
    final String userJson = jsonEncode(user.toJson()); 
    await _storage.write(key: _userKey, value: userJson);
  }

  // Leemos y reconstruimos el objeto
  Future<UsuarioModel?> leerUsuario() async {
    final String? userJson = await _storage.read(key: _userKey);
    if (userJson != null && userJson.isNotEmpty) {
      // Nota: Asegúrate de que tu UsuarioModel tenga un factory fromJson() o fromMap()
      return UsuarioModel.fromJson(jsonDecode(userJson)); 
    }
    return null;
  }

  // Borrar al cerrar sesión
  Future<void> borrarSesion() async {
    await _storage.delete(key: _userKey);
  }
}

// Inyección de dependencias (SOLID)
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});