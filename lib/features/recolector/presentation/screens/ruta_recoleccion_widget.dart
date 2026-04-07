import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/map_utils.dart';
import '../../../lotes/domain/models/lote_model.dart';
import '../../../paquetes/presentation/screens/formulario_paquete_screen.dart';
import '../providers/recoleccion_provider.dart';

class RutaRecoleccionWidget extends ConsumerWidget {
  final LoteModel lote;

  const RutaRecoleccionWidget({super.key, required this.lote});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rutaAsync = ref.watch(paradasPorLoteProvider(lote.id));

    return rutaAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
      error: (e, s) => Center(child: Text('Error al cargar ruta: $e', style: const TextStyle(color: Colors.red))),
      data: (paradas) {
        if (paradas.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(40.0),
            child: Text('No hay paradas de recolección asignadas a esta ruta.', 
              textAlign: TextAlign.center, 
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text('Ruta de Recolección (${paradas.length} paradas)', 
                style: Theme.of(context).textTheme.titleLarge),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: paradas.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final parada = paradas[index];
                final recolectada = parada['estatus'] == 'Recolectada';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: recolectada ? AppColors.success : AppColors.primary,
                    child: recolectada 
                      ? const Icon(Icons.check, color: Colors.white)
                      : Text('${parada['orden_visita'] ?? '-'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(parada['direccion_texto'] ?? 'Ubicación de WhatsApp', 
                    style: TextStyle(fontWeight: FontWeight.bold, decoration: recolectada ? TextDecoration.lineThrough : null)),
                  subtitle: const Text('Punto de recolección', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  trailing: recolectada 
                    ? const Text('Completada', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold))
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.navigation, color: Colors.blueAccent),
                            tooltip: 'Ir con GPS',
                            onPressed: () async {
                              try {
                                final lat = double.parse(parada['latitud'].toString());
                                final lng = double.parse(parada['longitud'].toString());
                                await MapUtils.openMap(lat, lng);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
                              }
                            },
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FormularioPaqueteScreen(
                                    loteAsociado: lote, 
                                    idRecoleccion: parada['id'] is int ? parada['id'] : int.tryParse(parada['id'].toString()),
                                  )
                                ),
                              ).then((_) {
                                ref.invalidate(paradasPorLoteProvider(lote.id));
                              });
                            },
                            child: const Text('Recolectar', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}