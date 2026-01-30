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
      appBar: AppBar(
        title: const Text("Escanear Dweller ID", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F1013),
      ),
      body: QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
        // Força a câmera traseira inicial
        cameraFacing: CameraFacing.back, 
        overlay: QrScannerOverlayShape(
          borderColor: const Color(0xFF25D366),
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: 250,
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;

    // REAVALIAÇÃO COGNITIVA: Delay para dispositivos multi-camera renegociarem o driver
    Future.delayed(const Duration(milliseconds: 500), () async {
      await controller.resumeCamera();
      // TRIUNFO: Tenta alternar a câmera se a primeira falhar (opcional, mas ajuda)
      // await controller.flipCamera(); 
    });

    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null) {
        controller.pauseCamera();
        Navigator.pop(context, scanData.code);
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
