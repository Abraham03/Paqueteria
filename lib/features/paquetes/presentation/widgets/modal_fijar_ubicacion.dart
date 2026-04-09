import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/paquete_provider.dart';

class ModalFijarUbicacion extends ConsumerStatefulWidget {
  final int idPaquete;

  const ModalFijarUbicacion({super.key, required this.idPaquete});

  @override
  ConsumerState<ModalFijarUbicacion> createState() => _ModalFijarUbicacionState();
}

class _ModalFijarUbicacionState extends ConsumerState<ModalFijarUbicacion> {
  final _enlaceController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _enlaceController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    // 1. Evitamos que envíe el formulario si está vacío
    if (_enlaceController.text.trim().isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, pega un enlace primero.'), backgroundColor: Colors.orange)
      );
      return;
    }

    // 2. Activamos el indicador de carga
    setState(() => _isLoading = true);
    
    // 3. Guardamos el mensajero antes de hacer cualquier cosa asíncrona
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    try {
      // 4. Llamamos a tu repositorio (que sabemos que funciona perfecto)
      await ref.read(paqueteRepositoryProvider).fijarUbicacionPaquete(
        widget.idPaquete, 
        _enlaceController.text.trim()
      );
      
      // 5. Si fue exitoso, cerramos el modal
      nav.pop(true); 
      
      // 6. Mostramos el mensaje de éxito
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Ubicación fijada en el servidor correctamente.'), backgroundColor: AppColors.success)
      );

    } catch (e) {
      // Si falla, mostramos el error sin cerrar el modal para que el usuario pueda corregir el link
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error)
      );
    } finally {
      // Apagamos el indicador de carga siempre
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos MediaQuery para saber cuánto espacio ocupa el teclado en pantalla
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // SingleChildScrollView asegura que el contenido no se "aplaste" por el teclado
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: 24, left: 24, right: 24,
          // Le sumamos el tamaño del teclado + un espacio extra al padding inferior
          bottom: bottomInset + 24, 
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Fijar Ubicación de Entrega', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Pega el enlace de Google Maps o WhatsApp que te envió el cliente. El sistema calculará las coordenadas automáticamente.', 
              style: TextStyle(color: Colors.grey, fontSize: 13)
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _enlaceController,
              // Esto hace que el teclado muestre el botón "Hecho" en lugar de un salto de línea
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                // Si el usuario presiona "Enter" en el teclado, intenta guardar
                if (!_isLoading) _guardar();
              },
              decoration: InputDecoration(
                labelText: 'Enlace de ubicación',
                hintText: 'Ej. https://maps.app.goo.gl/...',
                prefixIcon: const Icon(Icons.map),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, 
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                onPressed: _isLoading ? null : _guardar, // null desactiva el botón mientras carga
                child: _isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('GUARDAR UBICACIÓN', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}