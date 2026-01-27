import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pigeon_model.dart';
import '../database/database_helper.dart';

class PigeonService {
  final String baseUrl = "https://8b48ce67-8062-40e3-be2d-c28fd3ae4f01-00-117turwazmdmc.janeway.replit.dev"; 

  // --- ATIVAÇÃO CORRIGIDA PARA PARIDADE ---
  Future<bool> activatePigeon({required String idPigeon, required String password}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/activate_pigeon'),
        headers: {"Content-Type": "application/json"},
        // PARIDADE: Enviando 'id_pigeon' para bater com o C++
        body: jsonEncode({
          "id_pigeon": idPigeon, 
          "password": password
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Ativação concluída!");
        return true;
      } else {
        print("⚠️ Erro na ativação: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ Erro de rede: $e");
      return false;
    }
  }

  // --- LOGIN CORRIGIDO ---
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
          await DatabaseHelper.instance.insertMessage({
            'remote_id': '${msg.senderId}_${msg.timestamp}', 
            'id_pigeon': userId,   
            'peer_id': msg.senderId, 
            'sender_id': msg.senderId,
            'content': msg.content,
            'timestamp': msg.timestamp,
            'is_me': 0 
          });
        }

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
        await DatabaseHelper.instance.insertMessage({
          'remote_id': 'me_$time', 
          'id_pigeon': senderId,   
          'peer_id': receiverId,   
          'sender_id': senderId,
          'content': content,
          'timestamp': time,
          'is_me': 1 
        });
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
