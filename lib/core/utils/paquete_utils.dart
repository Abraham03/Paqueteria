// Archivo: lib/core/utils/paquete_utils.dart
import '../../features/paquetes/domain/models/paquete_model.dart';

class PaqueteUtils {
  static List<PaqueteModel> filtrar(List<PaqueteModel> paquetes, String query, String tipoFiltro) {
    if (query.isEmpty) return paquetes;
    final q = query.toLowerCase();
    
    return paquetes.where((p) {
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