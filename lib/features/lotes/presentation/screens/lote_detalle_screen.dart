// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/widgets/modal_carga_masiva.dart';
import '../../../../core/presentation/widgets/modal_entrega_paquetes.dart';
import '../../../../core/presentation/widgets/paquete_card_widget.dart';
import '../../../../core/presentation/widgets/paquete_detalle_modal.dart';
import '../../../../core/theme/app_colors.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../paquetes/domain/models/paquete_model.dart';
import '../providers/lote_provider.dart';
import '../../domain/models/lote_model.dart';
import '../../../paquetes/presentation/providers/paquete_provider.dart'; 
import '../../../paquetes/presentation/screens/formulario_paquete_screen.dart';
import 'formulario_lote_screen.dart';

// =========================================================================
// PANTALLA PRINCIPAL
// =========================================================================
class LoteDetalleScreen extends ConsumerWidget {
  final int loteId;
  const LoteDetalleScreen({super.key, required this.loteId});

  // FUNCIÓN PARA ENTREGA DIRECTA DESDE LA TARJETA
  Future<void> _entregarPaqueteDirecto(BuildContext context, WidgetRef ref, PaqueteModel paquete, int idLote) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final usuarioActivo = ref.read(authProvider).user;

      await ref.read(paqueteRepositoryProvider).actualizarPaquete({
        'id': paquete.id,
        'remitente_nombre': paquete.remitenteNombre,
        'destinatario_nombre': paquete.destinatarioNombre,
        'peso_cantidad': paquete.pesoCantidad,
        'estatus_paquete': 'Entregado', 
        'id_usuario_entrega': usuarioActivo?.id, 
      });

      ref.invalidate(loteDetalleProvider(idLote));
      ref.invalidate(paquetesProvider); 

