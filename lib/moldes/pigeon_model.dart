class PigeonMessage {
  final String senderId;
  final String content;
  final String timestamp;
  final int isMe; // 1 para sim, 0 para não

  PigeonMessage({
    required this.senderId, 
    required this.content, 
    required this.timestamp,
    this.isMe = 0, // Por padrão, mensagens recebidas
  });

  // Transforma o JSON do servidor C++ em objeto Dart
  factory PigeonMessage.fromJson(Map<String, dynamic> json) {
    return PigeonMessage(
      senderId: json['sender_id']?.toString() ?? 'Desconhecido',
      content: json['content']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
      isMe: json['is_me'] ?? 0,
    );
  }

  // Converte para o formato que o Sqflite entende (Map)
  Map<String, dynamic> toMap(String currentDwellerId) {
    return {
      'remote_id': '${senderId}_$timestamp', // Chave única para evitar duplicatas
      'id_pigeon': currentDwellerId,          // O seu ID de 10 dígitos
      'sender_id': senderId,
      'content': content,
      'timestamp': timestamp,
      'is_me': isMe,
    };
  }
}
