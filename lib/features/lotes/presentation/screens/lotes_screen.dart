import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart'; // Importamos el Theme
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/lote_model.dart';
import '../providers/lote_provider.dart';
import 'formulario_lote_screen.dart';
import 'lote_detalle_screen.dart';

class LotesScreen extends ConsumerWidget {
  const LotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lotesState = ref.watch(lotesProvider);
    final user = ref.watch(authProvider).user;

    // 1. Envolvemos todo el Scaffold en un DefaultTabController
    return DefaultTabController(
      length: 2, // Número de pestañas
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Viajes y Lotes'),
          centerTitle: true,
          // 2. Agregamos el TabBar en la parte inferior del AppBar
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Internacional', icon: Icon(Icons.public)),
              Tab(text: 'Ruta Local', icon: Icon(Icons.local_shipping)),
            ],
          ),
        ),
        body: lotesState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 60),
                const SizedBox(height: 16),
                Text(e.toString(), style: const TextStyle(color: AppColors.error)),
              ],
            ),
          ),
          data: (lotes) {
            // 3. Filtramos los lotes según su tipo
            final lotesPrincipales = lotes.where((l) => l.tipoViaje == 'Principal').toList();
            final lotesReparto = lotes.where((l) => l.tipoViaje == 'Reparto').toList();

            // 4. Usamos TabBarView para mostrar las dos listas
            return TabBarView(
              children: [
                _buildListaLotes(context, ref, lotesPrincipales, 'No hay viajes internacionales activos'),
                _buildListaLotes(context, ref, lotesReparto, 'No hay rutas locales activas'),
              ],
            );
          },
        ),
        
        // El botón flotante mantiene tu validación de roles
        floatingActionButton: (user?.rol == 'Dueño' || user?.rol == 'Administrador')
            ? FloatingActionButton.extended(
                heroTag: 'btn_new_lote', // Evita choques de animaciones
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FormularioLoteScreen()),
                  );
                },
                label: const Text('Nuevo Viaje'),
                icon: const Icon(Icons.add_box),
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.surface,
              )
            : null,
      ),
    );
  }

  // MÉTODO DRY: Construye la lista con Pull-to-Refresh y tu diseño de tarjetas
  Widget _buildListaLotes(BuildContext context, WidgetRef ref, List<LoteModel> lotesFiltrados, String mensajeVacio) {
    if (lotesFiltrados.isEmpty) {
      return RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () => ref.read(lotesProvider.notifier).refresh(),
        // Usamos ListView para que el RefreshIndicator funcione incluso vacío
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            Center(
              child: Text(mensajeVacio, 
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => ref.read(lotesProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: lotesFiltrados.length,
        itemBuilder: (context, index) {
          final lote = lotesFiltrados[index];
          final estatusColor = _getColor(lote.estatusLote);

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                // ignore: deprecated_member_use
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: const Icon(Icons.local_shipping, color: AppColors.primary),
              ),
              title: Text(lote.nombreViaje, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(lote.ubicacionActual, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Estatus: ${lote.estatusLote}', 
                    style: TextStyle(color: estatusColor, fontWeight: FontWeight.bold)),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoteDetalleScreen(loteId: lote.id)),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Color _getColor(String estatus) {
    switch (estatus) {
      case 'Preparación': return AppColors.accent;
      case 'En Tránsito': return AppColors.highlight;
      case 'En Bodega México': return AppColors.primary;
      case 'Finalizado': return AppColors.success;
      default: return AppColors.textSecondary;
    }
  }
}