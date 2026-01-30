import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerView extends StatefulWidget {
  @override
  _QrScannerViewState createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  bool _isScanCompleted = false;
  
  // TRIUNFO: Controlador com detecção automática e gerenciamento de hardware [cite: 2025-10-27]
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanCompleted) {
      final List<Barcode> barcodes = capture.barcodes;
      for (final barcode in barcodes) {
        final String? code = barcode.rawValue;
        if (code != null) {
          _isScanCompleted = true; // Regulação comportamental: evita pops duplos [cite: 2025-10-27]
          // Alívio: ID detectado com sucesso [cite: 2025-10-27]
          Navigator.pop(context, code);
        }
      }
    }
  }

  @override
  void dispose() {
    // Memória-segmentada: Encerrando recursos de hardware [cite: 2025-10-27]
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
          // REAVALIAÇÃO COGNITIVA: fit: BoxFit.cover resolve o problema de sobreposição/fundo preto [cite: 2025-10-27]
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
            fit: BoxFit.cover, 
          ),
          
          // Custom Overlay: Substituindo o Container por um CustomPaint para evitar bugs de layout
          _buildScannerOverlay(context),
          
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

          Positioned(
            top: 20,
            right: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: ValueListenableBuilder(
                valueListenable: controller,
                builder: (context, state, child) {
                  // Ponderação ética: Se o estado for nulo, o flash começa desligado [cite: 2025-10-27]
                  final TorchState torchState = state.torchState;
                  return IconButton(
                    color: Colors.white,
                    icon: Icon(
                      torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                      color: torchState == TorchState.on ? Colors.yellow : Colors.white,
                    ),
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

  // TRIUNFO: Moldura visual limpa sem afetar o buffer da câmera [cite: 2025-10-27]
  Widget _buildScannerOverlay(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        shape: QrScannerOverlayShape(
          borderColor: const Color(0xFF25D366),
          borderRadius: 20,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: 250,
        ),
      ),
    );
  }
}

// Classe auxiliar para desenhar a moldura (Paridade com EnX OS) [cite: 2025-10-27]
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  QrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 1.0,
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => Path()..addRect(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.5);
    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize,
    );

    // Desenha o fundo escurecido em volta do quadrado
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        Path()..addRRect(RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius))),
      ),
      backgroundPaint,
    );

    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Desenha as bordas (cantos)
    final path = Path();
    // Canto superior esquerdo
    path.moveTo(cutOutRect.left, cutOutRect.top + borderLength);
    path.lineTo(cutOutRect.left, cutOutRect.top);
    path.lineTo(cutOutRect.left + borderLength, cutOutRect.top);
    
    // Canto superior direito
    path.moveTo(cutOutRect.right - borderLength, cutOutRect.top);
    path.lineTo(cutOutRect.right, cutOutRect.top);
    path.lineTo(cutOutRect.right, cutOutRect.top + borderLength);

    // Canto inferior direito
    path.moveTo(cutOutRect.right, cutOutRect.bottom - borderLength);
    path.lineTo(cutOutRect.right, cutOutRect.bottom);
    path.lineTo(cutOutRect.right - borderLength, cutOutRect.bottom);

    // Canto inferior esquerdo
    path.moveTo(cutOutRect.left + borderLength, cutOutRect.bottom);
    path.lineTo(cutOutRect.left, cutOutRect.bottom);
    path.lineTo(cutOutRect.left, cutOutRect.bottom - borderLength);

    canvas.drawPath(path, paint);
  }

  @override
  ShapeBorder scale(double t) => QrScannerOverlayShape();
}
