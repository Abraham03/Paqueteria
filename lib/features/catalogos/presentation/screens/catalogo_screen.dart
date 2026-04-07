import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/ubicacion_model.dart';
import '../providers/catalogo_provider.dart'; 

class CatalogoCrudScreen extends ConsumerStatefulWidget {
  const CatalogoCrudScreen({super.key});

  @override
  ConsumerState<CatalogoCrudScreen> createState() => _CatalogoCrudScreenState();
}

class _CatalogoCrudScreenState extends ConsumerState<CatalogoCrudScreen> {
  int? _estadoSeleccionadoId;
  int? _municipioSeleccionadoId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administrar Zonas (Catálogo)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. SECCIÓN ESTADOS (Siempre habilitada)
            _buildSeccionLista(
              context: context,
              ref: ref,
              titulo: 'Estados',
              icono: Icons.map_outlined, // <-- ICONO AGREGADO
              tipoEndpint: 'estados',
              isEnabled: true,
              mensajeDeshabilitado: '',
              proveedor: ref.watch(estadosProvider), 
              seleccionId: _estadoSeleccionadoId,
              onItemTap: (id) => setState(() {
                _estadoSeleccionadoId = id;
                _municipioSeleccionadoId = null; // Resetea hijos
              }),
            ),

            const SizedBox(height: 24),

            // 2. SECCIÓN MUNICIPIOS (Se habilita al elegir Estado)
            _buildSeccionLista(
              context: context,
              ref: ref,
              titulo: 'Municipios',
              icono: Icons.location_city_outlined, // <-- ICONO AGREGADO
              tipoEndpint: 'municipios',
              isEnabled: _estadoSeleccionadoId != null,
              mensajeDeshabilitado: 'Selecciona un Estado para ver sus municipios',
              // Solo intentamos leer el provider si hay un Estado seleccionado
              proveedor: _estadoSeleccionadoId != null ? ref.watch(municipiosProvider(_estadoSeleccionadoId!)) : null,
              idPadre: _estadoSeleccionadoId,
              seleccionId: _municipioSeleccionadoId,
              onItemTap: (id) => setState(() {
                _municipioSeleccionadoId = id;
              }),
            ),

            const SizedBox(height: 24),

            // 3. SECCIÓN LOCALIDADES (Se habilita al elegir Municipio)
            _buildSeccionLista(
              context: context,
              ref: ref,
              titulo: 'Localidades / Colonias',
              icono: Icons.holiday_village_outlined, // <-- ICONO AGREGADO
              tipoEndpint: 'localidades',
              isEnabled: _municipioSeleccionadoId != null,
              mensajeDeshabilitado: 'Selecciona un Municipio para ver sus localidades',
              // Solo intentamos leer el provider si hay un Municipio seleccionado
              proveedor: _municipioSeleccionadoId != null ? ref.watch(localidadesProvider(_municipioSeleccionadoId!)) : null,
              idPadre: _municipioSeleccionadoId,
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET REUTILIZABLE PARA DIBUJAR CADA BLOQUE (DRY) ---
  Widget _buildSeccionLista({
    required BuildContext context,
    required WidgetRef ref,
    required String titulo,
    required IconData icono, // <-- NUEVO PARÁMETRO
    required String tipoEndpint,
    required bool isEnabled, // <-- NUEVO PARÁMETRO
    required String mensajeDeshabilitado, // <-- NUEVO PARÁMETRO
    AsyncValue<List<UbicacionModel>>? proveedor, // Ahora es opcional (nullable)
    int? idPadre,
    int? seleccionId,
    ValueChanged<int>? onItemTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isEnabled ? Colors.grey.shade300 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CABECERA DE SECCIÓN
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isEnabled ? AppColors.surface : Colors.grey.shade50, // Fondo gris si está deshabilitado
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icono, size: 22, color: isEnabled ? AppColors.primary : Colors.grey.shade400),
                    const SizedBox(width: 8),
                    Text(
                      titulo, 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 16, 
                        color: isEnabled ? AppColors.primary : Colors.grey.shade400
                      ),
                    ),
                  ],
                ),
                // Solo mostramos el botón de "Agregar" si la sección está activa
                if (isEnabled)
                  TextButton.icon(
                    onPressed: () => _mostrarModalFormulario(context, ref, tipoEndpint, idPadre: idPadre),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Agregar'),
                  )
              ],
            ),
          ),
          
          // CUERPO: LISTA DE DATOS O MENSAJE DE BLOQUEO
          if (!isEnabled || proveedor == null)
             Padding(
               padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
               child: Center(
                 child: Text(
                   mensajeDeshabilitado, 
                   textAlign: TextAlign.center,
                   style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)
                 )
               ),
             )
          else
            proveedor.when(
              loading: () => const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
              error: (e, s) => Padding(padding: const EdgeInsets.all(20), child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
              data: (lista) {
                if (lista.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('No hay registros', style: TextStyle(color: Colors.grey))));
                
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250), 
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: lista.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (context, index) {
                      final item = lista[index];
                      final isSelected = seleccionId == item.id;

                      return ListTile(
                        dense: true,
                        selected: isSelected,
                        selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
                        title: Text(item.nombre, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        onTap: onItemTap != null ? () => onItemTap(item.id) : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                              onPressed: () => _mostrarModalFormulario(context, ref, tipoEndpint, modeloActual: item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
                              onPressed: () => _mostrarConfirmacionBorrado(context, ref, tipoEndpint, item),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // --- LÓGICA PARA CREAR/EDITAR (SOLID) ---
  void _mostrarModalFormulario(BuildContext context, WidgetRef ref, String tipoEndpoint, {UbicacionModel? modeloActual, int? idPadre}) {
    final txtController = TextEditingController(text: modeloActual?.nombre ?? '');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(modeloActual == null ? 'Nuevo Registro' : 'Editar Registro'),
        content: TextField(
          controller: txtController,
          decoration: const InputDecoration(hintText: 'Ingresa el nombre'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (txtController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              
              try {
                final repo = ref.read(catalogoRepositoryProvider);
                if (modeloActual == null) {
                  await repo.crearUbicacion(tipoEndpoint, txtController.text.trim(), idPadre: idPadre);
                } else {
                  await repo.editarUbicacion(tipoEndpoint, modeloActual.id, txtController.text.trim());
                }
                
                // Refrescamos los providers para que la UI se actualice
                ref.invalidate(estadosProvider);
                if (_estadoSeleccionadoId != null) ref.invalidate(municipiosProvider(_estadoSeleccionadoId!));
                if (_municipioSeleccionadoId != null) ref.invalidate(localidadesProvider(_municipioSeleccionadoId!));
                
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
              }
            },
            child: const Text('Guardar'),
          )
        ],
      ),
    );
  }

  // --- LÓGICA PARA ELIMINAR (SOLID) ---
  void _mostrarConfirmacionBorrado(BuildContext context, WidgetRef ref, String tipoEndpoint, UbicacionModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Borrado'),
        content: Text('¿Seguro que deseas eliminar "${item.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final repo = ref.read(catalogoRepositoryProvider);
                await repo.eliminarUbicacion(tipoEndpoint, item.id);
                
                ref.invalidate(estadosProvider);
                if (_estadoSeleccionadoId != null) ref.invalidate(municipiosProvider(_estadoSeleccionadoId!));
                if (_municipioSeleccionadoId != null) ref.invalidate(localidadesProvider(_municipioSeleccionadoId!));
                
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}