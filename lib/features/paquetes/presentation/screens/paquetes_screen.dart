import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/paquete_model.dart';
import '../providers/paquete_provider.dart';
import '../../../evidencias/presentation/providers/evidencia_provider.dart';
import 'formulario_paquete_screen.dart';
import '../../../../core/presentation/screens/escaner_screen.dart';
import '../../../../core/presentation/widgets/paquete_card_widget.dart';
// IMPORTAMOS EL WIDGET REUTILIZABLE
import '../../../../core/presentation/widgets/buscador_filtro_widget.dart';

// --- FUNCIONES GLOBALES DE APOYO ---
Color obtenerColorEstatusGlobal(String estatus) {
  if (estatus == 'Recibido') return AppColors.accent;
  if (estatus == 'En Lote') return AppColors.highlight;
  if (estatus == 'Entregado') return AppColors.success;
  return AppColors.textSecondary;
}

// --- PANTALLA PRINCIPAL ---
// Cambiado a ConsumerStatefulWidget para poder manejar el estado del buscador
class PaquetesScreen extends ConsumerStatefulWidget {
  const PaquetesScreen({super.key});

  @override
  ConsumerState<PaquetesScreen> createState() => _PaquetesScreenState();
}

class _PaquetesScreenState extends ConsumerState<PaquetesScreen> {
  // Variables para controlar la búsqueda
  String _searchQuery = '';
  String _filterType = 'Destino';

  @override
  Widget build(BuildContext context) {
    final paquetesState = ref.watch(paquetesProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paquetes Activos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(paquetesProvider.notifier).refrescarPaquetes(),
          )
        ],
      ),
      body: Column(
        children: [
          // --- BARRA DE BÚSQUEDA PROFESIONAL FIJA ARRIBA ---
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16.0),
            child: BuscadorFiltroWidget(
              filterType: _filterType,
              filterOptions: const ['Destino', 'Origen', 'Guía'],
              onFilterChanged: (val) => setState(() => _filterType = val),
              onSearchChanged: (val) => setState(() => _searchQuery = val),
              onScanPressed: () async {
                FocusScope.of(context).unfocus();
                final barcodeScanRes = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (context) => const EscanerScreen()),
                );
                if (barcodeScanRes != null && barcodeScanRes.isNotEmpty) {
                  final listaPaquetes = paquetesState.value ?? [];
                  if (mounted) _procesarCodigo(context, ref, barcodeScanRes, listaPaquetes);
                }
              },
            ),
          ),

          // --- LISTA DE PAQUETES ---
          Expanded(
            child: paquetesState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 60),
                      const SizedBox(height: 16),
                      Text(error.toString(), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.read(paquetesProvider.notifier).refrescarPaquetes(),
                        child: const Text('Reintentar'),
                      )
                    ],
                  ),
                ),
              ),
              data: (paquetes) {
                if (paquetes.isEmpty) {
                  return Center(
                    child: Text('No hay paquetes activos en el sistema', 
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
                  );
                }

                // APLICAMOS LA LÓGICA DE FILTRADO AQUÍ
                final paquetesFiltrados = paquetes.where((p) {
                  if (_searchQuery.isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  
                  switch (_filterType) {
                    case 'Guía':
                      return p.guiaRastreo.toLowerCase().contains(q);
                    case 'Origen':
                      final origen = p.remitenteOrigen?.toLowerCase() ?? '';
                      final remitente = p.remitenteNombre.toLowerCase();
                      return origen.contains(q) || remitente.contains(q);
                    case 'Destino':
                      final destino = p.destinatarioOrigen?.toLowerCase() ?? '';
                      final destinatario = p.destinatarioNombre.toLowerCase();
                      return destino.contains(q) || destinatario.contains(q);
                    default:
                      return true;
                  }
                }).toList();

                if (paquetesFiltrados.isEmpty) {
                  return const Center(child: Text('Ningún paquete coincide con la búsqueda.', style: TextStyle(color: Colors.grey)));
                }

                return RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: () => ref.read(paquetesProvider.notifier).refrescarPaquetes(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: paquetesFiltrados.length,
                    itemBuilder: (context, index) {
                      final paquete = paquetesFiltrados[index];
                      
                      return PaqueteCardWidget(
                        paquete: paquete,
                        onTap: () {
                          Color estatusColor = obtenerColorEstatusGlobal(paquete.estatusPaquete);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => PaqueteDetalleModal(paqueteId: paquete.id, estatusColor: estatusColor),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      
      // BOTONES FLOTANTES 
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2. Nuevo Paquete (Solo Dueño o Administrador)
          if (user?.rol == 'Dueño' || user?.rol == 'Administrador') ...[
            FloatingActionButton.extended(
              heroTag: 'btn_new', 
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FormularioPaqueteScreen()),
                );
              },
              label: const Text('Nuevo Paquete'),
              icon: const Icon(Icons.add_box),
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.surface,
            ),
          ]
        ],
      ),
    );
  }


  // --- LÓGICA PARA BUSCAR EL PAQUETE (INTACTA) ---
  void _procesarCodigo(BuildContext context, WidgetRef ref, String codigo, List<PaqueteModel> paquetesActivos) {
    if (codigo.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un código de guía'), backgroundColor: AppColors.highlight),
      );
      return;
    }

    final resultados = paquetesActivos.where(
      (p) => p.guiaRastreo.toUpperCase() == codigo.toUpperCase()
    );

    if (resultados.isNotEmpty) {
      final paqueteEncontrado = resultados.first;
      Color estatusColor = obtenerColorEstatusGlobal(paqueteEncontrado.estatusPaquete);
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => PaqueteDetalleModal(paqueteId: paqueteEncontrado.id, estatusColor: estatusColor),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se encontró el paquete: $codigo'), backgroundColor: AppColors.error),
      );
    }
  }
}

