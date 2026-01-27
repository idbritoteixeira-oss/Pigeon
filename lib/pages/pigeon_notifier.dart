import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

class PigeonNotificationService {
  Socket? _socket;
  final String serverIp = "https://8b48ce67-8062-40e3-be2d-c28fd3ae4f01-00-117turwazmdmc.janeway.replit.dev/login_pigeon"; 
  final int port = 8080;
  
  final _controller = StreamController<void>.broadcast();
  Stream<void> get onNewMessage => _controller.stream;

  // Instância do player de áudio
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> connect(String userId) async {
    try {
      _socket = await Socket.connect(serverIp, port);
      
      String request = "POST /listen_alerts HTTP/1.1\r\n" +
                       "Content-Type: application/json\r\n" +
                       "Content-Length: ${jsonEncode({"user_id": userId}).length}\r\n" +
                       "\r\n" +
                       jsonEncode({"user_id": userId});
      
      _socket!.write(request);

      _socket!.listen((List<int> data) async {
        if (data.contains(0x01)) {
          print("🔔 Pigeon: Sinal recebido!");
          
          // --- EFEITOS DE IMERSÃO ---
          _playPigeonSound(); // Toca o som de "pombo" ou "pop"
          _triggerVibration(); // Vibração curta
          
          _controller.add(null); 
        }
      }, onDone: () => _reconnect(userId), onError: (e) => _reconnect(userId));
      
    } catch (e) {
      print("❌ Erro no Notifier: $e");
      Future.delayed(Duration(seconds: 5), () => connect(userId));
    }
  }

  void _playPigeonSound() async {
    // Certifique-se de ter o arquivo em assets/sounds/pigeon_alert.mp3
    await _audioPlayer.play(AssetSource('sounds/pigeon_alert.mp3'));
  }

  void _triggerVibration() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100); // Vibração rápida de 100ms
    }
  }

  void _reconnect(String userId) {
    _socket?.destroy();
    Future.delayed(Duration(seconds: 3), () => connect(userId));
  }
                                                     }
                                                     