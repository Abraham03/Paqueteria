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
  String _tipoViajeSeleccionado = 'Principal'; 

  final List<String> _opcionesTipoViaje = [
    'Principal',
    'Reparto'
  ];

  // --- NUEVO: LÓGICA DINÁMICA (GETTER) ---
  // Retorna la lista correcta dependiendo del tipo de viaje seleccionado
  List<String> get _opcionesEstatusActivas {
    if (_tipoViajeSeleccionado == 'Reparto') {
      return [
        'Preparación',
        'En Tránsito',
        'Finalizado'
      ];
    }
    // Si es Principal, retorna todas
    return [
      'Preparación',
      'En Tránsito',
      'En Aduana',
      'En Bodega México',
      'Finalizado'
    ];
  }

  bool get _esEdicion => widget.loteAEditar != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      _nombreController.text = widget.loteAEditar!.nombreViaje;
      _ubicacionController.text = widget.loteAEditar!.ubicacionActual;
      _tipoViajeSeleccionado = widget.loteAEditar!.tipoViaje; 
      
      // Validamos que el estatus guardado sea compatible con las opciones actuales, 
      // de lo contrario, ponemos 'Preparación' por defecto
      if (_opcionesEstatusActivas.contains(widget.loteAEditar!.estatusLote)) {
        _estatusSeleccionado = widget.loteAEditar!.estatusLote;
      } else {
        _estatusSeleccionado = 'Preparación';
      }
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

      final datosLote = {
        'nombre_viaje': _nombreController.text.trim(),
        'tipo_viaje': _tipoViajeSeleccionado,
        'estatus_lote': _estatusSeleccionado,
        'ubicacion_actual': _ubicacionController.text.trim(),
      };

      if (_esEdicion) {
        datosLote['id'] = widget.loteAEditar!.id.toString(); // Agregamos el ID si es edición
        await repository.actualizarLote(datosLote);
      } else {
        await repository.crearLote(datosLote);
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

              DropdownButtonFormField<String>(
                value: _tipoViajeSeleccionado, // Usamos value en lugar de initialValue
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
                // Al estar en edición, bloqueamos el cambio de tipo de viaje 
                // para no romper la logística, a menos que quieras que puedan cambiarlo.
                onChanged: _esEdicion ? null : (val) { 
                  setState(() {
                    _tipoViajeSeleccionado = val!;
                    
                    // PROTECCIÓN: Si al cambiar de tipo, el estatus actual ya no existe en la nueva lista, lo reseteamos.
                    if (!_opcionesEstatusActivas.contains(_estatusSeleccionado)) {
                      _estatusSeleccionado = 'Preparación';
                    }
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
                value: _estatusSeleccionado, // Usamos value para que reaccione al setState
                decoration: InputDecoration(
                  labelText: 'Estatus del Viaje',
                  prefixIcon: const Icon(Icons.timeline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                // LLAMAMOS AL GETTER DINÁMICO EN LUGAR DE LA LISTA ESTÁTICA
                items: _opcionesEstatusActivas.map((estatus) {
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