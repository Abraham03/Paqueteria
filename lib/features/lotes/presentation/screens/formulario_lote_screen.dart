import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/custom_text_form_field.dart';
import '../../domain/models/lote_model.dart';
import '../providers/lote_provider.dart';

class FormularioLoteScreen extends ConsumerStatefulWidget {
  final LoteModel? loteAEditar;

  const FormularioLoteScreen({super.key, this.loteAEditar});

  @override
  ConsumerState<FormularioLoteScreen> createState() => _FormularioLoteScreenState();
}

class _FormularioLoteScreenState extends ConsumerState<FormularioLoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _ubicacionController = TextEditingController();
  String _estatusLote = 'Preparación';
  bool _isLoading = false;

  bool get _esEdicion => widget.loteAEditar != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      _nombreController.text = widget.loteAEditar!.nombreViaje;
      _ubicacionController.text = widget.loteAEditar!.ubicacionActual;
      _estatusLote = widget.loteAEditar!.estatusLote;
    } else {
      _ubicacionController.text = 'Bodega Principal'; // Valor por defecto
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _ubicacionController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(loteRepositoryProvider);
      
      if (_esEdicion) {
        await repo.actualizarLote({
          'id': widget.loteAEditar!.id,
          'nombre_viaje': _nombreController.text,
          'estatus_lote': _estatusLote,
          'ubicacion_actual': _ubicacionController.text,
        });
        ref.invalidate(loteDetalleProvider(widget.loteAEditar!.id));
      } else {
        await repo.crearLote({
          'nombre_viaje': _nombreController.text,
          'estatus_lote': _estatusLote,
          'ubicacion_actual': _ubicacionController.text,
        });
      }

      ref.read(lotesProvider.notifier).refresh(); // Actualizamos la lista principal
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_esEdicion ? 'Viaje actualizado' : 'Viaje creado'), backgroundColor: AppColors.success)
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
    return Scaffold(
      appBar: AppBar(title: Text(_esEdicion ? 'Editar Viaje' : 'Nuevo Viaje')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextFormField(
                label: 'Nombre del Viaje (Ej. Ruta Norte 01)',
                icon: Icons.route,
                controller: _nombreController,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
                label: 'Ubicación Actual',
                icon: Icons.location_on,
                controller: _ubicacionController,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              
              const Text('Estatus del Viaje', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _estatusLote,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: ['Preparación', 'En Tránsito', 'En Aduana', 'En Bodega México', 'Finalizado']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => _estatusLote = val!),
              ),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _guardar,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : Text(_esEdicion ? 'GUARDAR CAMBIOS' : 'CREAR VIAJE'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}