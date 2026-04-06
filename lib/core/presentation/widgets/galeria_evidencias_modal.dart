import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
// IMPORTAMOS EL PROVIDER (QUE AHORA USA EL REPO CORRECTAMENTE)
import '../../../features/evidencias/presentation/providers/evidencia_provider.dart';

class GaleriaEvidenciasModal extends ConsumerWidget {
  final int paqueteId;

  const GaleriaEvidenciasModal({super.key, required this.paqueteId});

  // --- FUNCIÓN DE UI: VER FOTO EN PANTALLA COMPLETA CON ZOOM ---
  void _verImagenCompleta(BuildContext context, String urlImagen) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero, // Ocupa toda la pantalla
        child: Stack(
          alignment: Alignment.center,
          children: [
            // InteractiveViewer permite hacer "Pellizco" (Pinch to zoom)
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // La vista solo escucha el estado, no sabe de dónde vienen los datos
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
                    
                    // Ajustamos la URL para apuntar a la raíz pública
                    final dominioBase = ApiConstants.baseUrl.replaceAll('/router.php', '');
                    final urlImagen = '$dominioBase/${ev['url_archivo']}';

                    return GestureDetector(
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