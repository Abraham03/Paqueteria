import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/ubicacion_model.dart';
import '../../../../core/constants/api_constants.dart';

class CatalogoRepository {

  Future<List<UbicacionModel>> _fetchCatalogo(String endpoint) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint'); 
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        if (decodedData['status'] == 'error') throw Exception(decodedData['message']);
        final List<dynamic> dataList = decodedData['data'] ?? [];
        return dataList.map((item) => UbicacionModel.fromJson(item)).toList();
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al cargar catálogo: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  // MÉTODOS PÚBLICOS DE LECTURA
  Future<List<UbicacionModel>> getEstados() => _fetchCatalogo('/catalogos/estados');
  Future<List<UbicacionModel>> getMunicipios(int idEstado) => _fetchCatalogo('/catalogos/municipios?id_estado=$idEstado');
  Future<List<UbicacionModel>> getLocalidades(int idMunicipio) => _fetchCatalogo('/catalogos/localidades?id_municipio=$idMunicipio');

  // --- MÉTODOS DE ESCRITURA DRY ---
  Future<void> _enviarPeticion(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      
      final decodedData = jsonDecode(response.body);
      if (response.statusCode != 200 && response.statusCode != 201 || decodedData['status'] == 'error') {
        throw Exception(decodedData['message'] ?? 'Error desconocido');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> crearUbicacion(String tipo, String nombre, {int? idPadre}) async {
    final endpoint = '/catalogos/$tipo/crear';
    
    // <-- CORRECCIÓN: Le decimos explícitamente a Dart que es Map<String, dynamic>
    final Map<String, dynamic> body = {'nombre': nombre}; 
    
    if (tipo == 'municipios') body['id_estado'] = idPadre;
    if (tipo == 'localidades') body['id_municipio'] = idPadre;
    
    await _enviarPeticion(endpoint, body);
  }

  Future<void> editarUbicacion(String tipo, int id, String nombre) async {
    await _enviarPeticion('/catalogos/$tipo/actualizar', {'id': id, 'nombre': nombre});
  }

  Future<void> eliminarUbicacion(String tipo, int id) async {
    final tipoSingular = tipo == 'estados' ? 'estado' : (tipo == 'municipios' ? 'municipio' : 'localidad');
    await _enviarPeticion('/catalogos/eliminar', {'tipo': tipoSingular, 'id': id});
  }
}