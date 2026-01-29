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

  factory PigeonMessage.fromJson(Map<String, dynamic> json) {
    return PigeonMessage(
      senderId: json['sender_id']?.toString() ?? 'Desconhecido',
      receiverId: json['receiver_id']?.toString(),
      content: json['content']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? 'Agora',
      isMe: json['is_me'] ?? 0,
    );
  }

  Map<String, dynamic> toMap(String currentDwellerId) {
    return {
      'remote_id': '${senderId}_${timestamp}_${content.hashCode}',
      'dweller_id': currentDwellerId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'timestamp': timestamp,
      'is_me': isMe,
    };
  }
}
