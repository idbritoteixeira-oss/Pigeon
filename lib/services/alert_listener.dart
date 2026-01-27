import 'dart:io';
import 'dart:async';

class AlertListener {
  Socket? _socket;
  // Este StreamController vai avisar a tela que há novidades
  final _updateController = StreamController<bool>.broadcast();
  Stream<bool> get onMessageReceived => _updateController.stream;

  Future<void> startListening(String userId) async {
    try {
      // Conecta no IP local do seu celular
      _socket = await Socket.connect('127.0.0.1', 8080);

      // Envia a requisição para entrar na rota /listen_alerts do C++
      String request = "POST /listen_alerts HTTP/1.1\r\n"
                       "Content-Type: application/json\r\n\r\n"
                       '{"user_id":"$userId"}';
      _socket!.write(request);

      _socket!.listen((data) {
        // Se receber o byte 0x01, dispara o evento para a UI
        if (data.isNotEmpty && data[0] == 0x01) {
          print("🔔 Alerta: Nova mensagem detectada!");
          _updateController.add(true); 
        }
      }, onDone: () => restart(userId)); 
    } catch (e) {
      print("Erro no Listener: $e");
      Future.delayed(Duration(seconds: 5), () => startListening(userId));
    }
  }

  void restart(String userId) => startListening(userId);
}