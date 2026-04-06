import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/widgets/custom_text_form_field.dart';
import '../../../lotes/domain/models/lote_model.dart';
import '../../domain/models/paquete_model.dart';
import '../providers/paquete_form_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Importamos los catálogos
// Ajusta esta ruta según la carpeta donde hayas guardado el catalogo_provider
import '../../../catalogos/presentation/providers/catalogo_provider.dart'; 
import '../../../catalogos/domain/models/ubicacion_model.dart';

class FormularioPaqueteScreen extends ConsumerStatefulWidget {
  final PaqueteModel? paqueteAEditar;
  final LoteModel? loteAsociado;

  const FormularioPaqueteScreen({super.key, this.paqueteAEditar, this.loteAsociado});

  @override
  ConsumerState<FormularioPaqueteScreen> createState() => _FormularioPaqueteScreenState();
}

class _FormularioPaqueteScreenState extends ConsumerState<FormularioPaqueteScreen> {
  int _currentStep = 0;
  final _formKeyPaso0 = GlobalKey<FormState>();
  final _formKeyPaso1 = GlobalKey<FormState>();

  final _remitenteController = TextEditingController();
  final _remitenteTelController = TextEditingController();
  final _destinatarioController = TextEditingController();
  final _destinatarioTelController = TextEditingController();
  final _origenController = TextEditingController();
  final _pesoController = TextEditingController();
  String _pesoUnidad = 'Kg';

  final _itemDescController = TextEditingController();
  final _itemCantController = TextEditingController();

  // --- NUEVAS VARIABLES PARA LOS CATÁLOGOS ---
  int? _idEstadoDestino;
  int? _idMunicipioDestino;
  int? _idLocalidadDestino;

  bool get _esEdicion => widget.paqueteAEditar != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      final p = widget.paqueteAEditar!;
      
      _remitenteController.text = p.remitenteNombre;
      _remitenteTelController.text = p.remitenteTelefono ?? ''; 
      _origenController.text = p.remitenteOrigen ?? '';         
      
      _destinatarioController.text = p.destinatarioNombre;
      _destinatarioTelController.text = p.destinatarioContacto ?? ''; 
      
      // Cargamos los IDs de ubicación si los tiene
      _idEstadoDestino = p.idEstadoDestino;
      _idMunicipioDestino = p.idMunicipioDestino;
      _idLocalidadDestino = p.idLocalidadDestino;

      _pesoController.text = p.pesoCantidad.toString();
      _pesoUnidad = p.pesoUnidad;
      
