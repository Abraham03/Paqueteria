import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/map_utils.dart'; 
import '../../../lotes/domain/models/lote_model.dart';
import '../../../paquetes/presentation/screens/formulario_paquete_screen.dart'; 
import '../providers/recoleccion_provider.dart';

import 'modal_nueva_recoleccion.dart';
import 'ruta_mapa_widget.dart';

class RutaRecoleccionWidget extends ConsumerWidget {
  final LoteModel lote;

  const RutaRecoleccionWidget({super.key, required this.lote});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rutaAsync = ref.watch(paradasPorLoteProvider(lote.id));
    final bool isFinalizado = lote.estatusLote == 'Finalizado';

    return rutaAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
      error: (e, s) => Center(child: Text('Error al cargar ruta: $e', style: const TextStyle(color: Colors.red))),
      data: (paradas) {
        
        final paradasFiltradas = paradas.where((p) => p['id'] != 'START' && p['id'] != 'END' && p['id'] != 'END_FORZADO').toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Ruta de Recolección (${paradasFiltradas.length} paradas)', 
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  if (!isFinalizado)
                    IconButton(
                      icon: const Icon(Icons.add_location_alt, color: AppColors.primary),
                      tooltip: 'Agregar Parada',
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => ModalNuevaRecoleccion(loteId: lote.id),
                        ).then((_) {
                          ref.invalidate(paradasPorLoteProvider(lote.id));
                        });
                      },
                    ),
                ],
              ),
            ),
            
            if (paradasFiltradas.isEmpty)
               const Padding(
                 padding: EdgeInsets.all(40.0),
                 child: Text('No hay paradas asignadas.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
               )
            else ...[
              RutaMapaWidget(paradas: paradas), 
              const SizedBox(height: 8),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: paradasFiltradas.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final parada = paradasFiltradas[index];
                  final recolectada = parada['estatus'] == 'Recolectada';

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    
                    // =========================================================
                    // --- CÍRCULO LIMPIO SIN ALERTAS AMARILLAS ---
                    // =========================================================
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: recolectada ? AppColors.success : Colors.white,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: recolectada ? Colors.transparent : AppColors.primary, 
                            width: 2 
                          ),
                        ),
                        alignment: Alignment.center,
                        child: recolectada 
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : Text('${index + 1}', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    
                    title: Text(parada['direccion_texto'] ?? 'Ubicación de WhatsApp', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 14,
                        decoration: recolectada ? TextDecoration.lineThrough : null,
                        color: recolectada ? Colors.grey : AppColors.textPrimary
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: const Text('Punto de recolección', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    
                    trailing: recolectada 
                      ? const Text('Completada', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12))
                      : Row(
                          mainAxisSize: MainAxisSize.min, 
                          children: [
                            IconButton(
                              icon: const Icon(Icons.navigation, color: Colors.blueAccent, size: 24),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
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
                            const SizedBox(width: 8),
                            Flexible( 
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                child: const Text('Recolectar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
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