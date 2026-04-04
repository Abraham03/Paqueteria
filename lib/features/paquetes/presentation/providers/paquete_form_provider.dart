import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/paquete_provider.dart';

// 1. El estado se mantiene igual
class PaqueteFormState {
  final bool isUploading;
  final List<Map<String, dynamic>> items;

  PaqueteFormState({this.isUploading = false, this.items = const []});

  PaqueteFormState copyWith({bool? isUploading, List<Map<String, dynamic>>? items}) {
    return PaqueteFormState(
      isUploading: isUploading ?? this.isUploading,
      items: items ?? this.items,
    );
  }
}

class PaqueteFormNotifier extends Notifier<PaqueteFormState> {
  
  @override
  PaqueteFormState build() => PaqueteFormState();

  void agregarItem(String desc, int cant) {
    state = state.copyWith(items: [...state.items, {'descripcion': desc, 'cantidad': cant}]);
  }

  void eliminarItem(int index) {
    final newItems = List<Map<String, dynamic>>.from(state.items)..removeAt(index);
    state = state.copyWith(items: newItems);
  }

  void limpiarItems() => state = state.copyWith(items: []);

  // NUEVO: Carga los items de un paquete existente a la memoria temporal
  void cargarItemsIniciales(List<dynamic>? itemsOriginales) {
    if (itemsOriginales == null || itemsOriginales.isEmpty) return;
    final mapped = itemsOriginales.map((i) => {
      'descripcion': i.descripcion, 
      'cantidad': i.cantidad
    }).toList();
    
    // Usamos Future.microtask para no chocar con el renderizado inicial de Flutter
    Future.microtask(() => state = state.copyWith(items: mapped));
  }

  // MEJORADO: Decide si es Crear o Editar
  Future<bool> enviarFormulario(Map<String, dynamic> datosBase, {bool esEdicion = false}) async {
    if (state.items.isEmpty) throw Exception('Debes agregar al menos un item');
    
    state = state.copyWith(isUploading: true);
    try {
      final repository = ref.read(paqueteRepositoryProvider);
      final dataCompleta = {...datosBase, 'items': state.items};
      
      if (esEdicion) {
        await repository.actualizarPaquete(dataCompleta);
        // Limpiamos el caché del detalle para que al abrirlo se vea fresco
        ref.invalidate(paqueteDetalleProvider(datosBase['id'])); 
      } else {
        await repository.crearPaquete(dataCompleta);
      }
      
      ref.read(paquetesProvider.notifier).refrescarPaquetes();
      limpiarItems();
      return true;
    } finally {
      state = state.copyWith(isUploading: false);
    }
  }
}

// 3. El Provider ahora usa la sintaxis NotifierProvider
final paqueteFormProvider = NotifierProvider<PaqueteFormNotifier, PaqueteFormState>(() {
  return PaqueteFormNotifier();
});