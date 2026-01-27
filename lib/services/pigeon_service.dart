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

  // TRIUNFO: Agora salva as mensagens de forma segmentada no PigeonDatabase
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
          // MEMÓRIA-SEGMENTADA: Salvando com paridade no banco unificado
          await PigeonDatabase.instance.saveMessage({
            'remote_id': '${msg.senderId}_${msg.timestamp}_${msg.content.hashCode}', 
            'sender_id': msg.senderId,
            'peer_id': msg.senderId, // Quem mandou é o meu par de chat
            'content': msg.content,
            'timestamp': msg.timestamp,
            'is_me': 0 
          }, userId); // Passamos o dweller_id (userId) separadamente
        }

        // Após salvar tudo no banco local, limpa a fila no C++
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
        // PARIDADE: Salva sua própria mensagem para aparecer no histórico do ChatView
        await PigeonDatabase.instance.saveMessage({
          'remote_id': 'me_${DateTime.now().millisecondsSinceEpoch}', 
          'sender_id': senderId,
          'peer_id': receiverId, // Para quem mandei é o meu par de chat
          'content': content,
          'timestamp': time,
          'is_me': 1 
        }, senderId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
