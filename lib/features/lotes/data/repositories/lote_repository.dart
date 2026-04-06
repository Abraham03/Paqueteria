import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../domain/models/lote_model.dart';

class LoteRepository {
  // Obtener todos los lotes
  Future<List<LoteModel>> getLotes() async {
    final url = Uri.parse('${ApiConstants.baseUrl}/lotes');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 20));
      

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        if (decodedData['status'] == 'error') {
          throw Exception(decodedData['message']);
        }

        // 🔥 EL BLINDAJE CONTRA NULOS
        final List<dynamic> lotesJson = decodedData['data'] != null 
            ? List<dynamic>.from(decodedData['data']) 
            : [];

        return lotesJson.map((json) => LoteModel.fromJson(json)).toList();
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
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


 Future<bool> crearLote(Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/lotes/crear');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 20)); // Aumentado a 20s para darle respiro al servidor

      // Blindaje: Verificamos que realmente llegó un JSON y no una página de error HTML
      Map<String, dynamic> decodedData;
      try {
        decodedData = jsonDecode(response.body);
      } catch (_) {
        throw Exception('Respuesta inválida del servidor (Status: ${response.statusCode})');
      }

      if (response.statusCode == 201 && decodedData['status'] == 'success') {
        return true;
      }
      
      throw Exception(decodedData['message'] ?? 'Error al crear lote');
      
    } on TimeoutException catch (_) {
      // Si Hostinger se durmió y pasaron los 20 segundos, avisamos amablemente
      throw Exception('El servidor tardó demasiado en responder. Intenta de nuevo.');
    } catch (e) {
      // Limpiamos el texto 'Exception:' para que no se vea feo en el SnackBar
      throw Exception('Error de conexión: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  // EDITAR LOTE
  // EDITAR LOTE
  Future<bool> actualizarLote(Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/lotes/editar');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 20)); // Aumentado a 20s

      // Blindaje contra errores de servidor que devuelven HTML
      Map<String, dynamic> decodedData;
      try {
        decodedData = jsonDecode(response.body);
      } catch (_) {
        throw Exception('Respuesta inválida del servidor (Status: ${response.statusCode})');
      }

      if (response.statusCode == 200 && decodedData['status'] == 'success') {
        return true;
      }
      
      throw Exception(decodedData['message'] ?? 'Error al actualizar lote');
      
    } on TimeoutException catch (_) {
      throw Exception('El servidor tardó demasiado en responder. Intenta de nuevo.');
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString().replaceAll('Exception: ', '')}');
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