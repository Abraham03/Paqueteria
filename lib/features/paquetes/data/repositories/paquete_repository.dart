import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../domain/models/paquete_model.dart';
import '../../../../core/constants/api_constants.dart';
class PaqueteRepository {

  Future<List<PaqueteModel>> getPaquetes() async {
    final url = Uri.parse('${ApiConstants.baseUrl}/paquetes');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        if (decodedData['status'] == 'error') {
          throw Exception(decodedData['message']);
        }

        // 🔥 EL BLINDAJE CONTRA NULOS (Si no hay 'data', usamos [])
        final List<dynamic> paquetesJson = decodedData['data'] != null 
            ? List<dynamic>.from(decodedData['data']) 
            : [];

        return paquetesJson.map((json) => PaqueteModel.fromJson(json)).toList();
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
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
      ).timeout(const Duration(seconds: 20)); // Aumentado a 20s para darle tiempo al servidor

      // Blindaje: Verificamos que realmente llegó un JSON válido
      Map<String, dynamic> decodedData;
      try {
        decodedData = jsonDecode(response.body);
      } catch (_) {
        throw Exception('Respuesta inválida del servidor (Status: ${response.statusCode})');
      }

      if (response.statusCode == 201 && decodedData['status'] == 'success') {
        // Blindaje extra: Si 'data' viene nulo, retornamos un mapa vacío en vez de crashear
        return decodedData['data'] ?? {}; 
      }
      
      throw Exception(decodedData['message'] ?? 'Error al crear el paquete');
      
    } on TimeoutException catch (_) {
      // Manejo específico del límite de tiempo
      throw Exception('El servidor tardó demasiado en responder. Intenta de nuevo.');
    } catch (e) {
      // Limpiamos la excepción para el SnackBar
      throw Exception('Error de conexión: ${e.toString().replaceAll('Exception: ', '')}');
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
      ).timeout(const Duration(seconds: 20)); // Aumentado a 20s para el servidor

      // Blindaje: Verificamos que llegó un JSON válido y no una pantalla de error del hosting
      Map<String, dynamic> decodedData;
      try {
        decodedData = jsonDecode(response.body);
      } catch (_) {
        throw Exception('Respuesta inválida del servidor (Status: ${response.statusCode})');
      }

      if (response.statusCode == 200 && decodedData['status'] == 'success') {
        return true;
      }
      
      throw Exception(decodedData['message'] ?? 'Error al actualizar paquete');
      
    } on TimeoutException catch (_) {
      // Manejo específico si Hostinger tarda en despertar
      throw Exception('El servidor tardó demasiado en responder. Intenta de nuevo.');
    } catch (e) {
      // Limpiamos el error para que el SnackBar se vea profesional
      throw Exception('Error de conexión: ${e.toString().replaceAll('Exception: ', '')}');
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


  // =========================================================================
  // --- FUNCIONES PARA EL MAPA DE REPARTO ---
  // =========================================================================

  Future<List<dynamic>> getRutaRepartoPorLote(int idLote) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/paquetes/reparto/por-lote?id_lote=$idLote');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 200 && decodedData['status'] == 'success') {
        // --- ACTUALIZADO: BLINDAJE CONTRA NULL ---
        final data = decodedData['data'];
        return data != null ? List<dynamic>.from(data) : [];
      } else {
        throw Exception(decodedData['message'] ?? 'Error al obtener la ruta de reparto');
      }
    } catch (e) {
      throw Exception('Error al conectar: $e');
    }
  }

  Future<void> fijarUbicacionPaquete(int idPaquete, String enlace) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/paquetes/ubicacion/enlace');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_paquete': idPaquete, 'enlace_ubicacion': enlace}),
      ).timeout(const Duration(seconds: 15));

      final decodedData = jsonDecode(response.body);
      if (response.statusCode != 200 || decodedData['status'] != 'success') {
        throw Exception(decodedData['message'] ?? 'Error al fijar ubicación');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> reoptimizarLoteReparto(int idLote) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/paquetes/reparto/reoptimizar');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_lote': idLote}),
      ).timeout(const Duration(seconds: 20));

      final decodedData = jsonDecode(response.body);
      if (response.statusCode != 200 || decodedData['status'] != 'success') {
        throw Exception(decodedData['message'] ?? 'Error al re-optimizar el viaje');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }


  // --- AGREGAR PARADA LIBRE ---
  Future<void> crearParadaLibre(int idLote, String enlace, String descripcion) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/paquetes/reparto/parada-libre');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_lote': idLote,
          'enlace_ubicacion': enlace,
          'descripcion': descripcion
        }),
      ).timeout(const Duration(seconds: 15));

      final decodedData = jsonDecode(response.body);
      if (response.statusCode != 200 || decodedData['status'] != 'success') {
        throw Exception(decodedData['message'] ?? 'Error al agregar parada libre');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

}