// --- MODAL DE DETALLES (INTACTO) ---
class PaqueteDetalleModal extends ConsumerWidget {
  final int paqueteId;
  final Color estatusColor;

  const PaqueteDetalleModal({super.key, required this.paqueteId, required this.estatusColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paqueteAsync = ref.watch(paqueteDetalleProvider(paqueteId));

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
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
                    _buildDetalleFila(context, Icons.account_circle_outlined, 'Remitente', paquete.remitenteNombre),
                    const SizedBox(height: 16),
                    _buildDetalleFila(context, Icons.person_pin_circle_outlined, 'Destinatario', paquete.destinatarioNombre),
                    const SizedBox(height: 16),
                    _buildDetalleFila(context, Icons.scale_outlined, 'Peso Total', '${paquete.pesoCantidad} ${paquete.pesoUnidad}'),
                    const SizedBox(height: 16),
                    _buildDetalleFila(context, Icons.calendar_today_outlined, 'Fecha de Registro', paquete.fechaRegistro),
                    const Divider(height: 30),
                    
                    Text('Contenido de la caja:', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
                    const SizedBox(height: 12),
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
              SizedBox(
                width: double.infinity,
                height: 56, 
                child: Consumer(
                  builder: (context, ref, child) {
                    final isUploading = ref.watch(evidenciaProvider); 
                    return ElevatedButton.icon(
                      onPressed: isUploading ? null : () => _mostrarOpcionesDeEvidencia(context, ref, paquete),
                      icon: isUploading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.camera_alt_outlined),
                      label: Text(isUploading ? 'Subiendo...' : 'Subir Evidencia'),
                    );
                  }
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetalleFila(BuildContext context, IconData icono, String titulo, String valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, color: AppColors.textSecondary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 2),
              Text(valor, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  void _mostrarOpcionesDeEvidencia(BuildContext context, WidgetRef ref, PaqueteModel paquete) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                  if (photo != null) {
                    if (context.mounted) await _procesarYSubirFotos(context, ref, paquete, [photo]); 
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
                  if (photos.isNotEmpty) {
                    if (context.mounted) await _procesarYSubirFotos(context, ref, paquete, photos);
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
          SnackBar(
            content: Text('¡${archivosFisicos.length} evidencias subidas!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
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