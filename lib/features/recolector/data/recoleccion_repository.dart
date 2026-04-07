import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/api_constants.dart';

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
}

final recoleccionRepositoryProvider = Provider((ref) => RecoleccionRepository());