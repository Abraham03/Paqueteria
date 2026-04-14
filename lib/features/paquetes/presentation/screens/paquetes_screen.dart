// ignore_for_file: use_build_context_synchronously

import 'dart:async'; // Necesario para el Timer del Debouncer
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/widgets/infinite_scroll_list_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/paquete_provider.dart';
import 'formulario_paquete_screen.dart';
import '../../../../core/presentation/widgets/paquete_card_widget.dart';
import '../../../../core/presentation/widgets/buscador_filtro_widget.dart';

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
  // Variables locales solo para mantener el estado visual de la UI en los botones
  String _filterType = 'Destino';
  String _statusFilter = 'Todos';
  
  // Instanciamos el Debouncer con 500 milisegundos de espera
  final _debouncer = Debouncer(milliseconds: 500);

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
          // --- BARRA DE BÚSQUEDA Y CHIPS ---
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16.0),
            child: BuscadorFiltroWidget(
              filterType: _filterType,
              filterOptions: const ['Destino', 'Origen', 'Guía'],
              onFilterChanged: (val) {
                setState(() => _filterType = val);
                // Le avisamos al servidor que cambió el tipo de filtro
                ref.read(paquetesProvider.notifier).aplicarFiltros(tipo: val);
              },
              onSearchChanged: (val) {
                // Usamos el debouncer para no saturar el servidor con cada letra
                _debouncer.run(() {
                  ref.read(paquetesProvider.notifier).aplicarFiltros(query: val);
                });
              },
              statusFilter: _statusFilter,
              statusOptions: const [
                'Todos', 
                'Recibido USA', 
                'En Viaje Principal', 
                'En Bodega México', 
                'En Viaje Reparto', 
                'Entregado'
              ],
              onStatusChanged: (val) {
                setState(() => _statusFilter = val);
                // Le avisamos al servidor que busque por este estatus
                ref.read(paquetesProvider.notifier).aplicarFiltros(estatus: val);
              },
            ),
          ),

          // --- LISTA DE PAQUETES (CON PAGINACIÓN) ---
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
                // La lista 'paquetes' ya viene filtrada desde el servidor
                if (paquetes.isEmpty) {
                  return Center(
                    child: Text('Ningún paquete coincide con la búsqueda.', 
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: () => ref.read(paquetesProvider.notifier).refrescarPaquetes(),
                  child: InfiniteScrollListWidget(
                    padding: const EdgeInsets.all(12),
                    itemCount: paquetes.length, // Usamos la lista directa del servidor
                    isLoadingMore: ref.watch(paquetesProvider.notifier).estaCargandoMas,
                    hasMoreData: ref.watch(paquetesProvider.notifier).hayMasDatos,
                    onLoadMore: () {
                      ref.read(paquetesProvider.notifier).cargarMasPaquetes();
                    },
                    itemBuilder: (context, index) {
                      final paquete = paquetes[index];
                      
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

  
}

// --- CLASE DE APOYO (DEBOUNCER) ---
// Evita ejecutar una función repetidamente en poco tiempo.
// Se usa en la barra de búsqueda para esperar a que el usuario termine de teclear.
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}