      Navigator.pop(context); 

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Paquete Entregado!'), backgroundColor: AppColors.success)
      );
    } catch (e) {
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error)
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalleState = ref.watch(loteDetalleProvider(loteId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Viaje'),
        centerTitle: true,
        actions: [
          detalleState.maybeWhen(
            data: (lote) => IconButton(
              icon: const Icon(Icons.edit_location_alt_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FormularioLoteScreen(loteAEditar: lote)),
                );
              },
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: detalleState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorView(ref, error.toString()),
        data: (lote) {
          final paquetes = lote.paquetes ?? [];
          final esRepartoEnTransito = lote.tipoViaje == 'Reparto' && lote.estatusLote == 'En Tránsito';

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lote.nombreViaje, style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24)),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        lote.tipoViaje == 'Principal' ? Icons.public : Icons.local_shipping, 
                        'Tipo de Ruta:', 
                        lote.tipoViaje == 'Principal' ? 'Internacional' : 'Reparto Local'
                      ),
                      const SizedBox(height: 4),
                      _buildInfoRow(Icons.location_on_outlined, 'Ubicación Actual:', lote.ubicacionActual),
                      
                      _buildTimeline(lote),
                      
                      const Divider(height: 30),
                      
                      if (lote.estatusLote != 'Finalizado')
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => FormularioLoteScreen(loteAEditar: lote)),
                              );
                            },
                            icon: const Icon(Icons.update),
                            label: const Text('ACTUALIZAR RASTREO / ESTATUS'),
                          ),
                        )
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Manifiesto de Carga', style: Theme.of(context).textTheme.titleLarge),
                      Text('${paquetes.length} cajas', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),

              if (paquetes.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text('El viaje está vacío. Asigna paquetes para empezar.', 
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final p = paquetes[index];
                      final bool entregado = p.estatusPaquete == 'Entregado';

                      // 1. REEMPLAZO POR TU PAQUETE CARD WIDGET
                      return PaqueteCardWidget(
                        paquete: p,
                        // El botón naranja se inyecta en el trailing del widget si cumple la condición
                        trailing: (esRepartoEnTransito && !entregado)
                          ? ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.highlight),
                              onPressed: () => _entregarPaqueteDirecto(context, ref, p, lote.id),
                              child: const Text('ENTREGAR', style: TextStyle(color: Colors.white, fontSize: 12)),
                            )
                          : null, // Si es nulo, tu Card mostrará el badge del estatus por defecto
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => PaqueteDetalleModal(paqueteId: p.id, estatusColor: AppColors.success),
                          );
                        },
                      );
                    },
                    childCount: paquetes.length,
                  ),
                ),
                
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      
      floatingActionButton: _buildFloatingActionButton(context, ref, detalleState.value),
    );
  }

  // --- MÉTODOS PRIVADOS (Timeline, Botón Flotante, Etc) ---
  Widget _buildTimeline(LoteModel lote) {
    final isReparto = lote.tipoViaje == 'Reparto';
    final List<Map<String, dynamic>> steps = isReparto 
      ? [
          {'label': 'Prep', 'icon': Icons.inventory_2, 'status': 'Preparación'},
          {'label': 'Ruta', 'icon': Icons.local_shipping, 'status': 'En Tránsito'},
          {'label': 'Fin', 'icon': Icons.task_alt, 'status': 'Finalizado'},
        ]
      : [
          {'label': 'Prep', 'icon': Icons.inventory_2, 'status': 'Preparación'},
          {'label': 'Viaje', 'icon': Icons.local_shipping, 'status': 'En Tránsito'},
          {'label': 'Aduana', 'icon': Icons.policy, 'status': 'En Aduana'},
          {'label': 'Bodega', 'icon': Icons.warehouse, 'status': 'En Bodega México'},
          {'label': 'Fin', 'icon': Icons.task_alt, 'status': 'Finalizado'},
        ];

    int currentStep = steps.indexWhere((s) => s['status'] == lote.estatusLote);
    if (currentStep == -1) currentStep = 0; 

    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index % 2 == 0) {
            int stepIdx = index ~/ 2;
            bool isActive = stepIdx <= currentStep;
            bool isCurrent = stepIdx == currentStep;
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : Colors.grey.shade200,
                    shape: BoxShape.circle,
                    border: isCurrent ? Border.all(color: AppColors.accent, width: 3) : null,
                  ),
                  child: Icon(steps[stepIdx]['icon'] as IconData, size: 20, color: isActive ? Colors.white : Colors.grey.shade400),
                ),
                const SizedBox(height: 6),
                Text(
                  steps[stepIdx]['label'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? AppColors.textPrimary : Colors.grey,
                  ),
                ),
              ],
            );
          } else {
            int lineIdx = index ~/ 2;
            bool isLineActive = lineIdx < currentStep;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 18), 
                height: 3,
                color: isLineActive ? AppColors.primary : Colors.grey.shade200,
              ),
            );
          }
        }),
      ),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context, WidgetRef ref, LoteModel? lote) {
    if (lote == null || lote.estatusLote == 'Finalizado') return null;

    if (lote.tipoViaje == 'Principal') {
      return FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FormularioPaqueteScreen(loteAsociado: lote)),
          ).then((_) {
            ref.invalidate(loteDetalleProvider(lote.id));
            ref.invalidate(paquetesProvider);
          });
        },
        icon: const Icon(Icons.add_box),
        label: const Text('NUEVO PAQUETE'),
      );
    } else {
      if (lote.estatusLote == 'Preparación') {
        return FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => ModalCargaMasiva(lote: lote),
            );
          },
          icon: const Icon(Icons.airport_shuttle),
          label: const Text('CARGAR CAMIONETA'),
        );
      }

      return FloatingActionButton.extended(
        backgroundColor: AppColors.highlight,
        foregroundColor: AppColors.surface,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => ModalEntregaPaquetes(lote: lote),
          );
        },
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('ESCANEAR ENTREGA'),
      );
    }
  }

  Widget _buildInfoRow(IconData icono, String titulo, String valor) {
    return Row(
      children: [
        Icon(icono, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(titulo, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(width: 8),
        Expanded(child: Text(valor, style: const TextStyle(fontWeight: FontWeight.w600))),
      ],
    );
  }

  Widget _buildErrorView(WidgetRef ref, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 60),
          const SizedBox(height: 16),
          Text(error, textAlign: TextAlign.center),
          ElevatedButton(
            onPressed: () => ref.refresh(loteDetalleProvider(loteId)),
            child: const Text('Reintentar'),
          )
        ],
      ),
    );
  }
}



