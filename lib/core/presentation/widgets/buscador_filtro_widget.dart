import 'package:flutter/material.dart';
import '../../theme/app_colors.dart'; // Ajusta la ruta a tus colores

class BuscadorFiltroWidget extends StatelessWidget {
  final String filterType;
  final List<String> filterOptions;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onScanPressed;

  const BuscadorFiltroWidget({
    super.key,
    required this.filterType,
    required this.filterOptions,
    required this.onFilterChanged,
    required this.onSearchChanged,
    required this.onScanPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 1. Selector de Filtro (Dropdown)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100, 
            borderRadius: BorderRadius.circular(12)
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: filterType,
              items: filterOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) {
                if (val != null) onFilterChanged(val);
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        
        // 2. Campo de Texto (Buscador)
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar...',
              prefixIcon: Icon(Icons.search),
              contentPadding: EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: onSearchChanged,
          ),
        ),
        const SizedBox(width: 8),
        
        // 3. Botón de Escáner
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary, 
            borderRadius: BorderRadius.circular(12)
          ),
          child: IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            onPressed: onScanPressed,
          ),
        )
      ],
    );
  }
}