// Archivo: lib/core/utils/paquete_utils.dart
import '../../features/paquetes/domain/models/paquete_model.dart';

class PaqueteUtils {
  static List<PaqueteModel> filtrar({
    required List<PaqueteModel> paquetes, 
    required String query, 
    required String tipoFiltro,
    required String estatusFiltro, // <-- NUEVO PARÁMETRO
  }) {
    return paquetes.where((p) {
      // 1. Primero filtramos por estatus (Es más rápido descartar por estatus)
      if (estatusFiltro != 'Todos' && p.estatusPaquete != estatusFiltro) {
        return false;
      }

      // 2. Si pasó el filtro de estatus, aplicamos la búsqueda de texto
      if (query.trim().isEmpty) return true;
      final q = query.toLowerCase().trim();
      
      switch (tipoFiltro) {
        case 'Guía':
          return p.guiaRastreo.toLowerCase().contains(q);
        case 'Origen':
          final origen = p.remitenteOrigen?.toLowerCase() ?? '';
          final remitente = p.remitenteNombre.toLowerCase();
          return origen.contains(q) || remitente.contains(q);
        case 'Destino':
          final destino = p.destinatarioOrigen?.toLowerCase() ?? '';
          final destinatario = p.destinatarioNombre.toLowerCase();
          return destino.contains(q) || destinatario.contains(q);
        default:
          return true;
      }
    }).toList();
  }
}