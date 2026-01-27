import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pigeon_model.dart';
// REAVALIAÇÃO COGNITIVA: Agora aponta para o banco unificado [cite: 2025-10-27]
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
          "id_pigeon": idPigeon, 
          "password": password
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // TRIUNFO: Agora salva as mensagens de forma segmentada no PigeonDatabase [cite: 2025-10-27]
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
          // MEMÓRIA-SEGMENTADA: Salvando com paridade no banco unificado usando o toMap do modelo [cite: 2025-10-27]
          // A chave única gerada no toMap evita que o teste #8 suma se o timestamp for igual
          await PigeonDatabase.instance.saveMessage(
            msg.toMap(userId), 
            userId
          ); 
        }

        // Após salvar tudo com segurança no SQLite, limpa a fila no servidor C++
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

  Future<bool> sendMessage({
    required String senderId, 
    required String receiverId, 
    required String content
  }) async {
    try {
      final String time = DateTime.now().toIso8601String();
      final response = await http.post(
        Uri.parse('$baseUrl/send_message'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "sender_id": senderId, 
          "id_pigeon": receiverId, 
          "content": content,
          "timestamp": time,
        }),
      );
      
      if (response.statusCode == 200) {
        // PARIDADE: Cria o objeto local e salva no banco para atualização instantânea da UI [cite: 2025-10-27]
        final myMessage = PigeonMessage(
          senderId: senderId,
          content: content,
          timestamp: time,
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
