import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart'; // NUEVO PAQUETE

import '../../../../core/presentation/widgets/custom_text_form_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/lote_model.dart';
import '../providers/lote_provider.dart';
import '../../../recolector/presentation/providers/recoleccion_provider.dart';

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

  final List<String> _opcionesTipoViaje = ['Principal', 'Reparto'];

  List<dynamic> _paradasDisponibles = [];
  final Set<int> _paradasSeleccionadas = {};
  bool _cargandoParadas = false;
  bool _isSaving = false;

  // --- NUEVAS VARIABLES DE OPTIMIZACIÓN LOGÍSTICA ---
  bool _definirOrigen = false;
  bool _rutaCircular = false;
  String _metodoOrigen = 'GPS'; // 'GPS' o 'Enlace'
  final _enlaceOrigenController = TextEditingController();

  List<String> get _opcionesEstatusActivas {
    if (_tipoViajeSeleccionado == 'Reparto') return ['Preparación', 'En Tránsito', 'Finalizado'];
    return ['Preparación', 'En Tránsito', 'En Aduana', 'En Bodega México', 'Finalizado'];
  }

  bool get _esEdicion => widget.loteAEditar != null;

  // --- NUEVA LÓGICA: Seleccionar Todo ---
  bool get _todasSeleccionadas => 
    _paradasDisponibles.isNotEmpty && 
    _paradasSeleccionadas.length == _paradasDisponibles.length;

  void _toggleSeleccionarTodas() {
    setState(() {
      if (_todasSeleccionadas) {
        _paradasSeleccionadas.clear(); // Deseleccionar todo
      } else {
        // Seleccionar todo
        for (var p in _paradasDisponibles) {
          final pId = p['id'] is int ? p['id'] : int.tryParse(p['id'].toString()) ?? 0;
          _paradasSeleccionadas.add(pId);
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      _nombreController.text = widget.loteAEditar!.nombreViaje;
      _ubicacionController.text = widget.loteAEditar!.ubicacionActual;
      _tipoViajeSeleccionado = widget.loteAEditar!.tipoViaje; 
      
      if (_opcionesEstatusActivas.contains(widget.loteAEditar!.estatusLote)) {
        _estatusSeleccionado = widget.loteAEditar!.estatusLote;
      } else {
        _estatusSeleccionado = 'Preparación';
      }
    } else {
      if (_tipoViajeSeleccionado == 'Principal') {
        Future.microtask(() => _cargarParadas());
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _ubicacionController.dispose();
    _enlaceOrigenController.dispose();
    super.dispose();
  }

  Future<void> _cargarParadas() async {
    setState(() => _cargandoParadas = true);
    try {
      final paradas = await ref.read(recoleccionRepositoryProvider).getParadasPendientes();
      if (mounted) setState(() { _paradasDisponibles = paradas; _cargandoParadas = false; });
    } catch (e) {
      if (mounted) setState(() => _cargandoParadas = false);
    }
  }

  Future<Position?> _obtenerGPS() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw 'Los servicios de GPS están desactivados en el teléfono.';

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) throw 'Permisos de ubicación denegados.';
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw 'Los permisos de ubicación están bloqueados permanentemente en los ajustes.';
    } 

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _guardarLote() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Si eligieron usar Enlace pero está vacío
    if (_tipoViajeSeleccionado == 'Principal' && _definirOrigen && _metodoOrigen == 'Enlace' && _enlaceOrigenController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor ingresa el enlace del punto de partida.'), backgroundColor: AppColors.error));
      return;
    }

    setState(() => _isSaving = true);

    try {
      double? latOrigen;
      double? lngOrigen;
      String? enlaceOrigen;

      if (!_esEdicion && _tipoViajeSeleccionado == 'Principal' && _definirOrigen && _metodoOrigen == 'GPS') {
        final position = await _obtenerGPS();
        if (position != null) {
          latOrigen = position.latitude;
          lngOrigen = position.longitude;
        }
      } else if (!_esEdicion && _tipoViajeSeleccionado == 'Principal' && _definirOrigen && _metodoOrigen == 'Enlace') {
        enlaceOrigen = _enlaceOrigenController.text.trim();
      }

      final repository = ref.read(loteRepositoryProvider);
      final datosLote = {
        'nombre_viaje': _nombreController.text.trim(),
        'tipo_viaje': _tipoViajeSeleccionado,
        'estatus_lote': _estatusSeleccionado,
        'ubicacion_actual': _ubicacionController.text.trim(),
      };

      int idLoteFinal;
      if (_esEdicion) {
        idLoteFinal = widget.loteAEditar!.id;
        datosLote['id'] = idLoteFinal.toString();
        await repository.actualizarLote(datosLote);
      } else {
        idLoteFinal = await repository.crearLote(datosLote);
      }

      if (_tipoViajeSeleccionado == 'Principal' && _paradasSeleccionadas.isNotEmpty && !_esEdicion) {
        await ref.read(recoleccionRepositoryProvider).optimizarYAsignar(
          idLote: idLoteFinal,
          idsRecolecciones: _paradasSeleccionadas.toList(),
          origenLat: latOrigen,
          origenLng: lngOrigen,
          origenEnlace: enlaceOrigen,
          rutaCircular: _rutaCircular,
        );
      }

      ref.invalidate(lotesProvider);
      if (_esEdicion) ref.invalidate(loteDetalleProvider(widget.loteAEditar!.id));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_esEdicion ? 'Viaje actualizado exitosamente' : 'Viaje y ruta creados exitosamente'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
                value: _tipoViajeSeleccionado, 
                decoration: InputDecoration(
                  labelText: 'Tipo de Viaje',
                  prefixIcon: const Icon(Icons.route),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _opcionesTipoViaje.map((tipo) {
                  return DropdownMenuItem(value: tipo, child: Text(tipo == 'Principal' ? 'Viaje Internacional (USA -> MX)' : 'Ruta Local (Reparto en MX)'));
                }).toList(),
                onChanged: _esEdicion ? null : (val) { 
                  setState(() {
                    _tipoViajeSeleccionado = val!;
                    if (!_opcionesEstatusActivas.contains(_estatusSeleccionado)) {
                      _estatusSeleccionado = 'Preparación';
                    }
                  });
                  if (val == 'Principal' && _paradasDisponibles.isEmpty) _cargarParadas();
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
                items: _opcionesEstatusActivas.map((estatus) => DropdownMenuItem(value: estatus, child: Text(estatus))).toList(),
                onChanged: (val) { setState(() => _estatusSeleccionado = val!); },
              ),

              if (_tipoViajeSeleccionado == 'Principal' && !_esEdicion) ...[
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                
                const Text('Inteligencia Logística', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),

                SwitchListTile(
                  title: const Text('Definir punto de partida', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Mapbox usará este punto como el inicio de la ruta.', style: TextStyle(fontSize: 12)),
                  activeColor: AppColors.primary,
                  value: _definirOrigen,
                  onChanged: (val) => setState(() => _definirOrigen = val),
                ),

                if (_definirOrigen)
                  Container(
                    margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.blue.withValues(alpha:0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade100)),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Mi GPS Actual', style: TextStyle(fontSize: 14)),
                                value: 'GPS',
                                groupValue: _metodoOrigen,
                                contentPadding: EdgeInsets.zero,
                                onChanged: (val) => setState(() => _metodoOrigen = val!),
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Pegar Enlace', style: TextStyle(fontSize: 14)),
                                value: 'Enlace',
                                groupValue: _metodoOrigen,
                                contentPadding: EdgeInsets.zero,
                                onChanged: (val) => setState(() => _metodoOrigen = val!),
                              ),
                            ),
                          ],
                        ),
                        if (_metodoOrigen == 'Enlace')
                          CustomTextFormField(
                            label: 'Enlace de Maps o WhatsApp',
                            icon: Icons.link,
                            controller: _enlaceOrigenController,
                          ),
                      ],
                    ),
                  ),

                SwitchListTile(
                  title: const Text('Ruta Circular (Roundtrip)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Optimiza la ruta obligando al chofer a terminar donde empezó.', style: TextStyle(fontSize: 12)),
                  activeColor: AppColors.primary,
                  value: _rutaCircular,
                  onChanged: _definirOrigen ? (val) => setState(() => _rutaCircular = val) : null,
                ),

                const SizedBox(height: 24),
                
                // --- CABECERA DE PARADAS CON EL BOTÓN SELECCIONAR TODO ---
                Row(
                  children: [
                    const Expanded(child: Text('Paradas Pendientes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    if (_paradasDisponibles.isNotEmpty)
                      TextButton.icon(
                        onPressed: _toggleSeleccionarTodas,
                        icon: Icon(_todasSeleccionadas ? Icons.deselect : Icons.select_all, size: 18),
                        label: Text(_todasSeleccionadas ? 'Deseleccionar' : 'Todas'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    IconButton(
                      onPressed: _cargarParadas, 
                      icon: const Icon(Icons.refresh, color: AppColors.primary),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                if (_cargandoParadas) 
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                else if (_paradasDisponibles.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20), 
                    child: Text('No hay ubicaciones pendientes.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                  )
                else
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _paradasDisponibles.length,
                      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (context, index) {
                        final p = _paradasDisponibles[index];
                        final pId = p['id'] is int ? p['id'] : int.tryParse(p['id'].toString()) ?? 0;
                        final isSelected = _paradasSeleccionadas.contains(pId);
                        
                        return CheckboxListTile(
                          title: Text(p['direccion_texto'] ?? 'Ubicación sin nombre', style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('Lat: ${p['latitud']}, Lng: ${p['longitud']}', style: const TextStyle(fontSize: 11)),
                          secondary: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                          activeColor: AppColors.primary,
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) _paradasSeleccionadas.add(pId);
                              else _paradasSeleccionadas.remove(pId);
                            });
                          },
                        );
                      },
                    ),
                  ),
              ],

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _guardarLote,
                  child: _isSaving 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : Text(_esEdicion ? 'ACTUALIZAR VIAJE' : 'CREAR VIAJE'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}