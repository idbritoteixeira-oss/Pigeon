import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart'; 
import 'dart:async';
import '../style.dart';
import '../services/pigeon_service.dart';
import '../database/database_helper.dart';
import 'pigeon_notifier.dart'; 

class ChatView extends StatefulWidget {
  @override
  _ChatViewState createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _audioPlayer = AudioPlayer(); 
  
  List<Map<String, dynamic>> _messages = []; 
  final PigeonService _pigeonService = PigeonService();
  final PigeonNotificationService _notifier = PigeonNotificationService();
  StreamSubscription? _notificationSubscription;
  
  String? _myId;
  String _peerId = ""; 
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final String args = ModalRoute.of(context)?.settings.arguments as String? ?? "";
    _peerId = args.replaceAll(RegExp(r'[^0-9]'), ''); 
    _initChat();
  }

  Future<void> _initChat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _myId = prefs.getString('dweller_id') ?? "Desconhecido";
      
      if (_myId != null && _myId != "Desconhecido") {
        _notifier.connect(_myId!);
        
        // REAVALIAÇÃO COGNITIVA: Escuta ativa do sinal 0x01 vindo do C+
        _notificationSubscription = _notifier.onNewMessage.listen((_) async {
          // 1. Feedback tátil
          if (await Vibration.hasVibrator() ?? false) {
            Vibration.vibrate(duration: 50); 
          }

          // 2. Feedback Sonoro: Recebimento (Paridade com Notifier)
          try {
            await _audioPlayer.play(AssetSource('sounds/push.mp3'));
          } catch (e) {
            print("Erro som push: $e");
          }
          
          // 3. Sincronização e atualização da UI
          await _syncWithServer(); 
          _scrollToBottom();
        });
      }
      
      await _loadLocalHistory();
      await _syncWithServer(); 
      _scrollToBottom();
    } catch (e) {
      print("Erro ao inicializar chat: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _syncWithServer() async {
    if (_myId == null || _myId == "Desconhecido") return;
    try {
      await _pigeonService.fetchMessages(userId: _myId!); 
      await _loadLocalHistory();
    } catch (e) {
      print("Erro na sincronização: $e");
    }
  }

  Future<void> _loadLocalHistory() async {
    if (_myId == null || _peerId.isEmpty) return;
    final history = await DatabaseHelper.instance.getChatMessages(_myId!, _peerId); 

    if (mounted) {
      setState(() {
        _messages = List.from(history);
      });
    }
  }

  // TRIUNFO: Som de envio e atualização otimista
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _myId == null || _peerId.isEmpty) {
      return;
    }

    final String text = _messageController.text;
    final String time = DateTime.now().toIso8601String();

    // 1. Feedback Sonoro: Envio (send.mp3)
    try {
      await _audioPlayer.play(AssetSource('sounds/send.mp3'));
    } catch (e) {
      print("Erro ao tocar send.mp3: $e");
    }

    // 2. Atualização Otimista da Interface
    setState(() {
      _messages.add({
        'content': text,
        'is_me': 1,
        'timestamp': time,
      });
    });

    _messageController.clear();
    _scrollToBottom();

    // 3. Envio Real para o Servidor
    try {
      await _pigeonService.sendMessage(
        senderId: _myId!, 
        receiverId: _peerId, 
        content: text
      );
    } catch (e) {
      print("Erro no envio Pigeon: $e");
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _scrollController.dispose();
    _audioPlayer.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EnXStyle.backgroundBlack,
      appBar: AppBar(
        backgroundColor: EnXStyle.primaryBlue,
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18, 
              backgroundColor: Colors.white10, 
              child: Icon(Icons.person, color: Colors.white70, size: 20)
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Habitante $_peerId", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("Seu ID: $_myId", style: const TextStyle(fontSize: 10, color: Colors.white54)),
              ],
            ),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF25D366)))
        : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
                ),
              ),
              _buildMessageInput(),
            ],
          ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    bool isMe = msg['is_me'] == 1;
    String displayContent = msg['content'] ?? ""; 

    String timeLabel = msg['timestamp'].toString().contains('T') 
        ? msg['timestamp'].toString().split('T').last.substring(0, 5)
        : msg['timestamp'].toString().length >= 5 
            ? msg['timestamp'].toString().substring(0, 5) 
            : msg['timestamp'].toString();

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: isMe 
                ? const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]) 
                : null,
              color: isMe ? null : Colors.white10,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 18),
              ),
            ),
            child: Text(displayContent, style: const TextStyle(color: Colors.white, fontSize: 15)),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 4.0, right: 4.0),
            child: Text(timeLabel, style: const TextStyle(color: Colors.white24, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      color: Colors.black,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: (_) => _sendMessage(),
                  decoration: const InputDecoration(
                    hintText: "Mensagem Pigeon...",
                    hintStyle: TextStyle(color: Colors.white24),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: const Color(0xFF25D366),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