      Future.microtask(() {
        ref.read(paqueteFormProvider.notifier).cargarItemsIniciales(p.items);
      });
    } else {
      Future.microtask(() {
        ref.read(paqueteFormProvider.notifier).limpiarItems();
      });
    }
  }

  @override
  void dispose() {
    _remitenteController.dispose();
    _remitenteTelController.dispose();
    _destinatarioController.dispose();
    _destinatarioTelController.dispose();
    _origenController.dispose();
    _pesoController.dispose();
    _itemDescController.dispose();
    _itemCantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_esEdicion ? 'Editar Paquete' : 'Levantamiento de Carga')),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: _nextStep,
        onStepCancel: _prevStep,
        controlsBuilder: _buildCustomControls,
        steps: [
          _buildStepDirectorio(),
          _buildStepCarga(),
          _buildStepConfirmacion(),
        ],
      ),
    );
  }

  Step _buildStepDirectorio() {
    // 1. Cargamos el estado de los providers de catálogo
    final estadosAsync = ref.watch(estadosProvider);
    
    // 2. Si hay un estado seleccionado, pedimos sus municipios
    final municipiosAsync = _idEstadoDestino != null 
        ? ref.watch(municipiosProvider(_idEstadoDestino!)) 
        : const AsyncValue.data(<UbicacionModel>[]);
        
    // 3. Si hay un municipio seleccionado, pedimos sus localidades
    final localidadesAsync = _idMunicipioDestino != null 
        ? ref.watch(localidadesProvider(_idMunicipioDestino!)) 
        : const AsyncValue.data(<UbicacionModel>[]);

    return Step(
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.editing,
      title: const Text('Contactos'),
      content: Form(
        key: _formKeyPaso0,
        child: Column(
          children: [
            const Text('Datos del Remitente', style: TextStyle(fontWeight: FontWeight.bold)),
            CustomTextFormField(
              label: 'Nombre de quien envía',
              icon: Icons.person_outline,
              controller: _remitenteController,
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            CustomTextFormField(
              label: 'Teléfono Remitente',
              icon: Icons.phone_android,
              keyboardType: TextInputType.phone,
              controller: _remitenteTelController,
            ),
            CustomTextFormField(
              label: 'Origen (Ciudad USA)',
              icon: Icons.location_city,
              controller: _origenController,
            ),
            
            const Divider(height: 32),
            const Text('Datos del Destinatario', style: TextStyle(fontWeight: FontWeight.bold)),
            CustomTextFormField(
              label: 'Nombre de quien recibe',
              icon: Icons.person,
              controller: _destinatarioController,
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            CustomTextFormField(
              label: 'Teléfono Destinatario',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              controller: _destinatarioTelController,
            ),

            const SizedBox(height: 16),
            const Text('Dirección de Destino (México)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 12),

            // --- DROPDOWN: ESTADOS ---
            _buildDropdownCatalogo(
              label: 'Estado',
              icon: Icons.map,
              asyncValue: estadosAsync,
              value: _idEstadoDestino,
              onChanged: (val) {
                setState(() {
                  _idEstadoDestino = val;
                  // Al cambiar estado, limpiamos municipio y localidad
                  _idMunicipioDestino = null;
                  _idLocalidadDestino = null;
                });
              },
            ),
            const SizedBox(height: 12),

            // --- DROPDOWN: MUNICIPIOS ---
            _buildDropdownCatalogo(
              label: 'Municipio',
              icon: Icons.location_city_outlined,
              asyncValue: municipiosAsync,
              value: _idMunicipioDestino,
              enabled: _idEstadoDestino != null,
              onChanged: (val) {
                setState(() {
                  _idMunicipioDestino = val;
                  // Al cambiar municipio, limpiamos localidad
                  _idLocalidadDestino = null;
                });
              },
            ),
            const SizedBox(height: 12),

            // --- DROPDOWN: LOCALIDADES ---
            _buildDropdownCatalogo(
              label: 'Localidad / Colonia',
              icon: Icons.pin_drop_outlined,
              asyncValue: localidadesAsync,
              value: _idLocalidadDestino,
              enabled: _idMunicipioDestino != null,
              onChanged: (val) {
                setState(() {
                  _idLocalidadDestino = val;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET REUTILIZABLE PARA LOS DROPDOWNS (DRY) ---
  Widget _buildDropdownCatalogo({
    required String label,
    required IconData icon,
    required AsyncValue<List<UbicacionModel>> asyncValue,
    required int? value,
    required void Function(int?) onChanged,
    bool enabled = true,
  }) {
    return asyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text('Error al cargar $label', style: const TextStyle(color: Colors.red)),
      data: (lista) {
        // Aseguramos que el valor exista en la lista (previene crashes si se borró un catálogo)
        final isValidValue = lista.any((item) => item.id == value);
        final safeValue = isValidValue ? value : null;

        return DropdownButtonFormField<int>(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey.shade100,
          ),
          initialValue: safeValue,
          isExpanded: true,
          hint: Text(enabled ? 'Seleccionar $label' : 'Primero selecciona la opción anterior'),
          items: enabled 
              ? lista.map((u) => DropdownMenuItem(value: u.id, child: Text(u.nombre))).toList() 
              : null,
          onChanged: enabled ? onChanged : null,
          validator: (v) => null,
        );
      },
    );
  }

  Step _buildStepCarga() {
    final state = ref.watch(paqueteFormProvider);
    
    return Step(
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.editing,
      title: const Text('Carga'),
      content: Form(
        key: _formKeyPaso1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: CustomTextFormField(
                    label: 'Peso / Cantidad',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    controller: _pesoController,
                    validator: (v) => v!.isEmpty ? 'Obligatorio' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _pesoUnidad, 
                    decoration: const InputDecoration(labelText: 'Unidad'),
                    items: ['Kg', 'Lb', 'Galón', 'Litro', 'Pieza', 'Caja']
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (val) => setState(() => _pesoUnidad = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('¿Qué hay dentro de la caja?', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildItemInput(),
            const SizedBox(height: 12),
            _buildItemsList(state),
          ],
        ),
      ),
    );
  }

  Step _buildStepConfirmacion() {
    final state = ref.watch(paqueteFormProvider);
    return Step(
      isActive: _currentStep >= 2,
      title: const Text('Revisión'),
      content: Column(
        children: [
          _buildResumenCard(),
          const SizedBox(height: 16),
          if (state.items.isEmpty)
            const Text('⚠️ Debes agregar al menos un item al contenido.', 
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          else
            Text('✅ ${state.items.length} artículos listos para registro.', 
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildItemInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _itemDescController,
            decoration: const InputDecoration(hintText: 'Descripción (ej. Ropa)'),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: TextField(
            controller: _itemCantController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Cant'),
          ),
        ),
        IconButton(
          onPressed: _addItem,
          icon: const Icon(Icons.add_circle, color: Colors.blue, size: 36),
        ),
      ],
    );
  }

  Widget _buildItemsList(PaqueteFormState state) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: state.items.isEmpty 
        ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No hay items agregados')))
        : ListView.separated(
            shrinkWrap: true,
            itemCount: state.items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) => ListTile(
              title: Text(state.items[i]['descripcion']),
              trailing: Text('x${state.items[i]['cantidad']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              leading: IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                onPressed: () => ref.read(paqueteFormProvider.notifier).eliminarItem(i),
              ),
            ),
          ),
    );
  }

  Widget _buildResumenCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _resumenRow('De:', _remitenteController.text),
            _resumenRow('Para:', _destinatarioController.text),
            _resumenRow('Carga:', '${_pesoController.text} $_pesoUnidad'),
            _resumenRow('Origen USA:', _origenController.text.isEmpty ? 'N/A' : _origenController.text),
          ],
        ),
      ),
    );
  }

  Widget _resumenRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
      ],
    ),
  );

  void _addItem() {
    final desc = _itemDescController.text;
    final cant = int.tryParse(_itemCantController.text) ?? 1;
    if (desc.isNotEmpty) {
      ref.read(paqueteFormProvider.notifier).agregarItem(desc, cant);
      _itemDescController.clear();
      _itemCantController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_formKeyPaso0.currentState!.validate()) {
        setState(() => _currentStep++);
      }
      return;
    }
    if (_currentStep == 1) {
      if (_formKeyPaso1.currentState!.validate()) {
        setState(() => _currentStep++);
      }
      return;
    }
    if (_currentStep == 2) {
      _guardarPaquete();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Future<void> _guardarPaquete() async {
    final authState = ref.read(authProvider);
    final usuarioId = authState.user?.id ?? 0;

    try {
      final Map<String, dynamic> datos = {
        'remitente_nombre': _remitenteController.text,
        'remitente_telefono': _remitenteTelController.text,
        'remitente_origen': _origenController.text,
        'destinatario_nombre': _destinatarioController.text,
        'destinatario_contacto': _destinatarioTelController.text,
        
        // Enviamos los 3 IDs de los catálogos a PHP
        'id_estado_destino': _idEstadoDestino,
        'id_municipio_destino': _idMunicipioDestino,
        'id_localidad_destino': _idLocalidadDestino,

        'peso_cantidad': _pesoController.text,
        'peso_unidad': _pesoUnidad,
      };

      if (_esEdicion) {
        datos['id'] = widget.paqueteAEditar!.id;
        datos['estatus_paquete'] = widget.paqueteAEditar!.estatusPaquete; 
      } else {
        datos['id_usuario_registro'] = usuarioId;
        // NUEVA MÁQUINA DE ESTADOS: El paquete nace en USA
        datos['estatus_paquete'] = 'Recibido USA'; 

        // --- LA MAGIA: Si nos pasaron un viaje, mandamos su ID a PHP ---
        if (widget.loteAsociado != null) {
           datos['id_lote'] = widget.loteAsociado!.id;
        } else {
           datos['estatus_paquete'] = 'Recibido USA'; 
        }
      }

      final exito = await ref.read(paqueteFormProvider.notifier).enviarFormulario(datos, esEdicion: _esEdicion);

      if (exito && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_esEdicion ? 'Paquete actualizado correctamente' : '¡Levantamiento exitoso!'), 
            backgroundColor: Colors.green
          )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildCustomControls(BuildContext context, ControlsDetails details) {
    final formState = ref.watch(paqueteFormProvider);
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: formState.isUploading ? null : details.onStepContinue,
              child: formState.isUploading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_currentStep == 2 ? (_esEdicion ? 'ACTUALIZAR' : 'FINALIZAR REGISTRO') : 'SIGUIENTE'),
            ),
          ),
          if (_currentStep > 0) ...[
            const SizedBox(width: 12),
            TextButton(onPressed: formState.isUploading ? null : details.onStepCancel, child: const Text('REGRESAR')),
          ]
        ],
      ),
    );
  }
}