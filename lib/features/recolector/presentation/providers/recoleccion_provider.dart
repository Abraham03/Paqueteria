import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Ajusta la ruta de la constante
import '../../../../core/constants/api_constants.dart';

class RecoleccionRepository {
  
  Future<void> registrarParada(String enlace, String referencias) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/recolecciones/crear');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'enlace_whatsapp': enlace,
          'direccion_texto': referencias,
        }),
      ).timeout(const Duration(seconds: 15));

      final decodedData = jsonDecode(response.body);
      if (response.statusCode != 201 || decodedData['status'] == 'error') {
        throw Exception(decodedData['message'] ?? 'Error al registrar la recolección');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // --- LEER LAS PARADAS DE LA API ---
  Future<List<dynamic>> getParadasPendientes() async {
    final url = Uri.parse('${ApiConstants.baseUrl}/recolecciones/pendientes');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      final decodedData = jsonDecode(response.body);
      
      if (response.statusCode == 200 && decodedData['status'] == 'success') {
        return decodedData['data'] ?? [];
      } else {
        throw Exception(decodedData['message'] ?? 'Error al obtener paradas');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  // --- ENVIAR PARADAS SELECCIONADAS A MAPBOX (VÍA PHP) ---
  Future<void> optimizarYAsignar({required int idLote, required List<int> idsRecolecciones}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/recolecciones/optimizar');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_lote': idLote,
          'ids_recolecciones': idsRecolecciones,
        }),
      ).timeout(const Duration(seconds: 30)); // Le damos más tiempo por si la API de Mapbox tarda

      final decodedData = jsonDecode(response.body);
      if (response.statusCode != 200 || decodedData['status'] == 'error') {
        throw Exception(decodedData['message'] ?? 'Error en la optimización');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final recoleccionRepositoryProvider = Provider((ref) => RecoleccionRepository());

// Notifier para manejar el estado de "Cargando" al guardar un link de Whatsapp
class CrearRecoleccionNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  Future<bool> crear(String enlace, String referencias) async {
    state = true;
    try {
      await ref.read(recoleccionRepositoryProvider).registrarParada(enlace, referencias);
      state = false;
      return true;
    } catch (e) {
      state = false;
      rethrow;
    }
  }
}

final crearRecoleccionProvider = NotifierProvider<CrearRecoleccionNotifier, bool>(() {
  return CrearRecoleccionNotifier();
});