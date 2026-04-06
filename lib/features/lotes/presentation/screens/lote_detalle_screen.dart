import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/widgets/paquete_card_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/buscador_filtro_widget.dart';
import '../../../../core/presentation/screens/escaner_screen.dart'; 
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../paquetes/domain/models/paquete_model.dart';
import '../providers/lote_provider.dart';
import '../../domain/models/lote_model.dart';
import '../../../paquetes/presentation/providers/paquete_provider.dart'; 
import '../../../paquetes/presentation/screens/paquetes_screen.dart';
// Asegúrate de que esta ruta apunte correctamente a tu formulario de paquetes
import '../../../paquetes/presentation/screens/formulario_paquete_screen.dart';
import 'formulario_lote_screen.dart';

// =========================================================================
// UTILIDADES (DRY)
// =========================================================================
class PaqueteUtils {
  static List<PaqueteModel> filtrar(List<PaqueteModel> paquetes, String query, String tipoFiltro) {
    if (query.isEmpty) return paquetes;
    final q = query.toLowerCase();
    
    return paquetes.where((p) {
      switch (tipoFiltro) {
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
  }
}

// =========================================================================
// WIDGET MAESTRO (DRY)
// =========================================================================
class SharedModalLayout extends StatelessWidget {
  final String titulo;
  final Widget buscador;
  final Widget listado;
  final Widget? cabeceraExtra;
  final Widget? piePagina;

  const SharedModalLayout({
    super.key,
    required this.titulo,
    required this.buscador,
    required this.listado,
    this.cabeceraExtra,
    this.piePagina,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(titulo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: buscador,
          ),
          if (cabeceraExtra != null) cabeceraExtra!,
          if (cabeceraExtra == null) const Divider(height: 30),
          Expanded(child: listado),
          if (piePagina != null) piePagina!,
        ],
      ),
    );
  }
}

// =========================================================================
// PANTALLA PRINCIPAL
// =========================================================================
class LoteDetalleScreen extends ConsumerWidget {
  final int loteId;
  const LoteDetalleScreen({super.key, required this.loteId});

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
                      
                      // WIDGET DE UBICACIÓN
                      _buildInfoRow(Icons.location_on_outlined, 'Ubicación Actual:', lote.ubicacionActual),
                      
                      _buildTimeline(lote.estatusLote),
                      
                      const Divider(height: 30),
                      
