import 'package:flutter/material.dart';
import '../../theme/app_colors.dart'; 

class BuscadorFiltroWidget extends StatelessWidget {
  final String filterType;
  final List<String> filterOptions;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSearchChanged;
  
  // --- NUEVOS PARÁMETROS PARA EL ESTATUS ---
  final String statusFilter;
  final List<String> statusOptions;
  final ValueChanged<String> onStatusChanged;

  const BuscadorFiltroWidget({
    super.key,
    required this.filterType,
    required this.filterOptions,
    required this.onFilterChanged,
    required this.onSearchChanged,
    required this.statusFilter,
    required this.statusOptions,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- FILA 1: TIPO DE BÚSQUEDA Y CAJA DE TEXTO ---
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100, 
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300), // Borde elegante
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: filterType,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                  items: filterOptions.map((e) => DropdownMenuItem(
                    value: e, 
                    child: Text(e, style: const TextStyle(fontWeight: FontWeight.w600))
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) onFilterChanged(val);
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar por $filterType...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
                onChanged: onSearchChanged,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),

        // --- FILA 2: CHIPS DE ESTATUS (Deslizables horizontalmente) ---
        SizedBox(
          height: 36, // Altura fija para que el scroll horizontal funcione
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: statusOptions.length,
            itemBuilder: (context, index) {
              final status = statusOptions[index];
              final isSelected = statusFilter == status;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(status),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) onStatusChanged(status);
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  backgroundColor: Colors.grey.shade100,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}