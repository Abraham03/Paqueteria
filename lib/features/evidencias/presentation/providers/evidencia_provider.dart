import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/evidencia_repository.dart';

// 1. Inyectamos el repositorio
final evidenciaRepositoryProvider = Provider<EvidenciaRepository>((ref) {
  return EvidenciaRepository();
});

// 2. El Notificador controlará un simple booleano: true (está subiendo) o false (ya terminó)
class EvidenciaNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false; // Por defecto no está cargando nada
  }

  Future<bool> procesarYSubirFotos(int idPaquete, String tipo, List<File> archivos) async {
    state = true; // Encendemos el estado de carga
    try {
      final repo = ref.read(evidenciaRepositoryProvider);
      await repo.subirEvidencia(idPaquete: idPaquete, tipoEvidencia: tipo, archivos: archivos);
      
      state = false; // Apagamos la carga
      return true; // Éxito
    } catch (e) {
      state = false; // Apagamos la carga
      rethrow; // Lanzamos el error para que la pantalla lo atrape y muestre un SnackBar
    }
  }
}

// 3. El Provider principal
final evidenciaProvider = NotifierProvider<EvidenciaNotifier, bool>(() {
  return EvidenciaNotifier();
});