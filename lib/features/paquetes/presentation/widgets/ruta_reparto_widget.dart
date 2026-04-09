import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/map_utils.dart'; 
import '../../../lotes/domain/models/lote_model.dart';
import '../providers/paquete_provider.dart';

// REUTILIZAMOS TU WIDGET DEL MAPA EXISTENTE
import '../../../recolector/presentation/screens/ruta_mapa_widget.dart';

class RutaRepartoWidget extends ConsumerWidget {
  final LoteModel lote;

  const RutaRepartoWidget({super.key, required this.lote});

  Future<void> _ejecutarOptimizacion(BuildContext context, WidgetRef ref) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await ref.read(paqueteRepositoryProvider).reoptimizarLoteReparto(lote.id);
      
      ref.invalidate(rutaRepartoPorLoteProvider(lote.id)); 
      Navigator.pop(context); 
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ruta local re-ordenada exitosamente'), backgroundColor: AppColors.success)
      );
    } catch (e) {
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error)
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rutaAsync = ref.watch(rutaRepartoPorLoteProvider(lote.id));
    final bool isFinalizado = lote.estatusLote == 'Finalizado';

    return rutaAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
      error: (e, s) => Center(child: Text('Error al cargar ruta de reparto: $e', style: const TextStyle(color: Colors.red))),
      data: (paradas) {
        
        final paradasFiltradas = paradas.where((p) => p['id'] != 'START' && p['id'] != 'END' && p['id'] != 'END_FORZADO').toList();

        // --- LÓGICA PARA OCULTAR EL BOTÓN SI HAY MÁS DE 10 DESTINOS ---
        final Set<String> coordenadasUnicas = {};
        for(var p in paradasFiltradas) {
          if(p['latitud'] != null && p['longitud'] != null) {
            coordenadasUnicas.add('${p['latitud']},${p['longitud']}');
          }
        }
        final bool puedeOptimizar = coordenadasUnicas.length <= 10;

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
                      'Ruta de Entregas (${paradasFiltradas.length} paradas)', 
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  if (!isFinalizado && paradas.isNotEmpty)
                    puedeOptimizar 
                      ? IconButton(
                          icon: const Icon(Icons.auto_fix_high, color: Colors.amber),
                          tooltip: 'Optimizar Ruta Local',
                          onPressed: () => _ejecutarOptimizacion(context, ref),
                        )
                      : IconButton(
                          icon: const Icon(Icons.info_outline, color: Colors.grey),
                          tooltip: 'Ruta manual (>10 destinos)',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Optimización automática deshabilitada por exceder los 10 destinos. Navega manualmente usando los botones azules.'))
                            );
                          },
                        ),
                ],
              ),
            ),
            
            if (paradasFiltradas.isEmpty)
               const Padding(
                 padding: EdgeInsets.all(40.0),
                 child: Text('No hay paquetes con ubicación asignados a esta ruta.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
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
                  final bool entregado = parada['estatus_paquete'] == 'Entregado';
                  final bool esDesordenada = parada['orden_visita'] == 999;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: entregado ? AppColors.success : (esDesordenada ? Colors.amber : AppColors.surface),
                      child: entregado 
                        ? const Icon(Icons.check, color: Colors.white)
                        : (esDesordenada 
                            ? const Icon(Icons.warning_amber, color: Colors.black87, size: 20) 
                            : Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ),
                    title: Text(parada['destinatario_nombre'] ?? 'Sin Nombre', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 14,
                        decoration: entregado ? TextDecoration.lineThrough : null,
                        color: entregado ? Colors.grey : AppColors.textPrimary
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(esDesordenada ? (puedeOptimizar ? 'Falta optimizar' : 'Navegación Manual') : 'Entrega programada', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    
                    trailing: entregado 
                      ? const Text('Entregado', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12))
                      : IconButton(
                          icon: const Icon(Icons.navigation, color: Colors.blueAccent, size: 28),
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