import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../../features/paquetes/domain/models/paquete_model.dart'; // Ajusta a tu ruta

class PaqueteCardWidget extends StatelessWidget {
  final PaqueteModel paquete;
  final VoidCallback? onTap;
  final Widget? trailing; // Para estatus o botones extra
  final Widget? leading;  // Para Checkboxes

  const PaqueteCardWidget({
    super.key,
    required this.paquete,
    this.onTap,
    this.trailing,
    this.leading,
  });

  Color _obtenerColorEstatus(String estatus) {
    if (estatus == 'Recibido') return AppColors.accent;
    if (estatus == 'En Lote') return AppColors.highlight;
    if (estatus == 'Entregado') return AppColors.success;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final estatusColor = _obtenerColorEstatus(paquete.estatusPaquete);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- CABECERA: CHECKBOX (OPCIONAL), GUÍA Y ESTATUS ---
              Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      paquete.guiaRastreo,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (trailing != null)
                    trailing!
                  else
                    _buildEstatusBadge(paquete.estatusPaquete, estatusColor),
                ],
              ),
              const Divider(height: 24),

              // --- REMITENTE Y ORIGEN ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.outbox, size: 20, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('De: ${paquete.remitenteNombre}', style: Theme.of(context).textTheme.bodyMedium),
                        if (paquete.remitenteOrigen != null && paquete.remitenteOrigen!.isNotEmpty)
                          Text('Origen: ${paquete.remitenteOrigen}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // --- DESTINATARIO Y DESTINO ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.move_to_inbox, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Para: ${paquete.destinatarioNombre}', style: Theme.of(context).textTheme.bodyMedium),
                        if (paquete.destinatarioOrigen != null && paquete.destinatarioOrigen!.isNotEmpty)
                          Text('Destino: ${paquete.destinatarioOrigen}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // --- PESO ---
              Row(
                children: [
                  const Icon(Icons.scale, size: 20, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text('Peso: ${paquete.pesoCantidad} ${paquete.pesoUnidad}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstatusBadge(String estatus, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(estatus, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}