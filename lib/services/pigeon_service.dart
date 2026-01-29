import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pigeon_model.dart';
// REAVALIAÇÃO COGNITIVA: Foco total no banco SQLite unificado [cite: 2025-10-27]
import '../database/pigeon_database.dart'; 

class PigeonService {
  final String baseUrl = "https://8b48ce67-8062-40e3-be2d-c28fd3ae4f01-00-117turwazmdmc.janeway.replit.dev"; 

  Future<bool> activatePigeon({required String idPigeon, required String password}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/activate_pigeon'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id_pigeon": idPigeon, 
          "password": password
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> loginPigeon({required String idPigeon, required String password}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login_pigeon'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id_pub": idPigeon, 
          "password": password
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // TRIUNFO: Busca mensagens e consolida a Memória-segmentada no SQLite [cite: 2025-10-27]
  Future<List<PigeonMessage>> fetchMessages({required String userId}) async {
    if (userId.isEmpty) return [];
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/fetch_messages'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId}), 
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<PigeonMessage> messages = body.map((item) => PigeonMessage.fromJson(item)).toList();

        for (var msg in messages) {
          // Salvando no banco local para garantir a persistência [cite: 2025-10-27]
          await PigeonDatabase.instance.saveMessage(
            msg.toMap(userId), 
            userId
          ); 
        }

        // Alívio: Limpa a fila no servidor após garantir a persistência local [cite: 2025-10-27]
        if (messages.isNotEmpty) {
          await http.post(
            Uri.parse('$baseUrl/confirm_clear'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"user_id": userId}),
          );
        }
        return messages;
      }
      return [];
    } catch (e) {
      print("Erro ao buscar mensagens: $e");
      return [];
    }
  }

  // TRIUNFO: Envio de mensagem com timestamp real formatado [cite: 2025-10-27]
  Future<bool> sendMessage({
    required String senderId, 
    required String receiverId, 
    required String content
  }) async {
    try {
      // REAVALIAÇÃO COGNITIVA: Gerando data e hora real para substituir o "AGORA" [cite: 2025-10-27]
      final DateTime now = DateTime.now();
      final String formattedTime = 
          "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      final response = await http.post(
        Uri.parse('$baseUrl/send_message'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "sender_id": senderId, 
          "id_pigeon": receiverId, 
          "content": content,
          "timestamp": formattedTime, // Envia o horário real para o C++
        }),
      );
      
      if (response.statusCode == 200) {
        // Ponderação ética: Atualiza o banco local imediatamente com o horário real [cite: 2025-10-27]
        final myMessage = PigeonMessage(
          senderId: senderId,
          receiverId: receiverId, // Adicionado para facilitar o mapeamento do peer_id
          content: content,
          timestamp: formattedTime,
          isMe: 1,
        );

        await PigeonDatabase.instance.saveMessage(
          myMessage.toMap(senderId), 
          senderId
        );
        return true;
      }
      return false;
    } catch (e) {
      print("Erro no envio Pigeon: $e");
      return false;
    }
  }
}
