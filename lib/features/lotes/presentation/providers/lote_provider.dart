import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/lote_repository.dart';
import '../../domain/models/lote_model.dart';

final loteRepositoryProvider = Provider<LoteRepository>((ref) => LoteRepository());

// Provider para la lista general
class LotesNotifier extends AsyncNotifier<List<LoteModel>> {
  @override
  Future<List<LoteModel>> build() async {
    return ref.read(loteRepositoryProvider).getLotes();
  }

  Future<void> refresh() async {
    // 1. Limpiamos el caché del detalle de TODOS los viajes (camionetas)
    ref.invalidate(loteDetalleProvider);
    
    // 2. Recargamos la lista principal de viajes
    ref.invalidateSelf();
  }
}

final lotesProvider = AsyncNotifierProvider<LotesNotifier, List<LoteModel>>(() => LotesNotifier());

// Provider para el detalle (usamos un Family para pasar el ID)
final loteDetalleProvider = FutureProvider.family<LoteModel, int>((ref, id) async {
  return ref.read(loteRepositoryProvider).getLoteById(id);
});