                      // BOTÓN DE ACTUALIZAR RASTREO
                      if (lote.estatusLote != 'Finalizado')
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
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
                              ),
                            ),
                          ],
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

                      return PaqueteCardWidget(
                        paquete: p,
                        leading: Icon(
                          entregado ? Icons.check_circle : Icons.inventory_2, 
                          color: entregado ? AppColors.success : AppColors.primary,
                          size: 32,
                        ),
                        trailing: Text(
                          p.estatusPaquete, 
                          style: TextStyle(color: entregado ? AppColors.success : AppColors.highlight, fontWeight: FontWeight.bold)
                        ),
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

  int _getStepIndex(String status) {
    switch (status) {
      case 'Preparación': return 0;
      case 'En Tránsito': return 1;
      case 'En Aduana': return 2;
      case 'En Bodega México': return 3;
      case 'Finalizado': return 4;
      default: return 0;
    }
  }

  Widget _buildTimeline(String currentStatus) {
    final int currentStep = _getStepIndex(currentStatus);
    final steps = [
      {'label': 'Prep', 'icon': Icons.inventory_2},
      {'label': 'Viaje', 'icon': Icons.local_shipping},
      {'label': 'Aduana', 'icon': Icons.policy},
      {'label': 'Bodega', 'icon': Icons.warehouse},
      {'label': 'Fin', 'icon': Icons.task_alt},
    ];

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

  // =========================================================================
  // BOTÓN FLOTANTE INTELIGENTE 
  // =========================================================================
  Widget? _buildFloatingActionButton(BuildContext context, WidgetRef ref, LoteModel? lote) {
    if (lote == null || lote.estatusLote == 'Finalizado') return null;

    if (lote.tipoViaje == 'Principal') {
      // 1. VIAJE INTERNACIONAL: Crear un paquete nuevo Y ASIGNARLO AL LOTE
      return FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              // LE PASAMOS EL LOTE ACTUAL AL FORMULARIO
              builder: (context) => FormularioPaqueteScreen(loteAsociado: lote),
            ),
          ).then((_) {
            // Refrescar al regresar para ver la nueva caja en la lista del viaje
            ref.invalidate(loteDetalleProvider(lote.id));
            ref.invalidate(paquetesProvider);
          });
        },
        icon: const Icon(Icons.add_box),
        label: const Text('NUEVO PAQUETE'),
      );
    } else {
      // 2. VIAJE DE REPARTO LOCAL: Asignar paquetes de bodega o entregarlos
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
        icon: const Icon(Icons.local_shipping),
        label: const Text('ENTREGAR PAQUETE'),
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

// =========================================================================
// MODAL DE ENTREGAS 
// =========================================================================
class ModalEntregaPaquetes extends ConsumerStatefulWidget {
  final LoteModel lote;
  const ModalEntregaPaquetes({super.key, required this.lote});

  @override
  ConsumerState<ModalEntregaPaquetes> createState() => _ModalEntregaPaquetesState();
}

class _ModalEntregaPaquetesState extends ConsumerState<ModalEntregaPaquetes> {
  String _searchQuery = '';
  String _filterType = 'Guía'; 
  bool _isLoading = false;

  Future<void> _procesarEntrega(PaqueteModel paquete) async {
    setState(() => _isLoading = true);
    try {
      if (paquete.estatusPaquete == 'Entregado') throw Exception('Ese paquete ya fue entregado anteriormente.');
      
      final usuarioActivo = ref.read(authProvider).user;

      await ref.read(paqueteRepositoryProvider).actualizarPaquete({
        'id': paquete.id,
        'remitente_nombre': paquete.remitenteNombre,
        'destinatario_nombre': paquete.destinatarioNombre,
        'peso_cantidad': paquete.pesoCantidad,
        'estatus_paquete': 'Entregado', 
        'id_usuario_entrega': usuarioActivo?.id, 
      });

      ref.invalidate(loteDetalleProvider(widget.lote.id));
      ref.invalidate(paquetesProvider); 

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('¡Paquete Entregado! Toca la lista para subir la evidencia.'), backgroundColor: AppColors.success, duration: const Duration(seconds: 4))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loteState = ref.watch(loteDetalleProvider(widget.lote.id)).value ?? widget.lote;
    final paquetesEnCamioneta = loteState.paquetes ?? [];
    
    final paquetesPendientes = paquetesEnCamioneta.where((p) => p.estatusPaquete != 'Entregado').toList();
    final paquetesFiltrados = PaqueteUtils.filtrar(paquetesPendientes, _searchQuery, _filterType);

    return SharedModalLayout(
      titulo: 'Entregar Paquete',
      buscador: BuscadorFiltroWidget(
        filterType: _filterType,
        filterOptions: const ['Guía', 'Destino', 'Origen'],
        onFilterChanged: (val) => setState(() => _filterType = val),
        onSearchChanged: (val) => setState(() => _searchQuery = val),
        onScanPressed: () async {
          FocusScope.of(context).unfocus();
          final barcode = await Navigator.push<String>(context, MaterialPageRoute(builder: (context) => const EscanerScreen()));
          if (barcode != null && barcode.isNotEmpty) {
            final p = paquetesEnCamioneta.where((p) => p.guiaRastreo == barcode).firstOrNull;
            if (p != null) {
              _procesarEntrega(p); 
            } else {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Esa caja no viene en este viaje.'), backgroundColor: AppColors.error));
            }
          }
        },
      ),
      listado: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : paquetesFiltrados.isEmpty
          ? const Center(child: Text('No hay paquetes pendientes que coincidan.', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: paquetesFiltrados.length,
              itemBuilder: (context, index) {
                final paquete = paquetesFiltrados[index];
                return PaqueteCardWidget(
                  paquete: paquete,
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.highlight),
                    onPressed: () => _procesarEntrega(paquete),
                    child: const Text('ENTREGAR', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                );
              },
            ),
    );
  }
}

// =========================================================================
// MODAL DE ASIGNACIÓN MASIVA (AHORA EXCLUSIVO PARA REPARTO LOCAL)
// =========================================================================
class ModalCargaMasiva extends ConsumerStatefulWidget {
  final LoteModel lote;
  const ModalCargaMasiva({super.key, required this.lote});

  @override
  ConsumerState<ModalCargaMasiva> createState() => _ModalCargaMasivaState();
}

class _ModalCargaMasivaState extends ConsumerState<ModalCargaMasiva> {
  String _searchQuery = '';
  String _filterType = 'Destino'; 
  final Set<int> _selectedIds = {}; 
  bool _isLoading = false;

  Future<void> _guardarAsignacion() async {
    if (_selectedIds.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(loteRepositoryProvider).asignarPaquetesALote(widget.lote.id, _selectedIds.toList());
      ref.invalidate(loteDetalleProvider(widget.lote.id));
      ref.invalidate(paquetesProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('¡${_selectedIds.length} paquetes asignados al viaje!'), backgroundColor: AppColors.success)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final todosLosPaquetes = ref.watch(paquetesProvider).value ?? [];
    
    // Aquí filtramos rigurosamente para que solo se carguen paquetes que estén en bodega
    final estatusPermitido = 'En Bodega México';
    
    final paquetesDisponibles = todosLosPaquetes.where((p) => p.estatusPaquete == estatusPermitido).toList();
    final paquetesFiltrados = PaqueteUtils.filtrar(paquetesDisponibles, _searchQuery, _filterType);

    bool todosSeleccionados = paquetesFiltrados.isNotEmpty && 
                              paquetesFiltrados.every((p) => _selectedIds.contains(p.id));

    return SharedModalLayout(
      titulo: 'Cargar Camioneta',
      buscador: BuscadorFiltroWidget(
        filterType: _filterType,
        filterOptions: const ['Destino', 'Origen', 'Guía'],
        onFilterChanged: (val) => setState(() => _filterType = val),
        onSearchChanged: (val) => setState(() => _searchQuery = val),
        onScanPressed: () async {
          FocusScope.of(context).unfocus();
          final barcode = await Navigator.push<String>(context, MaterialPageRoute(builder: (context) => const EscanerScreen()));
          if (barcode != null && barcode.isNotEmpty) {
            final p = paquetesDisponibles.where((p) => p.guiaRastreo == barcode).firstOrNull;
            if (p != null) {
              setState(() => _selectedIds.add(p.id));
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paquete agregado a la selección')));
            } else {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Código no encontrado o el paquete no está "$estatusPermitido"'), 
                backgroundColor: AppColors.error)
              );
            }
          }
        },
      ),
      cabeceraExtra: Column(
        children: [
          const Divider(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${paquetesFiltrados.length} listos ($estatusPermitido)', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                if (paquetesFiltrados.isNotEmpty)
                  Row(
                    children: [
                      const Text('Seleccionar Todos', style: TextStyle(fontWeight: FontWeight.bold)),
                      Checkbox(
                        value: todosSeleccionados,
                        activeColor: AppColors.primary,
                        onChanged: (bool? checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedIds.addAll(paquetesFiltrados.map((p) => p.id));
                            } else {
                              _selectedIds.removeAll(paquetesFiltrados.map((p) => p.id));
                            }
                          });
                        },
                      ),
                    ],
                  )
              ],
            ),
          ),
        ],
      ),
      listado: paquetesFiltrados.isEmpty
        ? Center(child: Text('No hay paquetes en "$estatusPermitido" que coincidan.', style: const TextStyle(color: Colors.grey)))
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: paquetesFiltrados.length,
            itemBuilder: (context, index) {
              final paquete = paquetesFiltrados[index];
              final isSelected = _selectedIds.contains(paquete.id);

              return PaqueteCardWidget(
                paquete: paquete,
                leading: Checkbox(
                  value: isSelected,
                  activeColor: AppColors.primary,
                  onChanged: (bool? checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedIds.add(paquete.id);
                      } else {
                        _selectedIds.remove(paquete.id);
                      }
                    });
                  },
                ),
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedIds.remove(paquete.id);
                    } else {
                      _selectedIds.add(paquete.id);
                    }
                  });
                },
              );
            },
          ),
      piePagina: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedIds.isEmpty ? Colors.grey : AppColors.primary,
            ),
            onPressed: _selectedIds.isEmpty || _isLoading ? null : _guardarAsignacion,
            child: _isLoading 
                ? const SizedBox(
                    height: 24, 
                    width: 24, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                  )
                : Text('ASIGNAR ${_selectedIds.length} PAQUETES'),
          ),
        ),
      ),
    );
  }
}