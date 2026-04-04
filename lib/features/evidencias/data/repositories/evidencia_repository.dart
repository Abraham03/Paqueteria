import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';

class EvidenciaRepository {

  Future<bool> subirEvidencia({
    required int idPaquete,
    required String tipoEvidencia,
    required List<File> archivos, // <-- Ahora es una lista
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/evidencias/subir');
    var request = http.MultipartRequest('POST', url);

    request.fields['id_paquete'] = idPaquete.toString();
    request.fields['tipo_evidencia'] = tipoEvidencia;

    // MAGIA MULTI-ARCHIVO: Recorremos la lista y adjuntamos cada foto
    // bajo el mismo nombre 'archivos[]' que espera tu PHP
    for (var archivo in archivos) {
      request.files.add(
        await http.MultipartFile.fromPath('archivos[]', archivo.path)
      );
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final decodedData = jsonDecode(response.body);

      if (response.statusCode == 201 && decodedData['status'] == 'success') {
        return true; 
      } else {
        throw Exception(decodedData['message'] ?? 'Error al subir evidencias');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }
}