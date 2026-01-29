import 'dart:io';
import 'dart:async';
import 'dart:typed_data';

class AlertListener {
  Socket? _socket;
  bool _isManuallyClosed = false;

  // O StreamController avisa a HomePigeon para rodar o fetchMessages
  final _updateController = StreamController<bool>.broadcast();
  Stream<bool> get onMessageReceived => _updateController.stream;

  Future<void> startListening(String userId) async {
    _isManuallyClosed = false;

    try {
      // Importante: Verifique se o IP é o do servidor Replit ou 10.0.2.2 (emulador)
      // Usar 127.0.0.1 só funciona se o servidor estiver no mesmo aparelho.
      _socket = await Socket.connect('127.0.0.1',8080, timeout: const Duration(seconds: 5));

      print("📡 [EnX] Conectado ao canal de Alerta. Mantendo paridade...");

      // Mantemos a requisição, mas garantimos que o socket não feche
      String request = "POST /listen_alerts HTTP/1.1\r\n"
                       "Host: localhost\r\n"
                       "Content-Type: application/json\r\n"
                       "Connection: keep-alive\r\n\r\n"
                       '{"user_id":"$userId"}';

      _socket!.write(request);

      _socket!.listen(
        (Uint8List data) {
          // Varredura de paridade: Procuramos o byte 0x01 em qualquer lugar do buffer
          if (data.contains(1)) {
            print("🔔 [EnX] Byte 0x01 capturado! Notificando interface...");
            _updateController.add(true); 
          }
        },
        onDone: () {
          print("⚠️ [EnX] Conexão encerrada pelo servidor. Reiniciando paridade...");
          _reconnect(userId);
        },
        onError: (error) {
          print("❌ [EnX] Erro no Socket: $error");
          _reconnect(userId);
        },
        cancelOnError: true,
      );
    } catch (e) {
      print("🔌 [EnX] Servidor de Alerta inacessível. Tentando em 5s...");
      _reconnect(userId);
    }
  }

  void _reconnect(String userId) {
    if (_isManuallyClosed) return;
    _socket?.destroy();
    // Delay para evitar loop infinito de alta CPU
    Future.delayed(const Duration(seconds: 5), () => startListening(userId));
  }

  void stop() {
    _isManuallyClosed = true;
    _socket?.destroy();
    _socket = null;
  }
}
