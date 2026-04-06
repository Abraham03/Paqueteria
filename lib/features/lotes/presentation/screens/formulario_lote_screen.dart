import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/widgets/custom_text_form_field.dart';
import '../../../../core/theme/app_colors.dart';
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
  
  String _estatusSeleccionado = 'Preparación';
  String _tipoViajeSeleccionado = 'Principal'; // NUEVO: Valor por defecto

  final List<String> _opcionesEstatus = [
    'Preparación',
    'En Tránsito',
    'En Aduana',
    'En Bodega México',
    'Finalizado'
  ];

  final List<String> _opcionesTipoViaje = [
    'Principal',
    'Reparto'
  ];

  bool get _esEdicion => widget.loteAEditar != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      _nombreController.text = widget.loteAEditar!.nombreViaje;
      _ubicacionController.text = widget.loteAEditar!.ubicacionActual;
      _estatusSeleccionado = widget.loteAEditar!.estatusLote;
      _tipoViajeSeleccionado = widget.loteAEditar!.tipoViaje; // Cargamos el tipo de viaje actual
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _ubicacionController.dispose();
    super.dispose();
  }

  Future<void> _guardarLote() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final repository = ref.read(loteRepositoryProvider);

      if (_esEdicion) {
        // Envolvemos los datos en { } para enviar un Map<String, dynamic>
        await repository.actualizarLote({
          'id': widget.loteAEditar!.id,
          'nombre_viaje': _nombreController.text.trim(),
          'tipo_viaje': _tipoViajeSeleccionado,
          'estatus_lote': _estatusSeleccionado,
          'ubicacion_actual': _ubicacionController.text.trim(),
        });
      } else {
        // Envolvemos los datos en { } para enviar un Map<String, dynamic>
        await repository.crearLote({
          'nombre_viaje': _nombreController.text.trim(),
          'tipo_viaje': _tipoViajeSeleccionado,
          'estatus_lote': _estatusSeleccionado,
          'ubicacion_actual': _ubicacionController.text.trim(),
        });
      }

      ref.invalidate(lotesProvider);
      if (_esEdicion) {
        ref.invalidate(loteDetalleProvider(widget.loteAEditar!.id));
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_esEdicion ? 'Viaje actualizado exitosamente' : 'Viaje creado exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Actualizar Rastreo / Viaje' : 'Nuevo Viaje / Ruta'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Información General', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              
              CustomTextFormField(
                label: 'Nombre del Viaje o Ruta',
                icon: Icons.local_shipping,
                controller: _nombreController,
                validator: (v) => v!.isEmpty ? 'Ingresa un nombre para identificar el viaje' : null,
              ),
              const SizedBox(height: 16),

              // --- NUEVO: DROPDOWN PARA TIPO DE VIAJE ---
              DropdownButtonFormField<String>(
                value: _tipoViajeSeleccionado,
                decoration: InputDecoration(
                  labelText: 'Tipo de Viaje',
                  prefixIcon: const Icon(Icons.route),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _opcionesTipoViaje.map((tipo) {
                  return DropdownMenuItem(
                    value: tipo,
                    child: Text(tipo == 'Principal' ? 'Viaje Internacional (USA -> MX)' : 'Ruta Local (Reparto en MX)'),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _tipoViajeSeleccionado = val!;
                  });
                },
              ),
              const SizedBox(height: 32),

              const Text('Rastreo y Estatus', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),

              CustomTextFormField(
                label: 'Ubicación Actual',
                icon: Icons.location_on,
                controller: _ubicacionController,
                validator: (v) => v!.isEmpty ? 'La ubicación es requerida' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _estatusSeleccionado,
                decoration: InputDecoration(
                  labelText: 'Estatus del Viaje',
                  prefixIcon: const Icon(Icons.timeline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _opcionesEstatus.map((estatus) {
                  return DropdownMenuItem(
                    value: estatus,
                    child: Text(estatus),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _estatusSeleccionado = val!;
                  });
                },
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _guardarLote,
                  child: Text(_esEdicion ? 'ACTUALIZAR VIAJE' : 'CREAR VIAJE'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}