// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/lotes/domain/models/lote_model.dart';
import '../../../features/lotes/presentation/providers/lote_provider.dart';
import '../../../features/paquetes/presentation/providers/paquete_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/paquete_utils.dart';
import '../screens/escaner_screen.dart';
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
  String _statusFilter = 'Todos'; // <-- NUEVA VARIABLE PARA CUMPLIR CON EL WIDGET
  final Set<int> _selectedIds = {}; 
  bool _isLoading = false;

  Future<void> _guardarAsignacion() async {
    if (_selectedIds.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(loteRepositoryProvider).asignarPaquetesALote(widget.lote.id, _selectedIds.toList());
      ref.invalidate(loteDetalleProvider(widget.lote.id));
      ref.invalidate(paquetesProvider);

      if (!mounted) return; // <-- CORRECCIÓN LINTER
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡${_selectedIds.length} paquetes asignados!'), backgroundColor: AppColors.success)
      );
      
    } catch (e) {
      if (!mounted) return; // <-- CORRECCIÓN LINTER
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final todosLosPaquetes = ref.watch(paquetesProvider).value ?? [];
    final estatusPermitido = 'En Bodega México';
    
    final paquetesDisponibles = todosLosPaquetes.where((p) => p.estatusPaquete == estatusPermitido).toList();
    
    // <-- CORRECCIÓN: PARÁMETROS NOMBRADOS (SOLID/DRY) -->
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
      buscador: Row(
        children: [
          // <-- EL BUSCADOR ACTUALIZADO -->
          Expanded(
            child: BuscadorFiltroWidget(
              filterType: _filterType,
              filterOptions: const ['Destino', 'Origen', 'Guía'],
              onFilterChanged: (val) => setState(() => _filterType = val),
              onSearchChanged: (val) => setState(() => _searchQuery = val),
              statusFilter: _statusFilter,
              statusOptions: const ['Todos'], // Solo necesitamos 'Todos' aquí
              onStatusChanged: (val) => setState(() => _statusFilter = val),
            ),
          ),
          const SizedBox(width: 8),
          
          // <-- BOTÓN DE ESCÁNER RESCATADO --->
          Container(
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
              onPressed: () async {
                FocusScope.of(context).unfocus();
                final barcode = await Navigator.push<String>(context, MaterialPageRoute(builder: (context) => const EscanerScreen()));
                
                if (!mounted) return; // <-- CORRECCIÓN LINTER DE CONTEXTO

                if (barcode != null && barcode.isNotEmpty) {
                  final p = paquetesDisponibles.where((p) => p.guiaRastreo == barcode).firstOrNull;
                  if (p != null) {
                    setState(() => _selectedIds.add(p.id));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paquete agregado a la selección')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Código no encontrado o no está en Bodega'), 
                      backgroundColor: AppColors.error)
                    );
                  }
                }
              },
            ),
          )
        ],
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