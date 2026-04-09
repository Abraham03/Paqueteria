import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../features/paquetes/domain/models/paquete_model.dart';
import '../../../features/paquetes/presentation/providers/paquete_provider.dart';
import '../../../features/evidencias/presentation/providers/evidencia_provider.dart';
import '../../../features/paquetes/presentation/screens/formulario_paquete_screen.dart';

import '../widgets/galeria_evidencias_modal.dart';
import '../../../features/paquetes/presentation/widgets/modal_fijar_ubicacion.dart';

class PaqueteDetalleModal extends ConsumerWidget {
  final int paqueteId;
  final Color estatusColor;

  const PaqueteDetalleModal({super.key, required this.paqueteId, required this.estatusColor});

  // --- FUNCIÓN PARA LLAMADAS ---
  Future<void> _hacerLlamada(String telefono, BuildContext context) async {
    final numeroLimpio = telefono.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri url = Uri.parse('tel:$numeroLimpio');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir la app de llamadas')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paqueteAsync = ref.watch(paqueteDetalleProvider(paqueteId));

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      child: paqueteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text(e.toString(), style: const TextStyle(color: AppColors.error))),
        data: (paquete) {
          final items = paquete.items ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 5, margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(color: AppColors.textSecondary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(paquete.guiaRastreo, style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24))),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.accent), 
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => FormularioPaqueteScreen(paqueteAEditar: paquete)),
                      );
                    }
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error), 
                    onPressed: () => _mostrarDialogoConfirmacion(context, ref, paquete.id)
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: estatusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: estatusColor),
                ),
                child: Text(paquete.estatusPaquete, style: TextStyle(color: estatusColor, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const Divider(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    _buildSeccionTitulo(context, 'Origen y Remitente', Icons.outbox),
                    _buildTarjetaInfo([
                      _buildFilaDato(context, 'Nombre', paquete.remitenteNombre),
                      if (paquete.remitenteTelefono != null && paquete.remitenteTelefono!.isNotEmpty)
                        _buildFilaDato(context, 'Teléfono', paquete.remitenteTelefono!, esTelefono: true),
                      if (paquete.remitenteOrigen != null && paquete.remitenteOrigen!.isNotEmpty)
                        _buildFilaDato(context, 'Ubicación USA', paquete.remitenteOrigen!),
                    ]),
                    const SizedBox(height: 16),

                    _buildSeccionTitulo(context, 'Destino y Receptor', Icons.move_to_inbox),
                    _buildTarjetaInfo([
                      _buildFilaDato(context, 'Nombre', paquete.destinatarioNombre),
                      if (paquete.destinatarioContacto != null && paquete.destinatarioContacto!.isNotEmpty)
                        _buildFilaDato(context, 'Teléfono', paquete.destinatarioContacto!, esTelefono: true),
                      if (paquete.destinatarioOrigen != null && paquete.destinatarioOrigen!.isNotEmpty)
                        _buildFilaDato(context, 'Dirección (MX)', paquete.destinatarioOrigen!),
                    ]),
                    const SizedBox(height: 16),

                    _buildSeccionTitulo(context, 'Detalles Logísticos', Icons.local_shipping_outlined),
                    _buildTarjetaInfo([
                      _buildFilaDato(context, 'Peso / Volumen', '${paquete.pesoCantidad} ${paquete.pesoUnidad}'),
                      _buildFilaDato(context, 'Fecha Registro', paquete.fechaRegistro),
                      if (paquete.idLotePrincipal != null)
                        _buildFilaDato(context, 'Tráiler Asignado', 'Viaje ID: ${paquete.idLotePrincipal}'),
                      if (paquete.idLoteReparto != null)
                        _buildFilaDato(context, 'Camioneta Asignada', 'Ruta ID: ${paquete.idLoteReparto}'),
                    ]),
                    const SizedBox(height: 16),

                    // =================================================================
                    // --- NUEVA SECCIÓN: FIJAR UBICACIÓN ---
                    // =================================================================
                    if (paquete.latitud == null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey.shade700, 
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12)
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => ModalFijarUbicacion(idPaquete: paquete.id),
                            ).then((_) {
                              ref.invalidate(paqueteDetalleProvider(paqueteId));
                            });
                          },
                          icon: const Icon(Icons.add_location_alt),
                          label: const Text('FIJAR UBICACIÓN MAPA', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1), 
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.5))
                        ),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: AppColors.success),
                                SizedBox(width: 8),
                                Text('Ubicación confirmada para Mapbox', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => ModalFijarUbicacion(idPaquete: paquete.id),
                                ).then((_) {
                                  ref.invalidate(paqueteDetalleProvider(paquete.id));
                                });
                              },
                              icon: const Icon(Icons.edit_location_alt, size: 16, color: AppColors.primary),
                              label: const Text('Cambiar Ubicación', style: TextStyle(color: AppColors.primary)),
                            )
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    // =================================================================
                    
                    _buildSeccionTitulo(context, 'Contenido de la Caja', Icons.inventory_2_outlined),
                    if (items.isEmpty)
                      Text('No hay items registrados', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic))
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, size: 18, color: AppColors.success),
                                const SizedBox(width: 8),
                                Expanded(child: Text(item.descripcion, style: Theme.of(context).textTheme.bodyLarge)),
                                Text('x${item.cantidad}', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )).toList(),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56, 
                      child: Consumer(
                        builder: (context, ref, child) {
                          final isUploading = ref.watch(evidenciaProvider); 
                          return ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                            onPressed: isUploading ? null : () => _mostrarOpcionesDeEvidencia(context, ref, paquete),
                            icon: isUploading 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.camera_alt_outlined),
                            label: Text(isUploading ? '...' : 'Subir'),
                          );
                        }
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 56, 
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accent, 
                          side: const BorderSide(color: AppColors.accent, width: 2)
                        ),
                        onPressed: () {
                           showModalBottomSheet(
                             context: context,
                             isScrollControlled: true,
                             backgroundColor: Colors.transparent,
                             builder: (context) => GaleriaEvidenciasModal(paqueteId: paquete.id),
                           );
                        },
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Ver Fotos'),
                      ),
                    ),
                  ),
                ],
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildSeccionTitulo(BuildContext context, String titulo, IconData icono) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Row(
        children: [
          Icon(icono, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(titulo, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildTarjetaInfo(List<Widget> filas) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: filas),
    );
  }

  Widget _buildFilaDato(BuildContext context, String etiqueta, String valor, {bool esTelefono = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110, 
            child: Text(etiqueta, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))
          ),
          Expanded(
            child: esTelefono
                ? InkWell(
                    onTap: () => _hacerLlamada(valor, context),
                    child: Row(
                      children: [
                        Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue)),
                        const SizedBox(width: 4),
                        const Icon(Icons.phone, size: 16, color: Colors.blue),
                      ],
                    ),
                  )
                : Text(valor, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  void _mostrarOpcionesDeEvidencia(BuildContext context, WidgetRef ref, PaqueteModel paquete) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text('Selecciona el origen', style: Theme.of(context).textTheme.titleLarge),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.accent),
                title: Text('Tomar foto con la Cámara', style: Theme.of(context).textTheme.bodyLarge),
                onTap: () async {
                  Navigator.pop(context); 
                  final picker = ImagePicker();
                  final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 70, maxWidth: 1200);
                  if (photo != null && context.mounted) {
                    await _procesarYSubirFotos(context, ref, paquete, [photo]); 
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.accent),
                title: Text('Elegir de la Galería', style: Theme.of(context).textTheme.bodyLarge),
                onTap: () async {
                  Navigator.pop(context); 
                  final picker = ImagePicker();
                  final photos = await picker.pickMultiImage(imageQuality: 70, maxWidth: 1200);
                  if (photos.isNotEmpty && context.mounted) {
                    await _procesarYSubirFotos(context, ref, paquete, photos);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _procesarYSubirFotos(BuildContext context, WidgetRef ref, PaqueteModel paquete, List<XFile> photos) async {
    if (photos.isEmpty) return;
    try {
      final List<File> archivosFisicos = photos.map((p) => File(p.path)).toList();
      final exito = await ref.read(evidenciaProvider.notifier).procesarYSubirFotos(
            paquete.id,
            'FOTO_LEVANTAMIENTO',
            archivosFisicos,
          );

      if (exito && context.mounted) {
        ref.invalidate(paqueteDetalleProvider(paquete.id));
        ref.invalidate(paquetesProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('¡${archivosFisicos.length} evidencias subidas!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    }
  }

  void _mostrarDialogoConfirmacion(BuildContext context, WidgetRef ref, int idPaquete) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Cancelar Paquete', style: Theme.of(context).textTheme.titleLarge),
        content: Text('¿Estás seguro de que deseas desactivar este paquete? Esta acción lo ocultará de la lista activa.', style: Theme.of(context).textTheme.bodyLarge),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No, regresar', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx); 
              try {
                await ref.read(paqueteRepositoryProvider).cancelarPaquete(idPaquete);
                ref.read(paquetesProvider.notifier).refrescarPaquetes(); 
                if (context.mounted) {
                  Navigator.pop(context); 
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paquete cancelado'), backgroundColor: AppColors.error));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
                }
              }
            },
            child: const Text('Sí, Cancelar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}