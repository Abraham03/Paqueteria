import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../domain/models/paquete_model.dart';
import '../../../../core/constants/api_constants.dart';
class PaqueteRepository {

  Future<List<PaqueteModel>> getPaquetes() async {
    final url = Uri.parse('${ApiConstants.baseUrl}/paquetes');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 && decodedData['status'] == 'success') {
        // La API devuelve un arreglo de JSONs en la llave 'data'
        final List<dynamic> paquetesJson = decodedData['data'];
        
        // Mapeamos cada JSON a un PaqueteModel y retornamos la lista
        return paquetesJson.map((json) => PaqueteModel.fromJson(json)).toList();
      } else {
        throw Exception(decodedData['message'] ?? 'Error al obtener la lista de paquetes.');
      }
    } on SocketException {
      throw Exception('No hay conexión a Internet. Verifica tus datos o Wi-Fi.');
    } catch (e) {
      throw Exception('Error al cargar paquetes: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  // Obtener el detalle de un solo paquete (incluye los items)
  Future<PaqueteModel> getPaqueteById(int id) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/paquetes?id=$id');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 && decodedData['status'] == 'success') {
        // Mapeamos el 'data' que ahora viene con el arreglo de 'items'
        return PaqueteModel.fromJson(decodedData['data']);
      } else {
        throw Exception(decodedData['message'] ?? 'Error al obtener el detalle del paquete.');
      }
    } on SocketException {
      throw Exception('No hay conexión a Internet.');
    } catch (e) {
      throw Exception('Error al cargar paquete: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Future<Map<String, dynamic>> crearPaquete(Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/paquetes/crear');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));

      final decodedData = jsonDecode(response.body);
      if (response.statusCode == 201 && decodedData['status'] == 'success') {
        return decodedData['data'];
      } else {
        throw Exception(decodedData['message'] ?? 'Error al crear el paquete');
      }
    } catch (e) {
      throw Exception('Error al conectar: $e');
    }
  }


  // EDITAR PAQUETE 
  Future<bool> actualizarPaquete(Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/paquetes/editar');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));

      final decodedData = jsonDecode(response.body);
      if (response.statusCode == 200 && decodedData['status'] == 'success') {
        return true;
      } else {
        throw Exception(decodedData['message'] ?? 'Error al actualizar');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // DESACTIVAR (SOFT DELETE) 
  Future<bool> cancelarPaquete(int id) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/paquetes/cancelar');
    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}), // Tu PHP espera el ID en el body
      ).timeout(const Duration(seconds: 15));

      final decodedData = jsonDecode(response.body);
      if (response.statusCode == 200) return true;
      throw Exception(decodedData['message'] ?? 'Error al cancelar');
    } catch (e) {
      throw Exception('Error al conectar: $e');
    }
  }

}