import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../theme/app_colors.dart'; // Ajusta los '../' según tu estructura

class EscanerScreen extends StatefulWidget {
  const EscanerScreen({super.key});

  @override
  State<EscanerScreen> createState() => _EscanerScreenState();
}

class _EscanerScreenState extends State<EscanerScreen> {
  final MobileScannerController controller = MobileScannerController(
    formats: const [BarcodeFormat.all], 
  );
  
  bool _escaneado = false; 

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Escaneando Guía...', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (_escaneado) return; 

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  setState(() => _escaneado = true); 
                  Navigator.pop(context, code); 
                }
              }
            },
          ),
          // Diseño del visor (Retícula)
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accent, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}