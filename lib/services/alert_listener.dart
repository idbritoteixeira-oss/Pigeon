import 'dart:io';
import 'dart:async';
import 'dart:typed_data';

class AlertListener {
  Socket? _socket;
  bool _isManuallyClosed = false;

  final _updateController = StreamController<bool>.broadcast();
  Stream<bool> get onMessageReceived => _updateController.stream;

  final String serverHost = "8b48ce67-8062-40e3-be2d-c28fd3ae4f01-00-117turwazmdmc.janeway.replit.dev";

  Future<void> startListening(String userId) async {
    _isManuallyClosed = false;

    try {
      // REAVALIAÇÃO COGNITIVA: No Replit, a porta EXTERNA mapeada é a 80! [cite: 2025-10-27, 2026-01-29]
      // Conectar na 8080 via APK causa frustração porque o proxy do Replit bloqueia. [cite: 2025-10-27]
      _socket = await Socket.connect(serverHost, 80, timeout: const Duration(seconds: 15));

      print("📡 [EnX] Conectado via Porta 80. Mantendo paridade com Replit...");

      // O Host no Header HTTP deve ser o domínio do Replit para o proxy aceitar.
      String request = "POST /listen_alerts HTTP/1.1\r\n"
                       "Host: $serverHost\r\n"
                       "Content-Type: application/json\r\n"
                       "Connection: keep-alive\r\n\r\n"
                       '{"user_id":"$userId"}';

      _socket!.write(request);

      _socket!.listen(
        (Uint8List data) {
          // Buscando o sinal de vida (byte 0x01) no fluxo de dados. [cite: 2025-10-27]
          if (data.contains(1)) {
            print("🔔 [EnX] Sinal capturado! Notificando HomePigeon...");
            _updateController.add(true); 
          }
        },
        onDone: () {
          print("⚠️ [EnX] Conexão encerrada pelo proxy. Reiniciando...");
          _reconnect(userId);
        },
        onError: (error) {
          print("❌ [EnX] Erro de Socket no Replit: $error");
          _reconnect(userId);
        },
        cancelOnError: true,
      );
    } catch (e) {
      print("🔌 [EnX] Falha ao conectar no Host público: $e");
      _reconnect(userId);
    }
  }

  void _reconnect(String userId) {
    if (_isManuallyClosed) return;
    _socket?.destroy();
    // Delay de segurança para evitar tédio do processador. [cite: 2025-10-27]
    Future.delayed(const Duration(seconds: 5), () => startListening(userId));
  }

  void stop() {
    _isManuallyClosed = true;
    _socket?.destroy();
    _socket = null;
  }
}
