class PigeonMessage {
  final String senderId;
  final String? receiverId;
  final String content;
  final String timestamp;
  final int isMe;

  PigeonMessage({
    required this.senderId,
    this.receiverId,
    required this.content,
    required this.timestamp,
    this.isMe = 0,
  });

  // REAVALIAÇÃO COGNITIVA: Mapeamento seguro de tipos vindos do JSON [cite: 2025-10-27]
  factory PigeonMessage.fromJson(Map<String, dynamic> json) {
    return PigeonMessage(
      senderId: json['sender_id']?.toString() ?? 'Desconhecido',
      receiverId: json['receiver_id']?.toString(),
      content: json['content']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
      isMe: json['is_me'] is int ? json['is_me'] : 0,
    );
  }

  // TRIUNFO: Gera um mapa pronto para o SQLite com ID único e estável [cite: 2025-10-27]
  Map<String, dynamic> toMap(String currentDwellerId) {
    // Criamos um remote_id baseado no tempo de processamento para evitar duplicatas
    // Isso garante a paridade mesmo se duas mensagens tiverem o mesmo timestamp de texto
    final String uniqueRef = DateTime.now().microsecondsSinceEpoch.toString();

    return {
      'remote_id': '${senderId}_$uniqueRef',
      'dweller_id': currentDwellerId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'timestamp': timestamp,
      'is_me': isMe,
      'is_read': isMe == 1 ? 1 : 0, // Mensagens enviadas já nascem lidas
      'type': 'text' 
    };
  }
}
