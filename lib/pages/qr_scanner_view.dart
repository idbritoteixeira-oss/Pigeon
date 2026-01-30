import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerView extends StatefulWidget {
  @override
  _QrScannerViewState createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  bool _isScanCompleted = false;
  
  // TRIUNFO: Controlador para gerenciar permissões e ciclo de vida da câmera [cite: 2025-10-27]
  final MobileScannerController controller = MobileScannerController();

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanCompleted) {
      final List<Barcode> barcodes = capture.barcodes;
      for (final barcode in barcodes) {
        final String? code = barcode.rawValue;
        if (code != null) {
          setState(() => _isScanCompleted = true);
          
          // Alívio: ID detectado com sucesso, fechando scanner [cite: 2025-10-27]
          Navigator.pop(context, code);
        }
      }
    }
  }

  @override
  void dispose() {
    // Memória-segmentada: Liberando a câmera ao sair da página
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
          // REAVALIAÇÃO COGNITIVA: O MobileScanner usa o controller para pedir permissão no boot
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          
          // Moldura visual para o utilizador (Estilo EnX OS)
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF25D366), width: 2), // Verde Pigeon
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

          // Botão para alternar Lanterna (Livre-arbítrio)
          Positioned(
            top: 20,
            right: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                color: Colors.white,
                icon: ValueListenableBuilder(
                  valueListenable: controller.torchState,
                  builder: (context, state, child) {
                    switch (state) {
                      case TorchState.off:
                        return const Icon(Icons.flash_off, color: Colors.grey);
                      case TorchState.on:
                        return const Icon(Icons.flash_on, color: Colors.yellow);
                    }
                  },
                ),
                onPressed: () => controller.toggleTorch(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
