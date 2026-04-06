import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/ubicacion_model.dart';
import '../../data/repositories/catalogo_repository.dart';

// 1. Proveedor del repositorio
final catalogoRepositoryProvider = Provider<CatalogoRepository>((ref) {
  return CatalogoRepository();
});

// 2. Proveedor para la lista de Estados (No requiere parámetros)
final estadosProvider = FutureProvider<List<UbicacionModel>>((ref) async {
  final repository = ref.read(catalogoRepositoryProvider);
  return repository.getEstados();
});

// 3. Proveedor para la lista de Municipios (Requiere el ID del Estado)
// Usamos .family para poder pasar el idEstado como parámetro
final municipiosProvider = FutureProvider.family<List<UbicacionModel>, int>((ref, idEstado) async {
  final repository = ref.read(catalogoRepositoryProvider);
  return repository.getMunicipios(idEstado);
});

// 4. Proveedor para la lista de Localidades (Requiere el ID del Municipio)
final localidadesProvider = FutureProvider.family<List<UbicacionModel>, int>((ref, idMunicipio) async {
  final repository = ref.read(catalogoRepositoryProvider);
  return repository.getLocalidades(idMunicipio);
});