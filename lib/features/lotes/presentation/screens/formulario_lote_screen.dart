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
  
  final _enlaceOrigenController = TextEditingController();
  final _enlaceDestinoController = TextEditingController();

  String _estatusSeleccionado = 'Preparación';
  String _tipoViajeSeleccionado = 'Principal'; 
  final List<String> _opcionesTipoViaje = ['Principal', 'Reparto'];

  List<dynamic> _paradasDisponibles = [];
  final Set<int> _paradasSeleccionadas = {};
  bool _cargandoParadas = false;
  bool _isSaving = false;

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
    }
    
    // Ahora SIEMPRE cargamos las paradas si es viaje Principal (sea edición o nuevo)
    // Usamos microtask para permitir que el widget se construya y el context esté disponible.
    if (_tipoViajeSeleccionado == 'Principal') {
      Future.microtask(() => _cargarParadas(cargarDatosDeEdicion: _esEdicion));
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

  Future<void> _cargarParadas({bool cargarDatosDeEdicion = false}) async {
    setState(() => _cargandoParadas = true);
    try {
      final repo = ref.read(recoleccionRepositoryProvider);
      
      // 1. Obtenemos las pendientes globales
      final paradasPendientes = await repo.getParadasPendientes();
      List<dynamic> paradasDeEsteViaje = [];

      // 2. Si estamos editando, traemos también los parámetros logísticos y las paradas que YA estaban asignadas
      if (cargarDatosDeEdicion && widget.loteAEditar != null) {
        // Pedimos al repositorio la lista de paradas que tiene el lote actualmente
        paradasDeEsteViaje = await repo.getParadasPorLote(widget.loteAEditar!.id);
        
        // Recuperamos los parámetros logísticos analizando la respuesta de las paradas (START/END)
        for (var p in paradasDeEsteViaje) {
           if (p['id'] == 'START') {
              _definirOrigen = true;
              _metodoOrigen = 'Enlace';
              _enlaceOrigenController.text = "${p['latitud']},${p['longitud']}"; // Coordenadas crudas
           } else if (p['id'] == 'END') {
              _definirDestino = true;
              _metodoDestino = 'Enlace';
              _enlaceDestinoController.text = "${p['latitud']},${p['longitud']}";
           } else if (p['id'] == 'END_FORZADO') {
              _definirOrigen = true;
              _rutaCircular = true;
           } else if (p['id'] is int || int.tryParse(p['id'].toString()) != null) {
              // Si es un ID normal, es una parada que pertenece al viaje. La pre-seleccionamos.
              _paradasSeleccionadas.add(p['id'] is int ? p['id'] : int.parse(p['id'].toString()));
           }
        }
      }

      if (mounted) {
        setState(() { 
          // Juntamos las pendientes con las que ya tiene el viaje para mostrarlas todas en la lista
          _paradasDisponibles = [
             ...paradasDeEsteViaje.where((p) => p['id'] != 'START' && p['id'] != 'END' && p['id'] != 'END_FORZADO'), 
             ...paradasPendientes
          ];
          
          // Eliminamos duplicados por ID por si acaso
          final idsVistos = <int>{};
          _paradasDisponibles.retainWhere((p) {
             final id = p['id'] is int ? p['id'] : int.tryParse(p['id'].toString()) ?? 0;
             return idsVistos.add(id);
          });

          _cargandoParadas = false; 
        });
      }
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
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
    );
  }

  void _toggleSeleccionarTodas() {
    setState(() {
      if (_todasSeleccionadas || _paradasSeleccionadas.isNotEmpty) {
        _paradasSeleccionadas.clear();
      } else {
        for (var p in _paradasDisponibles) {
          _paradasSeleccionadas.add(p['id'] is int ? p['id'] : int.tryParse(p['id'].toString()) ?? 0);
        }
      }
    });
  }

  Map<String, double>? _extraerCoordenadasDesdeEnlace(String enlace) {
    if (enlace.isEmpty) return null;
    
    // Si ya son coordenadas crudas (ej. "20.44,-99.16") que cargó la edición
    final rawDirectRegex = RegExp(r'^([-+]?\d{1,2}\.\d+),([-+]?\d{1,3}\.\d+)$');
    final matchDirect = rawDirectRegex.firstMatch(enlace.trim());
    if (matchDirect != null) {
      return {'lat': double.parse(matchDirect.group(1)!), 'lng': double.parse(matchDirect.group(2)!)};
    }

    final googleMapsRegex = RegExp(r'@([-+]?\d{1,2}\.\d+),([-+]?\d{1,3}\.\d+)');
    final matchGoogle = googleMapsRegex.firstMatch(enlace);
    if (matchGoogle != null) {
      return {'lat': double.parse(matchGoogle.group(1)!), 'lng': double.parse(matchGoogle.group(2)!)};
    }

    final rawUrlRegex = RegExp(r'([-+]?\d{1,2}\.\d+)%2C([-+]?\d{1,3}\.\d+)');
    final matchUrl = rawUrlRegex.firstMatch(enlace.replaceAll(',', '%2C'));
    if (matchUrl != null) {
        return {'lat': double.parse(matchUrl.group(1)!), 'lng': double.parse(matchUrl.group(2)!)};
    }
    return null;
  }

  Future<void> _guardarLote() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Ahora exigimos los enlaces también en edición si los switches están activos
    if (_definirOrigen && _metodoOrigen == 'Enlace' && _enlaceOrigenController.text.trim().isEmpty) {
      _msg('Ingresa el enlace de partida'); return;
    }
    if (_definirDestino && _metodoDestino == 'Enlace' && _enlaceDestinoController.text.trim().isEmpty) {
      _msg('Ingresa el enlace de llegada'); return;
    }

    setState(() => _isSaving = true);

    try {
      double? latOri, lngOri, latDest, lngDest;

      if (_definirOrigen) {
        if (_metodoOrigen == 'GPS') {
          final p = await _obtenerGPS(); 
          latOri = p?.latitude; 
          lngOri = p?.longitude;
        } else { 
          final coords = _extraerCoordenadasDesdeEnlace(_enlaceOrigenController.text.trim());
          if (coords == null) {
             _msg('No se detectaron coordenadas válidas en el enlace de origen.');
             setState(() => _isSaving = false);
             return;
          }
          latOri = coords['lat'];
          lngOri = coords['lng'];
        }
      }

      if (_definirDestino && !_rutaCircular) {
        if (_metodoDestino == 'GPS') {
          final p = await _obtenerGPS(); 
          latDest = p?.latitude; 
          lngDest = p?.longitude;
        } else { 
          final coords = _extraerCoordenadasDesdeEnlace(_enlaceDestinoController.text.trim());
          if (coords == null) {
             _msg('No se detectaron coordenadas válidas en el enlace de destino.');
             setState(() => _isSaving = false);
             return;
          }
          latDest = coords['lat'];
          lngDest = coords['lng'];
        }
      }

      final repository = ref.read(loteRepositoryProvider);
      
      final loteData = {
        'nombre_viaje': _nombreController.text.trim(),
        'tipo_viaje': _tipoViajeSeleccionado,
        'estatus_lote': _estatusSeleccionado,
        'ubicacion_actual': _ubicacionController.text.trim(),
        'origen_lat': latOri,
        'origen_lng': lngOri,
        'destino_lat': latDest,
        'destino_lng': lngDest,
        'ruta_circular': _rutaCircular,
      };

      final idLoteFinal = _esEdicion 
        ? widget.loteAEditar!.id 
        : await repository.crearLote(loteData);

      if (_esEdicion) {
        loteData['id'] = idLoteFinal.toString();
        await repository.actualizarLote(loteData);
      }

      // --- ASIGNACIÓN (APLICA PARA CREAR O EDITAR VIAJE PRINCIPAL) ---
      // Siempre ejecutamos la asignación en viajes principales, para que el servidor sepa si agregamos o quitamos paradas.
      if (_tipoViajeSeleccionado == 'Principal') {
        // En el backend, asegúrate que "asignarParadas" (RecoleccionController->asignar)
        // se encargue de "soltar" las paradas que ya no vengan en idsRecolecciones.
        // Como tu backend actual asigna por IDs, al actualizar el viaje y mandarle una nueva lista, las tomará. 
        // Nota: Para que sea perfecto al editar, el backend debería desvincular las que no vengan, 
        // pero por ahora funcionará para AGREGAR nuevas paradas o mantener las existentes.
        await ref.read(recoleccionRepositoryProvider).asignarParadas(
          idLote: idLoteFinal,
          idsRecolecciones: _paradasSeleccionadas.toList(),
          origenLat: latOri, origenLng: lngOri, origenEnlace: null, 
          destinoLat: latDest, destinoLng: lngDest, destinoEnlace: null,
          rutaCircular: _rutaCircular,
        );
      } 

      ref.invalidate(lotesProvider);
      if (_esEdicion) {
        ref.invalidate(loteDetalleProvider(widget.loteAEditar!.id));
        ref.invalidate(paradasPorLoteProvider(widget.loteAEditar!.id));
      }

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

              const SizedBox(height: 32),
              const Divider(),
              const Text('Inteligencia Logística', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              
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
                activeThumbColor: AppColors.primary,
                value: _rutaCircular,
                onChanged: _definirOrigen ? (v) => setState(() { _rutaCircular = v; if(v) _definirDestino = false; }) : null,
              ),

              if (_tipoViajeSeleccionado == 'Principal') ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Text('Paradas del Viaje', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    if (_paradasDisponibles.isNotEmpty)
                      TextButton.icon(
                        onPressed: _toggleSeleccionarTodas,
                        icon: Icon(_todasSeleccionadas ? Icons.deselect : Icons.select_all, size: 18),
                        label: Text(_todasSeleccionadas ? 'Ninguna' : 'Todas'),
                      ),
                    IconButton(onPressed: () => _cargarParadas(cargarDatosDeEdicion: _esEdicion), icon: const Icon(Icons.refresh, color: AppColors.primary)),
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
                          onChanged: (v) {
                            setState(() {
                              if (v!) {
                                _paradasSeleccionadas.add(id);
                              } else {
                                _paradasSeleccionadas.remove(id);
                              }
                            });
                          },
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
                  child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : Text(_esEdicion ? 'ACTUALIZAR VIAJE' : 'CREAR VIAJE'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}