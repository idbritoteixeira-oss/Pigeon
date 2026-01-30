import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerView extends StatefulWidget {
  @override
  _QrScannerViewState createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  bool _isScanCompleted = false;
  
  // TRIUNFO: Controlador configurado para gerenciar o hardware da câmera [cite: 2025-10-27]
  final MobileScannerController controller = MobileScannerController();

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanCompleted) {
      final List<Barcode> barcodes = capture.barcodes;
      for (final barcode in barcodes) {
        final String? code = barcode.rawValue;
        if (code != null) {
          setState(() => _isScanCompleted = true);
          
          // Alívio: ID detectado com sucesso, retornando dado ao sistema [cite: 2025-10-27]
          Navigator.pop(context, code);
        }
      }
    }
  }

  @override
  void dispose() {
    // Memória-segmentada: Encerrando processo da câmera para poupar energia
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Escanear Dweller ID", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F1013),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // REAVALIAÇÃO COGNITIVA: MobileScanner v5+ exige o controller para permissões automáticas
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          
          // Moldura visual (Paridade com EnX OS)
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF25D366), width: 2), 
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  "Aponte para o QR Code de um amigo",
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),

          // CALIBRAGEM: Ajuste do torchState para mobile_scanner 5.x (Triunfo) [cite: 2025-10-27]
          Positioned(
            top: 20,
            right: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: ValueListenableBuilder<MobileScannerState>(
                valueListenable: controller,
                builder: (context, state, child) {
                  return IconButton(
                    color: Colors.white,
                    icon: _buildTorchIcon(state.torchState),
                    onPressed: () => controller.toggleTorch(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Ponderação Ética: Garante que um Widget sempre seja retornado (Evita erro de Build)
  Widget _buildTorchIcon(TorchState state) {
    switch (state) {
      case TorchState.off:
        return const Icon(Icons.flash_off, color: Colors.grey);
      case TorchState.on:
        return const Icon(Icons.flash_on, color: Colors.yellow);
      default:
        return const Icon(Icons.flash_off, color: Colors.grey);
    }
  }
}
