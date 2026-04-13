import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/custom_text_form_field.dart';
import '../../../../core/theme/app_colors.dart';

class SelectorUbicacionLogistica extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final bool value;
  final ValueChanged<bool> onToggle;
  final String metodo; // 'GPS' o 'Enlace'
  final ValueChanged<String> onMetodoChanged;
  final TextEditingController controller;
  final bool mostrarRadioGPS;

  const SelectorUbicacionLogistica({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.value,
    required this.onToggle,
    required this.metodo,
    required this.onMetodoChanged,
    required this.controller,
    this.mostrarRadioGPS = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitulo, style: const TextStyle(fontSize: 12)),
          activeThumbColor: AppColors.primary,
          value: value,
          onChanged: onToggle,
        ),
        if (value)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    if (mostrarRadioGPS)
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Mi GPS', style: TextStyle(fontSize: 14)),
                          value: 'GPS',
                          groupValue: metodo,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) => onMetodoChanged(val!),
                        ),
                      ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Enlace Maps', style: TextStyle(fontSize: 14)),
                        value: 'Enlace',
                        groupValue: metodo,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => onMetodoChanged(val!),
                      ),
                    ),
                  ],
                ),
                if (metodo == 'Enlace')
                  CustomTextFormField(
                    label: 'Pegar enlace aquí',
                    icon: Icons.link,
                    controller: controller,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}