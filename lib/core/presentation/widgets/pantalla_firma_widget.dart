import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- IMPORTANTE PARA ROTAR PANTALLA
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import '../../theme/app_colors.dart';

class PantallaFirmaWidget extends StatefulWidget {
  final String nombreDestinatario;

  const PantallaFirmaWidget({super.key, required this.nombreDestinatario});

  @override
  State<PantallaFirmaWidget> createState() => _PantallaFirmaWidgetState();
}

class _PantallaFirmaWidgetState extends State<PantallaFirmaWidget> {
  late final SignatureController _signatureController;

  @override
  void initState() {
    super.initState();
    // Forzamos la orientación a horizontal (landscape) al entrar a esta pantalla
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _signatureController.dispose();
    // Restauramos la orientación a vertical (portrait) al salir de la pantalla
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  Future<void> _guardarFirma() async {
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, proporciona una firma.')),
      );
      return;
    }

    try {
      final Uint8List? signatureData = await _signatureController.toPngBytes();
      
      if (signatureData != null) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/firma_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(signatureData);

        if (mounted) {
          Navigator.pop(context, file);
        }
      } else {
        throw Exception('No se pudo generar la imagen de la firma.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar la firma: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Al estar en horizontal, la AppBar puede estorbar.
    // Usamos SafeArea y una estructura más limpia.
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Row(
          children: [
            // Panel lateral izquierdo para los controles
            Container(
              width: 200,
              color: Colors.grey.shade100,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Firma de Recibido',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.nombreDestinatario,
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () => _signatureController.clear(),
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpiar'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _guardarFirma,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                  )
                ],
              ),
            ),
            // Área principal para la firma
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      // Línea base para la firma
                      Center(
                        child: Container(
                          height: 1,
                          width: MediaQuery.of(context).size.width * 0.5,
                          color: Colors.grey.shade300,
                        ),
                      ),
                      Signature(
                        controller: _signatureController,
                        backgroundColor: Colors.transparent, // Transparente para ver la línea base
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}