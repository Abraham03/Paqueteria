import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/map_utils.dart'; 
import '../../../lotes/domain/models/lote_model.dart';
import '../providers/paquete_provider.dart';

import '../../../recolector/presentation/screens/ruta_mapa_widget.dart';

class RutaRepartoWidget extends ConsumerWidget {
  final LoteModel lote;

  const RutaRepartoWidget({super.key, required this.lote});

  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rutaAsync = ref.watch(rutaRepartoPorLoteProvider(lote.id));
    final bool isFinalizado = lote.estatusLote == 'Finalizado';

    return rutaAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
      error: (e, s) => Center(child: Text('Error al cargar ruta: $e', style: const TextStyle(color: Colors.red))),
      data: (paradas) {
        final paradasFiltradas = paradas.where((p) => p['id'] != 'START' && p['id'] != 'END').toList();

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
                      'Lista de Entregas (${paradasFiltradas.length})', 
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  // Botón para agregar parada libre (siempre útil)
                  if (!isFinalizado)
                    IconButton(
                      icon: const Icon(Icons.add_location_alt, color: AppColors.primary),
                      onPressed: () => _mostrarModalParadaLibre(context, ref),
                    ),
                ],
              ),
            ),
            
            if (paradasFiltradas.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40.0),
                child: Text('No hay paquetes asignados.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
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
                  final bool entregado = parada['estatus_paquete'] == 'Entregado' || parada['estatus_paquete'] == 'Recolectada';
                  
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: entregado ? AppColors.success : Colors.white,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: entregado ? Colors.transparent : AppColors.primary, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: entregado 
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : Text('${index + 1}', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    title: Text(parada['destinatario_nombre'] ?? 'Sin Nombre', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: entregado ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: const Text('Entrega local', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    trailing: entregado 
                      ? const Icon(Icons.done_all, color: AppColors.success)
                      : IconButton(
                          icon: const Icon(Icons.navigation, color: Colors.blueAccent, size: 28),
                          onPressed: () => MapUtils.openMap(
                            double.parse(parada['latitud'].toString()), 
                            double.parse(parada['longitud'].toString())
                          ),
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

  // --- MODAL PARA PARADA LIBRE ---
  void _mostrarModalParadaLibre(BuildContext context, WidgetRef ref) {
    final descController = TextEditingController();
    final linkController = TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24, left: 24, right: 24
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Agregar Parada Libre', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Agrega una parada extra (Gasolinera, Devolución, etc.) a la ruta de hoy.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: 'Descripción de la Parada',
                      prefixIcon: const Icon(Icons.label),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: linkController,
                    decoration: InputDecoration(
                      labelText: 'Enlace de Ubicación (Google Maps)',
                      prefixIcon: const Icon(Icons.map),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                      onPressed: isLoading ? null : () async {
                        if (linkController.text.trim().isEmpty || descController.text.trim().isEmpty) return;
                        setState(() => isLoading = true);
                        try {
                          await ref.read(paqueteRepositoryProvider).crearParadaLibre(
                            lote.id, linkController.text.trim(), descController.text.trim()
                          );
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ref.invalidate(rutaRepartoPorLoteProvider(lote.id));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Parada añadida. Recuerda Re-optimizar.'), backgroundColor: AppColors.success)
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
                          }
                        } finally {
                          if (ctx.mounted) setState(() => isLoading = false);
                        }
                      },
                      child: isLoading 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('GUARDAR PARADA'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  
}