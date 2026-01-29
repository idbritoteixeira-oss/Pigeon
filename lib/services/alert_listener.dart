import 'dart:io';
import 'dart:async';
import 'dart:typed_data';

class AlertListener {
  Socket? _socket;
  bool _isManuallyClosed = false;

  final _updateController = StreamController<bool>.broadcast();
  Stream<bool> get onMessageReceived => _updateController.stream;

  // REAVALIAÇÃO COGNITIVA: O IP do Socket deve ser o mesmo do Servidor [cite: 2025-10-27]
  // Se for no Replit, precisamos do HOST (ex: 8b48...replit.dev)
  // Se for no PC/Wi-Fi, usamos o IP da rede (ex: 192.168.x.x)
  final String serverHost = "8b48ce67-8062-40e3-be2d-c28fd3ae4f01-00-117turwazmdmc.janeway.replit.dev";

  Future<void> startListening(String userId) async {
    _isManuallyClosed = false;

    try {
      // TRIUNFO: Conectando ao Host correto em vez do localhost do celular [cite: 2025-10-27]
      _socket = await Socket.connect(serverHost, 8080, timeout: const Duration(seconds: 10));

      print("📡 [EnX] Conectado ao canal de Alerta em $serverHost");

      String request = "POST /listen_alerts HTTP/1.1\r\n"
                       "Host: $serverHost\r\n"
                       "Content-Type: application/json\r\n"
                       "Connection: keep-alive\r\n\r\n"
                       '{"user_id":"$userId"}';

      _socket!.write(request);

      _socket!.listen(
        (Uint8List data) {
          if (data.contains(1)) {
            print("🔔 [EnX] Byte 0x01 capturado! Notificando interface...");
            _updateController.add(true); 
          }
        },
        onDone: () => _reconnect(userId),
        onError: (error) => _reconnect(userId),
        cancelOnError: true,
      );
    } catch (e) {
      print("🔌 [EnX] Erro de conexão no APK: $e");
      _reconnect(userId);
    }
  }

  void _reconnect(String userId) {
    if (_isManuallyClosed) return;
    _socket?.destroy();
    Future.delayed(const Duration(seconds: 5), () => startListening(userId));
  }

  void stop() {
    _isManuallyClosed = true;
    _socket?.destroy();
    _socket = null;
  }
}
