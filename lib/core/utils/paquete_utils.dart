// Archivo: lib/core/utils/paquete_utils.dart
import '../../features/paquetes/domain/models/paquete_model.dart';

class PaqueteUtils {
  static List<PaqueteModel> filtrar({
    required List<PaqueteModel> paquetes, 
    required String query, 
    required String tipoFiltro,
    required String estatusFiltro,
  }) {
    return paquetes.where((p) {
      // 1. Filtro rápido por estatus
      if (estatusFiltro != 'Todos' && p.estatusPaquete != estatusFiltro) {
        return false;
      }

      // Si no hay texto, regresamos el paquete (ya pasó el filtro de estatus)
      if (query.trim().isEmpty) return true;
      
      // 2. BÚSQUEDA PROFESIONAL MULTI-TÉRMINO
      // Dividimos lo que escribió el usuario por espacios. 
      // Ejemplo: "Centro Hidalgo" -> ['centro', 'hidalgo']
      final terms = query.toLowerCase().trim().split(RegExp(r'\s+'));
      
      switch (tipoFiltro) {
        case 'Guía':
          final guia = p.guiaRastreo.toLowerCase();
          // ¿Contiene TODAS las palabras que escribió?
          return terms.every((term) => guia.contains(term));
          
        case 'Origen':
          final origen = p.remitenteOrigen?.toLowerCase() ?? '';
          final remitente = p.remitenteNombre.toLowerCase();
          final busquedaUnida = '$origen $remitente';
          return terms.every((term) => busquedaUnida.contains(term));
          
        case 'Destino':
          final destino = p.destinatarioOrigen?.toLowerCase() ?? '';
          final destinatario = p.destinatarioNombre.toLowerCase();
          // Al unir todo, si escribe "Juan Ixmiquilpan", lo encontrará perfectamente.
          final busquedaUnida = '$destino $destinatario';
          return terms.every((term) => busquedaUnida.contains(term));
          
        default:
          return true;
      }
    }).toList();
  }
}