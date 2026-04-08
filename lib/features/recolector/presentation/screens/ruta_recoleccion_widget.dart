import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../lotes/domain/models/lote_model.dart';
import '../providers/recoleccion_provider.dart';

// --- IMPORTAMOS NUESTRO NUEVO WIDGET DE MAPA ---
import 'modal_nueva_recoleccion.dart';
import 'ruta_mapa_widget.dart';

class RutaRecoleccionWidget extends ConsumerWidget {
  final LoteModel lote;

  const RutaRecoleccionWidget({super.key, required this.lote});

  // --- NUEVA LÓGICA: Re-Optimizar ---
  Future<void> _ejecutarOptimizacion(BuildContext context, WidgetRef ref) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await ref.read(recoleccionRepositoryProvider).reoptimizarLote(lote.id);
      
      ref.invalidate(paradasPorLoteProvider(lote.id)); // Refresca el mapa y la lista
      Navigator.pop(context); // Cierra loader
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ruta re-ordenada exitosamente'), backgroundColor: AppColors.success)
      );
    } catch (e) {
      Navigator.pop(context); // Cierra loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error)
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rutaAsync = ref.watch(paradasPorLoteProvider(lote.id));
    final bool isFinalizado = lote.estatusLote == 'Finalizado';

    return rutaAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
      error: (e, s) => Center(child: Text('Error al cargar ruta: $e', style: const TextStyle(color: Colors.red))),
      data: (paradas) {
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- NUEVO ENCABEZADO CON CONTROLES (DRY y UX) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ruta de Recolección (${paradas.length})', style: Theme.of(context).textTheme.titleLarge),
                  
                  if (!isFinalizado)
                    Row(
                      children: [
                        // BOTÓN 1: MÁGIA (OPTIMIZAR)
                        if (paradas.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.auto_fix_high, color: Colors.amber),
                            tooltip: 'Optimizar Ruta',
                            onPressed: () => _ejecutarOptimizacion(context, ref),
                          ),
                        // BOTÓN 2: AGREGAR PARADA MANUAL
                        IconButton(
                          icon: const Icon(Icons.add_location_alt, color: AppColors.primary),
                          tooltip: 'Agregar Parada',
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => ModalNuevaRecoleccion(loteId: lote.id), // Le pasamos el ID del lote
                            ).then((_) {
                              // Refrescamos al cerrar el modal por si agregó algo
                              ref.invalidate(paradasPorLoteProvider(lote.id));
                            });
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
            
            if (paradas.isEmpty)
               const Padding(
                 padding: EdgeInsets.all(40.0),
                 child: Text('No hay paradas asignadas.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
               )
            else ...[
              RutaMapaWidget(paradas: paradas),
              const SizedBox(height: 8),

              ListView.separated(
                // ... (EL RESTO DE TU LISTVIEW QUEDA IGUAL) ...
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
                        // Si tiene el orden 999 (la "sucia"), le ponemos un ícono de alerta en vez del número
                        : (parada['orden_visita'] == 999 
                            ? const Icon(Icons.warning_amber, color: Colors.white, size: 20) 
                            : Text('${parada['orden_visita'] ?? '-'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ),
                    title: Text(parada['direccion_texto'] ?? 'Ubicación de WhatsApp', 
                      style: TextStyle(fontWeight: FontWeight.bold, decoration: recolectada ? TextDecoration.lineThrough : null)),
                    subtitle: Text(parada['orden_visita'] == 999 ? 'Falta optimizar' : 'Punto de recolección', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    // ... (resto de tus botones de "Ir con GPS" o "Recolectar") ...
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }
}