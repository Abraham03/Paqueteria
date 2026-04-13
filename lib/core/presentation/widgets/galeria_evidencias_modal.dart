import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../features/evidencias/presentation/providers/evidencia_provider.dart';

class GaleriaEvidenciasModal extends ConsumerWidget {
  final int paqueteId;

  const GaleriaEvidenciasModal({super.key, required this.paqueteId});

  void _verImagenCompleta(BuildContext context, String urlImagen) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero, 
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                urlImagen,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                },
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: Container(
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- NUEVO: FUNCIÓN PARA ELIMINAR LA IMAGEN ---
  Future<void> _confirmarEliminarEvidencia(BuildContext context, WidgetRef ref, int idEvidencia) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Evidencia'),
        content: const Text('¿Deseas eliminar esta imagen de forma permanente?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Eliminar', style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Mostramos un indicador de carga
        // ignore: use_build_context_synchronously
        showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
        
        await ref.read(evidenciaProvider.notifier).eliminarEvidencia(idEvidencia);
        
        if (context.mounted) {
          Navigator.pop(context); // Cierra el indicador de carga
          ref.invalidate(evidenciasListProvider(paqueteId)); // Recarga la galería
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evidencia eliminada'), backgroundColor: AppColors.success));
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Cierra el indicador de carga
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evidenciasAsync = ref.watch(evidenciasListProvider(paqueteId));

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Evidencias del Paquete', style: Theme.of(context).textTheme.titleLarge),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(),
          Expanded(
            child: evidenciasAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text(e.toString(), style: const TextStyle(color: AppColors.error))),
              data: (evidencias) {
                if (evidencias.isEmpty) {
                  return const Center(child: Text('Aún no se han subido fotos.', style: TextStyle(color: Colors.grey)));
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, 
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: evidencias.length,
                  itemBuilder: (context, index) {
                    final ev = evidencias[index];
                    final dominioBase = ApiConstants.baseUrl.replaceAll('/router.php', '');
                    final urlImagen = '$dominioBase/${ev['url_archivo']}';
                    final int idEvidencia = int.tryParse(ev['id'].toString()) ?? 0;

                    return Stack(
                      children: [
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: () => _verImagenCompleta(context, urlImagen),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                color: Colors.grey.shade200,
                                child: Image.network(
                                  urlImagen,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => const Center(
                                    child: Icon(Icons.broken_image, color: Colors.grey, size: 40)
                                  ),
                                  loadingBuilder: (ctx, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        // --- BOTÓN FLOTANTE PARA ELIMINAR ---
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                              onPressed: () => _confirmarEliminarEvidencia(context, ref, idEvidencia),
                            ),
                          ),
                        ),
                        // Etiqueta visual para distinguir firmas de fotos
                        if (ev['tipo_evidencia'] == 'FIRMA_ENTREGA')
                           Positioned(
                             bottom: 4, left: 4,
                             child: Container(
                               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                               decoration: BoxDecoration(color: AppColors.primary.withValues(alpha:0.8), borderRadius: BorderRadius.circular(4)),
                               child: const Text('Firma', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                             ),
                           ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}