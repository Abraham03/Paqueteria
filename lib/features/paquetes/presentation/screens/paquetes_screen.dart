// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/paquete_model.dart';
import '../providers/paquete_provider.dart';
import 'formulario_paquete_screen.dart';
import '../../../../core/presentation/screens/escaner_screen.dart';
import '../../../../core/presentation/widgets/paquete_card_widget.dart';
import '../../../../core/presentation/widgets/buscador_filtro_widget.dart';
import '../../../../core/utils/paquete_utils.dart'; // <-- IMPORTAMOS EL UTILITARIO DRY

// IMPORTAMOS EL MODAL
import '../../../../core/presentation/widgets/paquete_detalle_modal.dart';

Color obtenerColorEstatusGlobal(String estatus) {
  if (estatus == 'Recibido USA') return AppColors.accent;
  if (estatus == 'En Bodega México') return AppColors.primary;
  if (estatus == 'Entregado') return AppColors.success;
  return AppColors.highlight; 
}

class PaquetesScreen extends ConsumerStatefulWidget {
  const PaquetesScreen({super.key});

  @override
  ConsumerState<PaquetesScreen> createState() => _PaquetesScreenState();
}

class _PaquetesScreenState extends ConsumerState<PaquetesScreen> {
  String _searchQuery = '';
  String _filterType = 'Destino';
  String _statusFilter = 'Todos'; // <-- NUEVA VARIABLE PARA LOS CHIPS

  @override
  Widget build(BuildContext context) {
    final paquetesState = ref.watch(paquetesProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paquetes Activos'),
        actions: [
          // 1. MOVIMOS EL ESCÁNER AQUÍ ARRIBA (Así no lo perdemos)
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () async {
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(paquetesProvider.notifier).refrescarPaquetes(),
          )
        ],
      ),
      body: Column(
        children: [
          // --- BARRA DE BÚSQUEDA Y CHIPS ---
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16.0),
            child: BuscadorFiltroWidget(
              filterType: _filterType,
              filterOptions: const ['Destino', 'Origen', 'Guía'],
              onFilterChanged: (val) => setState(() => _filterType = val),
              onSearchChanged: (val) => setState(() => _searchQuery = val),
              // PASAMOS LOS NUEVOS PARÁMETROS DEL WIDGET (Sin el escáner)
              statusFilter: _statusFilter,
              statusOptions: const [
                'Todos', 
                'Recibido USA', 
                'En Viaje Principal', 
                'En Bodega México', 
                'En Viaje Reparto', 
                'Entregado'
              ],
              onStatusChanged: (val) => setState(() => _statusFilter = val),
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

                // 2. USAMOS NUESTRA FUNCIÓN DRY (Ya no hay código espagueti aquí)
                final paquetesFiltrados = PaqueteUtils.filtrar(
                  paquetes: paquetes,
                  query: _searchQuery,
                  tipoFiltro: _filterType,
                  estatusFiltro: _statusFilter,
                );

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
      
      floatingActionButton: (user?.rol == 'Dueño' || user?.rol == 'Administrador')
        ? FloatingActionButton.extended(
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
          )
        : null,
    );
  }

  void _procesarCodigo(BuildContext context, WidgetRef ref, String codigo, List<PaqueteModel> paquetesActivos) {
    if (codigo.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un código de guía'), backgroundColor: AppColors.highlight),
      );
      return;
    }

    final resultados = paquetesActivos.where((p) => p.guiaRastreo.toUpperCase() == codigo.toUpperCase());

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