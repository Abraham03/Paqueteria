import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/ubicacion_model.dart';
import '../../../../core/constants/api_constants.dart';
class CatalogoRepository {
  // Cambia esto por tu URL base real

  Future<List<UbicacionModel>> _fetchCatalogo(String endpoint) async {

    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint'); 
    
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        if (decodedData['status'] == 'error') {
          throw Exception(decodedData['message']);
        }

        final List<dynamic> dataList = decodedData['data'] ?? [];

        return dataList.map((item) => UbicacionModel.fromJson(item)).toList();
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al cargar catálogo: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  // MÉTODOS PÚBLICOS
  
  Future<List<UbicacionModel>> getEstados() {
    return _fetchCatalogo('/catalogos/estados');
  }

  Future<List<UbicacionModel>> getMunicipios(int idEstado) {
    return _fetchCatalogo('/catalogos/municipios?id_estado=$idEstado');
  }

  Future<List<UbicacionModel>> getLocalidades(int idMunicipio) {
    return _fetchCatalogo('/catalogos/localidades?id_municipio=$idMunicipio');
  }
}