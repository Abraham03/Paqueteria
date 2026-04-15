// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/lotes/domain/models/lote_model.dart';
import '../../../features/lotes/presentation/providers/lote_provider.dart';
import '../../../features/paquetes/presentation/providers/paquete_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/paquete_utils.dart';
import 'buscador_filtro_widget.dart';
import 'paquete_card_widget.dart';
import 'shared_modal_layout.dart';

class ModalCargaMasiva extends ConsumerStatefulWidget {
  final LoteModel lote;
  const ModalCargaMasiva({super.key, required this.lote});

  @override
  ConsumerState<ModalCargaMasiva> createState() => _ModalCargaMasivaState();
}

class _ModalCargaMasivaState extends ConsumerState<ModalCargaMasiva> {
  String _searchQuery = '';
  String _filterType = 'Destino'; 
  String _statusFilter = 'Todos'; 
  final Set<int> _selectedIds = {}; 
  bool _isLoading = false;

  Future<void> _guardarAsignacion() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(loteRepositoryProvider).asignarPaquetesALote(widget.lote.id, _selectedIds.toList());
      
      // Invalidamos todos los providers relevantes para que se refresquen
      ref.invalidate(loteDetalleProvider(widget.lote.id));
      ref.invalidate(rutaRepartoPorLoteProvider(widget.lote.id));
      ref.invalidate(paquetesProvider);
      ref.invalidate(paquetesDisponiblesRepartoProvider(widget.lote.id));

      if (!mounted) return; 
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡Actualización guardada (${_selectedIds.length} paquetes)!'), backgroundColor: AppColors.success)
      );
      
    } catch (e) {
      if (!mounted) return; 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // LLAMAMOS AL PROVIDER ESPECIAL (Ignora la paginación de 15)
    final paquetesAsync = ref.watch(paquetesDisponiblesRepartoProvider(widget.lote.id));

    return paquetesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      data: (paquetesDisponibles) {
        
        // Auto-seleccionar los que ya estaban en este lote (Para la precarga inicial)
        if (_selectedIds.isEmpty && !_isLoading) {
           for (var p in paquetesDisponibles) {
             if (p.idLoteReparto == widget.lote.id) {
               _selectedIds.add(p.id);
             }
           }
        }

        final paquetesFiltrados = PaqueteUtils.filtrar(
          paquetes: paquetesDisponibles, 
          query: _searchQuery, 
          tipoFiltro: _filterType,
          estatusFiltro: _statusFilter,
        );

        bool todosSeleccionados = paquetesFiltrados.isNotEmpty && 
                                  paquetesFiltrados.every((p) => _selectedIds.contains(p.id));

        return SharedModalLayout(
          titulo: 'Cargar Camioneta',
          buscador: BuscadorFiltroWidget(
            filterType: _filterType,
            filterOptions: const ['Destino', 'Origen', 'Guía'],
            onFilterChanged: (val) => setState(() => _filterType = val),
            onSearchChanged: (val) => setState(() => _searchQuery = val),
            statusFilter: _statusFilter,
            statusOptions: const ['Todos'], 
            onStatusChanged: (val) => setState(() => _statusFilter = val),
          ),
          cabeceraExtra: Column(
            children: [
              const Divider(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${paquetesFiltrados.length} paquetes disponibles', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
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
            ? const Center(child: Text('No hay paquetes disponibles que coincidan.', style: TextStyle(color: Colors.grey)))
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
                  backgroundColor: AppColors.primary,
                ),
                onPressed: _isLoading ? null : _guardarAsignacion,
                child: _isLoading 
                    ? const SizedBox(
                        height: 24, 
                        width: 24, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                      )
                    : Text('GUARDAR CARGA (${_selectedIds.length} PAQUETES)'),
              ),
            ),
          ),
        );
      }
    );
  }
}