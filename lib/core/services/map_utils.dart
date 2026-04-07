import 'package:url_launcher/url_launcher.dart';

class MapUtils {
  // Constructor privado para evitar instanciar esta clase (DRY)
  MapUtils._();

  /// Abre Google Maps, Waze o Apple Maps con las coordenadas dadas
  static Future<void> openMap(double lat, double lng) async {
    // 1. Intentamos usar el esquema de navegación directa (abre Google Maps en modo conducir)
    final Uri directNavigationUri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    
    // 2. URL de respaldo universal (Abre el mapa en el navegador o la app por defecto)
    final Uri universalMapUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    try {
      if (await canLaunchUrl(directNavigationUri)) {
        await launchUrl(directNavigationUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(universalMapUri)) {
        await launchUrl(universalMapUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'No se encontró una aplicación de mapas compatible.';
      }
    } catch (e) {
      throw 'Error al abrir el mapa: $e';
    }
  }
}