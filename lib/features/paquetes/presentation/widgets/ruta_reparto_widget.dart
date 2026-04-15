// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/map_utils.dart'; 
import '../../../../core/presentation/widgets/paquete_detalle_modal.dart';
import '../../../lotes/domain/models/lote_model.dart';
import '../../../lotes/presentation/providers/lote_provider.dart'; 
import '../providers/paquete_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart'; 

import '../../../recolector/presentation/screens/ruta_mapa_widget.dart';

class RutaRepartoWidget extends ConsumerWidget {
  final LoteModel lote;

  const RutaRepartoWidget({super.key, required this.lote});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rutaAsync = ref.watch(rutaRepartoPorLoteProvider(lote.id));
    final bool enTransito = lote.estatusLote == 'En Tránsito';

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
              child: Text(
                'Lista de Entregas (${paradasFiltradas.length})', 
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            
            if (paradasFiltradas.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40.0),
                child: Text('No hay paquetes asignados a esta ruta.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
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
                  
                  final bool completado = parada['estatus_paquete'] == 'Entregado';
                  final int idReal = int.tryParse(parada['id'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                  
                  // --- SOLUCIÓN ANTIMONSTRUOS: Ocultar el 999 ---
                  final ordenDb = parada['orden_visita'];
                  final String numeroParada = (ordenDb != null && ordenDb != 999 && ordenDb != '999') 
                      ? ordenDb.toString() 
                      : '${index + 1}';
                  
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: completado ? AppColors.success : Colors.white,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: completado ? Colors.transparent : AppColors.primary, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: completado 
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : Text(numeroParada, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    title: Text(parada['destinatario_nombre'] ?? 'Sin Nombre', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: completado ? TextDecoration.lineThrough : null,
                        color: completado ? Colors.grey : AppColors.textPrimary
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: const Text('Entrega local', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    
                    trailing: completado 
                      ? const Text('Completado', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12))
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.navigation, color: Colors.blueAccent, size: 28),
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
                            if (enTransito) ...[
                              const SizedBox(width: 8),
                              Flexible( 
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  onPressed: () async {
                                    try {
                                      // 1. Mostrar loading
                                      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

                                      // 2. Traer el paquete
                                      final paquete = await ref.read(paqueteRepositoryProvider).getPaqueteById(idReal);
                                      final usuarioActivo = ref.read(authProvider).user;

                                      // 3. Actualizar
                                      await ref.read(paqueteRepositoryProvider).actualizarPaquete({
                                        'id': paquete.id,
                                        'remitente_nombre': paquete.remitenteNombre,
                                        'destinatario_nombre': paquete.destinatarioNombre,
                                        'peso_cantidad': paquete.pesoCantidad,
                                        'estatus_paquete': 'Entregado',
                                        'id_usuario_entrega': usuarioActivo?.id,
                                      });

                                      // 4. Cerrar loading y actualizar UI
                                      if (context.mounted) Navigator.pop(context);

                                      ref.invalidate(rutaRepartoPorLoteProvider(lote.id));
                                      ref.invalidate(loteDetalleProvider(lote.id));
                                      ref.invalidate(paquetesProvider);

                                      // 5. Abrir el Modal de detalles del paquete recién entregado
                                      if (context.mounted) {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) => PaqueteDetalleModal(
                                            paqueteId: idReal, 
                                            estatusColor: AppColors.success
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        Navigator.pop(context); // Cerrar loader si hay error
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
                                      }
                                    }
                                  },
                                  child: const Text('ENTREGAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ),
                            ]
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