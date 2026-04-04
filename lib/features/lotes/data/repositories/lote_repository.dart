import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../domain/models/lote_model.dart';

class LoteRepository {
  // Obtener todos los lotes
  Future<List<LoteModel>> getLotes() async {
    final url = Uri.parse('${ApiConstants.baseUrl}/lotes');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 && decodedData['status'] == 'success') {
        final List<dynamic> lotesJson = decodedData['data'];
        return lotesJson.map((json) => LoteModel.fromJson(json)).toList();
      } else {
        throw Exception(decodedData['message'] ?? 'Error al obtener lotes');
      }
    } on SocketException {
      throw Exception('Sin conexión a internet');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Obtener un lote específico con sus paquetes
  Future<LoteModel> getLoteById(int id) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/lotes?id=$id');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 && decodedData['status'] == 'success') {
        return LoteModel.fromJson(decodedData['data']);
      } else {
        throw Exception(decodedData['message'] ?? 'Error al obtener detalle');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }


  // CREAR LOTE
  Future<bool> crearLote(Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/lotes/crear');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));

      final decodedData = jsonDecode(response.body);
      if (response.statusCode == 201 && decodedData['status'] == 'success') return true;
      throw Exception(decodedData['message'] ?? 'Error al crear lote');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // EDITAR LOTE
  Future<bool> actualizarLote(Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/lotes/editar');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));

      final decodedData = jsonDecode(response.body);
      if (response.statusCode == 200 && decodedData['status'] == 'success') return true;
      throw Exception(decodedData['message'] ?? 'Error al actualizar lote');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Asignar paquete a lote (Adaptado para enviar un array de IDs a PHP)
  Future<void> asignarPaquetesALote(int idLote, List<int> paquetesIds) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/lotes/asignar'); 
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_lote': idLote,
          'paquetes': paquetesIds, // PHP recibirá exactamente el array que espera
        }),
      ).timeout(const Duration(seconds: 15));

      final decodedData = jsonDecode(response.body);
      if (response.statusCode != 200 || decodedData['status'] != 'success') {
        throw Exception(decodedData['message'] ?? 'Error al asignar paquetes');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

}