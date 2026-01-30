import 'dart:convert';
import 'dart:async'; 
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pigeon_model.dart';
import '../database/pigeon_database.dart'; 

class PigeonService {
  final String baseUrl = "https://8b48ce67-8062-40e3-be2d-c28fd3ae4f01-00-117turwazmdmc.janeway.replit.dev"; 

  static bool isSystemOnline = false; 

  // --- MÓDULO DE IDENTIDADE & PERFIL ---

  Future<String?> getDwellerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('dweller_id');
  }

  Future<void> setGlobalName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pigeon_name', name);
  }

  Future<String> getGlobalName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('pigeon_name') ?? "Usuário Pigeon";
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('dweller_id');
    await prefs.remove('pigeon_name');
    await prefs.remove('is_authenticated'); 
    isSystemOnline = false; 
  }

  String getOnlineStatus() {
    return isSystemOnline ? "Online agora" : "Desconectado";
  }

  // TRIUNFO: Nova verificação de presença do parceiro (Peer) [cite: 2025-10-27]
  Future<bool> checkPeerStatus(String peerId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/check_peer_status'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"peer_id": peerId}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'online';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // --- MÓDULO DE COMUNICAÇÃO ---

  Future<bool> activatePigeon({required String idPigeon, required String password}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/activate_pigeon'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id_pigeon": idPigeon, "password": password}),
      ).timeout(const Duration(seconds: 8));
      
      isSystemOnline = response.statusCode == 200;
      return isSystemOnline;
    } catch (e) {
      isSystemOnline = false;
      return false;
    }
  }

  Future<bool> loginPigeon({required String idPigeon, required String password}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login_pigeon'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id_pub": idPigeon, "password": password}),
      ).timeout(const Duration(seconds: 8));

      isSystemOnline = response.statusCode == 200;
      return isSystemOnline;
    } catch (e) {
      isSystemOnline = false;
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
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        isSystemOnline = true; 

        List<dynamic> body = jsonDecode(response.body);
        List<PigeonMessage> messages = body.map((item) => PigeonMessage.fromJson(item)).toList();

        for (var msg in messages) {
          await PigeonDatabase.instance.saveMessage(msg.toMap(userId), userId); 
        }

        if (messages.isNotEmpty) {
          await http.post(
            Uri.parse('$baseUrl/confirm_clear'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"user_id": userId}),
          );
        }
        return messages;
      } else {
        isSystemOnline = false;
        return [];
      }
    } on TimeoutException {
      isSystemOnline = false;
      return [];
    } catch (e) {
      isSystemOnline = false;
      return [];
    }
  }

  Future<bool> sendMessage({
    required String senderId, 
    required String receiverId, 
    required String content
  }) async {
    try {
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
          "timestamp": formattedTime, 
        }),
      ).timeout(const Duration(seconds: 8));
      
      if (response.statusCode == 200) {
        isSystemOnline = true; 

        final myMessage = PigeonMessage(
          senderId: senderId,
          receiverId: receiverId, 
          content: content,
          timestamp: formattedTime,
          isMe: 1,
        );

        await PigeonDatabase.instance.saveMessage(myMessage.toMap(senderId), senderId);
        return true;
      }
      isSystemOnline = false;
      return false;
    } catch (e) {
      isSystemOnline = false;
      return false;
    }
  }
}
