import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/presentation/widgets/custom_text_form_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/lote_model.dart';
import '../providers/lote_provider.dart';
import '../../../recolector/presentation/providers/recoleccion_provider.dart';
import '../../../../core/presentation/widgets/selector_ubicacion_widget.dart';

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
  
  // --- CONTROLADORES DE INTELIGENCIA LOGÍSTICA ---
  final _enlaceOrigenController = TextEditingController();
  final _enlaceDestinoController = TextEditingController();

  String _estatusSeleccionado = 'Preparación';
  String _tipoViajeSeleccionado = 'Principal'; 
  final List<String> _opcionesTipoViaje = ['Principal', 'Reparto'];

  List<dynamic> _paradasDisponibles = [];
  final Set<int> _paradasSeleccionadas = {};
  bool _cargandoParadas = false;
  bool _isSaving = false;

  // --- VARIABLES DE ESTADO DE OPTIMIZACIÓN ---
  bool _definirOrigen = false;
  String _metodoOrigen = 'GPS';
  
  bool _definirDestino = false;
  String _metodoDestino = 'Enlace';

  bool _rutaCircular = false;

  bool get _esEdicion => widget.loteAEditar != null;
  bool get _todasSeleccionadas => _paradasDisponibles.isNotEmpty && _paradasSeleccionadas.length == _paradasDisponibles.length;

  List<String> get _opcionesEstatusActivas {
    if (_tipoViajeSeleccionado == 'Reparto') return ['Preparación', 'En Tránsito', 'Finalizado'];
    return ['Preparación', 'En Tránsito', 'En Aduana', 'En Bodega México', 'Finalizado'];
  }

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      _nombreController.text = widget.loteAEditar!.nombreViaje;
      _ubicacionController.text = widget.loteAEditar!.ubicacionActual;
      _tipoViajeSeleccionado = widget.loteAEditar!.tipoViaje; 
      _estatusSeleccionado = _opcionesEstatusActivas.contains(widget.loteAEditar!.estatusLote) 
          ? widget.loteAEditar!.estatusLote 
          : 'Preparación';
    } else {
      if (_tipoViajeSeleccionado == 'Principal') Future.microtask(() => _cargarParadas());
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _ubicacionController.dispose();
    _enlaceOrigenController.dispose();
    _enlaceDestinoController.dispose();
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
    if (!serviceEnabled) throw 'GPS desactivado.';
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) throw 'Permisos denegados.';
    }
    // SOLUCIÓN AL WARNING DE DEPRECATED: Usamos LocationSettings
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
    );
  }

  void _toggleSeleccionarTodas() {
    setState(() {
      if (_todasSeleccionadas) {
        _paradasSeleccionadas.clear();
      } else {
        for (var p in _paradasDisponibles) {
          _paradasSeleccionadas.add(p['id'] is int ? p['id'] : int.tryParse(p['id'].toString()) ?? 0);
        }
      }
    });
  }

  Future<void> _guardarLote() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_tipoViajeSeleccionado == 'Principal' && !_esEdicion) {
      if (_definirOrigen && _metodoOrigen == 'Enlace' && _enlaceOrigenController.text.trim().isEmpty) {
        _msg('Ingresa el enlace de partida'); return;
      }
      if (_definirDestino && _metodoDestino == 'Enlace' && _enlaceDestinoController.text.trim().isEmpty) {
        _msg('Ingresa el enlace de llegada'); return;
      }
    }

    setState(() => _isSaving = true);

    try {
      double? latOri, lngOri, latDest, lngDest;
      String? linkOri, linkDest;

      if (_definirOrigen) {
        if (_metodoOrigen == 'GPS') {
          final p = await _obtenerGPS(); latOri = p?.latitude; lngOri = p?.longitude;
        } else { linkOri = _enlaceOrigenController.text.trim(); }
      }

      if (_definirDestino && !_rutaCircular) {
        if (_metodoDestino == 'GPS') {
          final p = await _obtenerGPS(); latDest = p?.latitude; lngDest = p?.longitude;
        } else { linkDest = _enlaceDestinoController.text.trim(); }
      }

      final repository = ref.read(loteRepositoryProvider);
      final idLoteFinal = _esEdicion 
        ? widget.loteAEditar!.id 
        : await repository.crearLote({
            'nombre_viaje': _nombreController.text.trim(),
            'tipo_viaje': _tipoViajeSeleccionado,
            'estatus_lote': _estatusSeleccionado,
            'ubicacion_actual': _ubicacionController.text.trim(),
          });

      if (_esEdicion) {
        await repository.actualizarLote({
          'id': idLoteFinal.toString(),
          'nombre_viaje': _nombreController.text.trim(),
          'tipo_viaje': _tipoViajeSeleccionado,
          'estatus_lote': _estatusSeleccionado,
          'ubicacion_actual': _ubicacionController.text.trim(),
        });
      }

      if (_tipoViajeSeleccionado == 'Principal' && _paradasSeleccionadas.isNotEmpty && !_esEdicion) {
        // SOLUCIÓN A ERROR: Se asume que optimizarYAsignar ya fue actualizado en el provider
        await ref.read(recoleccionRepositoryProvider).optimizarYAsignar(
          idLote: idLoteFinal,
          idsRecolecciones: _paradasSeleccionadas.toList(),
          origenLat: latOri, origenLng: lngOri, origenEnlace: linkOri,
          destinoLat: latDest, destinoLng: lngDest, destinoEnlace: linkDest,
          rutaCircular: _rutaCircular,
        );
      }

      ref.invalidate(lotesProvider);
      if (_esEdicion) ref.invalidate(loteDetalleProvider(widget.loteAEditar!.id));

      if (mounted) {
        Navigator.pop(context);
        _msg(_esEdicion ? 'Actualizado' : 'Creado con éxito', color: AppColors.success);
      }
    } catch (e) {
      if (mounted) _msg(e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _msg(String txt, {Color color = AppColors.error}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(txt), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_esEdicion ? 'Editar Viaje' : 'Nuevo Viaje / Ruta'), centerTitle: true),
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
                label: 'Nombre del Viaje',
                icon: Icons.local_shipping,
                controller: _nombreController,
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _tipoViajeSeleccionado, 
                // SOLUCIÓN A WARNING: Se usa decoration e initialValue implícito por 'value'
                decoration: InputDecoration(
                  labelText: 'Tipo de Viaje', prefixIcon: const Icon(Icons.route),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true, fillColor: Colors.white,
                ),
                items: _opcionesTipoViaje.map((t) => DropdownMenuItem(value: t, child: Text(t == 'Principal' ? 'Internacional' : 'Reparto Local'))).toList(),
                onChanged: _esEdicion ? null : (val) { 
                  setState(() { _tipoViajeSeleccionado = val!; _estatusSeleccionado = 'Preparación'; });
                  if (val == 'Principal' && _paradasDisponibles.isEmpty) _cargarParadas();
                },
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
                label: 'Ubicación Actual', icon: Icons.location_on,
                controller: _ubicacionController,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _estatusSeleccionado,
                decoration: InputDecoration(
                  labelText: 'Estatus', prefixIcon: const Icon(Icons.timeline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true, fillColor: Colors.white,
                ),
                items: _opcionesEstatusActivas.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() => _estatusSeleccionado = val!),
              ),

              if (_tipoViajeSeleccionado == 'Principal' && !_esEdicion) ...[
                const SizedBox(height: 32),
                const Divider(),
                const Text('Inteligencia Logística', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                
                // SOLUCIÓN ERROR ARGUMENTOS: Cambiado 'activo' por 'value' según tu widget
                SelectorUbicacionLogistica(
                  titulo: 'Punto de partida', subtitulo: '¿Desde dónde inicia la ruta?',
                  value: _definirOrigen, metodo: _metodoOrigen, controller: _enlaceOrigenController,
                  onToggle: (v) => setState(() => _definirOrigen = v),
                  onMetodoChanged: (v) => setState(() => _metodoOrigen = v),
                ),

                SelectorUbicacionLogistica(
                  titulo: 'Punto de llegada', subtitulo: '¿Dónde termina el viaje?',
                  value: _definirDestino, metodo: _metodoDestino, controller: _enlaceDestinoController,
                  onToggle: (v) => setState(() { _definirDestino = v; if(v) _rutaCircular = false; }),
                  onMetodoChanged: (v) => setState(() => _metodoDestino = v),
                ),

                SwitchListTile(
                  title: const Text('Ruta Circular', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: const Text('Termina exactamente donde empezó.'),
                  // SOLUCIÓN WARNING: Usar activeThumbColor
                  activeThumbColor: AppColors.primary,
                  value: _rutaCircular,
                  onChanged: _definirOrigen ? (v) => setState(() { _rutaCircular = v; if(v) _definirDestino = false; }) : null,
                ),

                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Text('Paradas Pendientes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    if (_paradasDisponibles.isNotEmpty)
                      TextButton.icon(
                        onPressed: _toggleSeleccionarTodas,
                        icon: Icon(_todasSeleccionadas ? Icons.deselect : Icons.select_all, size: 18),
                        label: Text(_todasSeleccionadas ? 'Ninguna' : 'Todas'),
                      ),
                    IconButton(onPressed: _cargarParadas, icon: const Icon(Icons.refresh, color: AppColors.primary)),
                  ],
                ),
                
                if (_cargandoParadas) 
                  const Center(child: CircularProgressIndicator())
                else
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                    child: ListView.separated(
                      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      itemCount: _paradasDisponibles.length,
                      separatorBuilder: (c, i) => const Divider(height: 1),
                      itemBuilder: (c, i) {
                        final p = _paradasDisponibles[i];
                        final id = p['id'] is int ? p['id'] : int.tryParse(p['id'].toString()) ?? 0;
                        return CheckboxListTile(
                          title: Text(p['direccion_texto'] ?? 'Ubicación WhatsApp', style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('Lat: ${p['latitud']}, Lng: ${p['longitud']}', style: const TextStyle(fontSize: 11)),
                          activeColor: AppColors.primary,
                          value: _paradasSeleccionadas.contains(id),
                          onChanged: (v) => setState(() => v! ? _paradasSeleccionadas.add(id) : _paradasSeleccionadas.remove(id)),
                        );
                      },
                    ),
                  ),
              ],
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _guardarLote,
                  child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : Text(_esEdicion ? 'ACTUALIZAR' : 'CREAR VIAJE'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}