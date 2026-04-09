import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/paquete_repository.dart';
import '../../domain/models/paquete_model.dart';

// 1. Inyectamos el Repositorio
final paqueteRepositoryProvider = Provider<PaqueteRepository>((ref) {
  return PaqueteRepository();
});

// 2. Creamos el Notificador Asíncrono (El estándar para peticiones a internet)
class PaquetesNotifier extends AsyncNotifier<List<PaqueteModel>> {
  
  @override
  Future<List<PaqueteModel>> build() async {
    // Esto se ejecuta automáticamente la primera vez que se abre la pantalla
    return _fetchPaquetes();
  }

  Future<List<PaqueteModel>> _fetchPaquetes() async {
    final repository = ref.read(paqueteRepositoryProvider);
    return await repository.getPaquetes();
  }

  // Método para recargar la lista manualmente (Pull to refresh)
  Future<void> refrescarPaquetes() async {
    // 1. Limpiamos el caché de los detalles (items) de TODOS los paquetes
    ref.invalidate(paqueteDetalleProvider);
    
    // 2. Recargamos la lista principal
    ref.invalidateSelf();
  }

}

  // 3. El Provider principal que observará nuestra pantalla
  final paquetesProvider = AsyncNotifierProvider<PaquetesNotifier, List<PaqueteModel>>(() {
    return PaquetesNotifier();
  });

  // 4. Provider para traer el detalle de un paquete específico (AHORA ES GLOBAL)
  final paqueteDetalleProvider = FutureProvider.family<PaqueteModel, int>((ref, id) async {
    final repository = ref.read(paqueteRepositoryProvider);
    return await repository.getPaqueteById(id);
  });

  // Provider para traer las coordenadas de la ruta de reparto para el mapa
final rutaRepartoPorLoteProvider = FutureProvider.family<List<dynamic>, int>((ref, idLote) async {
  final repository = ref.read(paqueteRepositoryProvider);
  return await repository.getRutaRepartoPorLote(idLote);
});