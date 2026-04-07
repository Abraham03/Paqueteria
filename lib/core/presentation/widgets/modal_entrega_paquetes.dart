import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/lotes/domain/models/lote_model.dart';
import '../../../features/lotes/presentation/providers/lote_provider.dart';
import '../../../features/paquetes/domain/models/paquete_model.dart';
import '../../../features/paquetes/presentation/providers/paquete_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/paquete_utils.dart';
import 'buscador_filtro_widget.dart';
import 'paquete_card_widget.dart';
import 'shared_modal_layout.dart';

class ModalEntregaPaquetes extends ConsumerStatefulWidget {
  final LoteModel lote;
  const ModalEntregaPaquetes({super.key, required this.lote});

  @override
  ConsumerState<ModalEntregaPaquetes> createState() => _ModalEntregaPaquetesState();
}

class _ModalEntregaPaquetesState extends ConsumerState<ModalEntregaPaquetes> {
  String _searchQuery = '';
  String _filterType = 'Guía'; 
  String _statusFilter = 'Todos'; 
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

      if (!mounted) return; 
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Paquete Entregado!'), backgroundColor: AppColors.success)
      );
      
    } catch (e) {
      if (!mounted) return; 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loteState = ref.watch(loteDetalleProvider(widget.lote.id)).value ?? widget.lote;
    final paquetesEnCamioneta = loteState.paquetes ?? [];
    
    final paquetesPendientes = paquetesEnCamioneta.where((p) => p.estatusPaquete != 'Entregado').toList();
    
    final paquetesFiltrados = PaqueteUtils.filtrar(
      paquetes: paquetesPendientes, 
      query: _searchQuery, 
      tipoFiltro: _filterType,
      estatusFiltro: _statusFilter
    );

    return SharedModalLayout(
      titulo: 'Entregar Paquete',
      // <-- CORRECCIÓN: SIN EXPANDED -->
      buscador: BuscadorFiltroWidget(
        filterType: _filterType,
        filterOptions: const ['Guía', 'Destino', 'Origen'],
        onFilterChanged: (val) => setState(() => _filterType = val),
        onSearchChanged: (val) => setState(() => _searchQuery = val),
        statusFilter: _statusFilter,
        statusOptions: const ['Todos'], 
        onStatusChanged: (val) => setState(() => _statusFilter = val),
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