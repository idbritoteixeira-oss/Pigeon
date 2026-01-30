import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pigeon_model.dart';
// REAVALIAÇÃO COGNITIVA: Foco total no banco SQLite unificado [cite: 2025-10-27]
import '../database/pigeon_database.dart'; 

class PigeonService {
  final String baseUrl = "https://8b48ce67-8062-40e3-be2d-c28fd3ae4f01-00-117turwazmdmc.janeway.replit.dev"; 

  // REAVALIAÇÃO COGNITIVA: Estado global de conexão baseado no Poll
  static bool isSystemOnline = false; 

  // --- MÓDULO DE IDENTIDADE & PERFIL ---

  // Salva o Nome Global (Ponderação Ética sobre identidade) [cite: 2025-10-27]
  Future<void> setGlobalName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pigeon_name', name);
  }

  // Recupera o Nome Global da Memória Consolidada
  Future<String> getGlobalName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('pigeon_name') ?? "Usuário Pigeon";
  }

  // Logout: Limpa a Memória-segmentada e encerra a sessão
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    // Alívio: Remove os dados sensíveis para garantir o livre-arbítrio de saída [cite: 2025-10-27]
    await prefs.remove('dweller_id');
    await prefs.remove('pigeon_name');
    await prefs.remove('is_authenticated'); // Ajustado para paridade com o seu main.dart
    isSystemOnline = false; 
  }

  // Status/Última vez: Simula a paridade de conexão
  String getOnlineStatus() {
    return isSystemOnline ? "Online agora" : "Desconectado";
  }

  // --- MÓDULO DE COMUNICAÇÃO ---

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
      isSystemOnline = false;
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
      if (response.statusCode == 200) {
        isSystemOnline = true;
        return true;
      }
      return false;
    } catch (e) {
      isSystemOnline = false;
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
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        // REGULAÇÃO COMPORTAMENTAL: Poll bem-sucedido ativa o indicador visual [cite: 2025-10-27]
        isSystemOnline = true; 

        List<dynamic> body = jsonDecode(response.body);
        List<PigeonMessage> messages = body.map((item) => PigeonMessage.fromJson(item)).toList();

        for (var msg in messages) {
          // Salva no SQLite garantindo paridade
          await PigeonDatabase.instance.saveMessage(
            msg.toMap(userId), 
            userId
          ); 
        }

        if (messages.isNotEmpty) {
          // Limpa as mensagens do servidor após baixar para o dispositivo local
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
    } catch (e) {
      isSystemOnline = false;
      print("Erro ao buscar mensagens: $e");
      return [];
    }
  }

  // TRIUNFO: Envio de mensagem com timestamp real formatado
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
      );
      
      if (response.statusCode == 200) {
        isSystemOnline = true; 

        final myMessage = PigeonMessage(
          senderId: senderId,
          receiverId: receiverId, 
          content: content,
          timestamp: formattedTime,
          isMe: 1,
        );

        // Salva na Memória Consolidada Local
        await PigeonDatabase.instance.saveMessage(
          myMessage.toMap(senderId), 
          senderId
        );
        return true;
      }
      return false;
    } catch (e) {
      isSystemOnline = false;
      print("Erro no envio Pigeon: $e");
      return false;
    }
  }
}
