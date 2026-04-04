import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/models/usuario_model.dart';
import '../../../../core/constants/api_constants.dart';

class AuthRepository {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<UsuarioModel> login(String usuario, String password) async {
    // Enviamos la petición al servidor usando la URL base costante
    final url = Uri.parse('${ApiConstants.baseUrl}/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'usuario': usuario,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10)); // Evita que se quede cargando infinito

      final decodedData = jsonDecode(response.body);

      // Manejo estricto de códigos HTTP
      switch (response.statusCode) {
        case 200:
          if (decodedData['status'] == 'success') {
            final userData = decodedData['data']['usuario'];
            final usuarioLogueado = UsuarioModel.fromJson(userData);

            await _storage.write(key: 'user_id', value: usuarioLogueado.id.toString());
            await _storage.write(key: 'user_rol', value: usuarioLogueado.rol);
            return usuarioLogueado;
          }
          throw Exception('Error inesperado al procesar los datos.');
        case 400:
          throw Exception('Faltan datos obligatorios. Verifica tu usuario y contraseña.');
        case 401:
          throw Exception('Usuario o contraseña incorrectos.');
        case 404:
          throw Exception('El servidor no fue encontrado. Verifica tu conexión.');
        case 500:
          throw Exception('Error interno del servidor. Intenta más tarde.');
        default:
          throw Exception(decodedData['message'] ?? 'Ocurrió un error desconocido (Código: ${response.statusCode})');
      }
    } on SocketException {
      throw Exception('No hay conexión a Internet. Verifica tus datos o Wi-Fi.');
    } catch (e) {
      // Captura timeouts u otros errores
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'user_rol');
  }
}