import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/evidencia_repository.dart';

// 1. Inyectamos el repositorio
final evidenciaRepositoryProvider = Provider<EvidenciaRepository>((ref) {
  return EvidenciaRepository();
});

// PROVIDER PARA TRAER LA LISTA DE FOTOS ---
final evidenciasListProvider = FutureProvider.family<List<dynamic>, int>((ref, idPaquete) async {
  final repo = ref.read(evidenciaRepositoryProvider);
  return await repo.getEvidencias(idPaquete);
});

// 2. El Notificador controlará un simple booleano: true (está subiendo) o false (ya terminó)
class EvidenciaNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false; // Por defecto no está cargando nada
  }

  Future<bool> procesarYSubirFotos(int idPaquete, String tipo, List<File> archivos) async {
    state = true; 
    try {
      final repo = ref.read(evidenciaRepositoryProvider);
      await repo.subirEvidencia(idPaquete: idPaquete, tipoEvidencia: tipo, archivos: archivos);
      
      // MUY IMPORTANTE: Invalidamos la lista de fotos para que si el usuario 
      // abre la galería justo después de subir, aparezcan las fotos nuevas.
      ref.invalidate(evidenciasListProvider(idPaquete));
      
      state = false; 
      return true; 
    } catch (e) {
      state = false; 
      rethrow; 
    }
  }

  Future<void> eliminarEvidencia(int idEvidencia) async {
    try {
      final repo = ref.read(evidenciaRepositoryProvider);
      await repo.eliminarEvidenciaFisica(idEvidencia);
    } catch (e) {
      rethrow;
    }
  }
}



// 3. El Provider principal
final evidenciaProvider = NotifierProvider<EvidenciaNotifier, bool>(() {
  return EvidenciaNotifier();
});