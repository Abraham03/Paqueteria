import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart'; // Para el portapapeles
import '../../../../core/theme/app_colors.dart';
import '../../../../../core/presentation/widgets/custom_text_form_field.dart';
import '../providers/recoleccion_provider.dart';

class ModalNuevaRecoleccion extends ConsumerStatefulWidget {
  final int? loteId;
  const ModalNuevaRecoleccion({super.key, this.loteId});

  @override
  ConsumerState<ModalNuevaRecoleccion> createState() => _ModalNuevaRecoleccionState();
}

class _ModalNuevaRecoleccionState extends ConsumerState<ModalNuevaRecoleccion> {
  final _formKey = GlobalKey<FormState>();
  final _enlaceController = TextEditingController();
  final _referenciasController = TextEditingController();

  Future<void> _pegarDelPortapapeles() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && (data.text?.contains('http') ?? false)) {
      setState(() {
        _enlaceController.text = data.text!;
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final exito = await ref.read(crearRecoleccionProvider.notifier).crear(
        _enlaceController.text.trim(),
        _referenciasController.text.trim(),
      );

      if (exito && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Parada registrada y lista para optimizar!'), backgroundColor: AppColors.success)
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUploading = ref.watch(crearRecoleccionProvider);

    return Container(
      padding: EdgeInsets.only(
        top: 24, left: 24, right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24, // Sube si se abre el teclado
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Nueva Recolección', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            
            // Campo del enlace con botón rápido para pegar
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomTextFormField(
                    label: 'Enlace de WhatsApp / Maps',
                    icon: Icons.link,
                    controller: _enlaceController,
                    validator: (v) {
                      if (v!.isEmpty) return 'Requerido';
                      if (!v.contains('http')) return 'Debe ser un enlace válido';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 56, // Misma altura que el input
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha:0.1), borderRadius: BorderRadius.circular(12)),
                  child: IconButton(
                    icon: const Icon(Icons.content_paste, color: AppColors.primary),
                    onPressed: _pegarDelPortapapeles,
                    tooltip: 'Pegar',
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            
            CustomTextFormField(
              label: 'Referencias (Ej. Casa portón negro)',
              icon: Icons.notes,
              controller: _referenciasController,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isUploading ? null : _guardar,
                child: isUploading 
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : const Text('REGISTRAR PARADA', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}