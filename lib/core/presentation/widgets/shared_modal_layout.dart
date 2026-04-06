// Archivo: lib/core/presentation/widgets/shared_modal_layout.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class SharedModalLayout extends StatelessWidget {
  final String titulo;
  final Widget buscador;
  final Widget listado;
  final Widget? cabeceraExtra;
  final Widget? piePagina;

  const SharedModalLayout({
    super.key,
    required this.titulo,
    required this.buscador,
    required this.listado,
    this.cabeceraExtra,
    this.piePagina,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(titulo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: buscador,
          ),
          if (cabeceraExtra != null) cabeceraExtra!,
          if (cabeceraExtra == null) const Divider(height: 30),
          Expanded(child: listado),
          if (piePagina != null) piePagina!,
        ],
      ),
    );
  }
}