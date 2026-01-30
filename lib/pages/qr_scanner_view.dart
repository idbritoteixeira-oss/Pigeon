import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class QrScannerView extends StatefulWidget {
  @override
  _QrScannerViewState createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isFlashOn = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildQrView(context),
          // Interface de controle para forçar a paridade com o hardware [cite: 2025-10-27]
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Botão para alternar entre as 3 câmeras traseiras [cite: 2025-10-27]
                _scannerActionButton(
                  icon: Icons.flip_camera_ios,
                  onPressed: () async {
                    await controller?.flipCamera();
                    // Alívio: Força o driver a reiniciar na nova lente [cite: 2025-10-27]
                    await controller?.resumeCamera();
                  },
                ),
                _scannerActionButton(
                  icon: isFlashOn ? Icons.flash_on : Icons.flash_off,
                  onPressed: () async {
                    await controller?.toggleFlash();
                    setState(() => isFlashOn = !isFlashOn);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      cameraFacing: CameraFacing.back,
      overlay: QrScannerOverlayShape(
        borderColor: const Color(0xFF25D366),
        borderRadius: 10,
        borderLength: 30,
        borderWidth: 10,
        cutOutSize: 250,
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    // Ponderação Ética: Delay necessário para estabilizar o driver multi-lente [cite: 2025-10-27]
    Future.delayed(const Duration(milliseconds: 600), () {
      controller.resumeCamera();
    });

    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null) {
        controller.pauseCamera();
        Navigator.pop(context, scanData.code);
      }
    });
  }

  Widget _scannerActionButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 28),
        onPressed: onPressed,
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
