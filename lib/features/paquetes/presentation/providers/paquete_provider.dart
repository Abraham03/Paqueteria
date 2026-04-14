import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/paquete_repository.dart';
import '../../domain/models/paquete_model.dart';

// 1. Inyectamos el Repositorio
final paqueteRepositoryProvider = Provider<PaqueteRepository>((ref) {
  return PaqueteRepository();
});

// 2. Creamos el Notificador Asíncrono (El estándar para peticiones a internet)
class PaquetesNotifier extends AsyncNotifier<List<PaqueteModel>> {

  int _paginaActual = 1;
  final int _limite = 15;
  bool hayMasDatos = true;
  bool _estaCargandoMas = false;
  bool get estaCargandoMas => _estaCargandoMas;

  // Variables para recordar los filtros activos
  String _currentQuery = '';
  String _currentTipoFiltro = 'Destino';
  String _currentEstatusFiltro = 'Todos';
  
  @override
  Future<List<PaqueteModel>> build() async {
    _paginaActual = 1;
    hayMasDatos = true;
    return _fetchPaquetes(page: _paginaActual);
  }

  Future<List<PaqueteModel>> _fetchPaquetes({required int page}) async {
    final repository = ref.read(paqueteRepositoryProvider);
    return await repository.getPaquetes(
      page: page, 
      limit: _limite,
      query: _currentQuery,
      tipoFiltro: _currentTipoFiltro,
      estatusFiltro: _currentEstatusFiltro,
    );
  }

  // --- NUEVA FUNCIÓN PARA APLICAR FILTROS ---
  Future<void> aplicarFiltros({String? query, String? tipo, String? estatus}) async {
    if (query != null) _currentQuery = query;
    if (tipo != null) _currentTipoFiltro = tipo;
    if (estatus != null) _currentEstatusFiltro = estatus;

    // Al cambiar un filtro, reiniciamos la lista desde la página 1
    _paginaActual = 1;
    hayMasDatos = true;
    
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPaquetes(page: _paginaActual));
  }

  Future<void> refrescarPaquetes() async {
    _paginaActual = 1;
    hayMasDatos = true;
    ref.invalidate(paqueteDetalleProvider);
    
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPaquetes(page: _paginaActual));
  }

  Future<void> cargarMasPaquetes() async {
    if (_estaCargandoMas || !hayMasDatos) return;

    _estaCargandoMas = true;
    _paginaActual++;

    try {
      final nuevosPaquetes = await _fetchPaquetes(page: _paginaActual);
      
      if (nuevosPaquetes.length < _limite) {
        hayMasDatos = false; 
      }

      final listaActual = state.value ?? [];
      state = AsyncValue.data([...listaActual, ...nuevosPaquetes]);
      
    } catch (e) {
      print("Error cargando más paquetes: $e");
    } finally {
      _estaCargandoMas = false;
    }
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