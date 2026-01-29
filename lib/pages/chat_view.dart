import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart'; 
import 'dart:async';
import '../style.dart';
import '../services/pigeon_service.dart';
import '../database/pigeon_database.dart'; 

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
  
  // REAVALIAÇÃO COGNITIVA: Timer de Polling substitui o AlertListener [cite: 2025-10-27]
  Timer? _chatPollingTimer;
  
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
      
      await _loadLocalHistory();
      await _syncWithServer(); 

      // TRIUNFO: Ativa o Polling específico para a tela de chat (a cada 5 segundos)
      _startChatPolling();
    } catch (e) {
      print("Erro ao inicializar chat: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startChatPolling() {
    _chatPollingTimer?.cancel();
    _chatPollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (mounted && _myId != null) {
        // Verifica se há novas mensagens no servidor
        int antes = _messages.length;
        await _syncWithServer();
        
        // Se chegaram mensagens novas, dar feedback visual/sonoro
        if (_messages.length > antes) {
          if (await Vibration.hasVibrator() ?? false) Vibration.vibrate(duration: 50);
          try { await _audioPlayer.play(AssetSource('sounds/push.mp3')); } catch (_) {}
        }
      }
    });
  }

  // Restante da lógica de scroll e sincronização...
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    final history = await PigeonDatabase.instance.getChatHistory(_myId!, _peerId); 

    if (mounted) {
      setState(() {
        _messages = List<Map<String, dynamic>>.from(history);
      });
      _scrollToBottom();
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _myId == null || _peerId.isEmpty) return;

    final String text = _messageController.text;
    try { await _audioPlayer.play(AssetSource('sounds/send.mp3')); } catch (_) {}
    _messageController.clear();

    try {
      await _pigeonService.sendMessage(
        senderId: _myId!, 
        receiverId: _peerId, 
        content: text
      );
      await _syncWithServer();
    } catch (e) {
      print("Erro no envio: $e");
    }
  }

  @override
  void dispose() {
    // IMPORTANTE: Cancelar o timer para não gastar dados em background [cite: 2025-10-27]
    _chatPollingTimer?.cancel();
    _scrollController.dispose();
    _audioPlayer.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // O build permanece idêntico ao seu, garantindo a estética EnX
    return Scaffold(
      backgroundColor: EnXStyle.backgroundBlack,
      appBar: AppBar(
        backgroundColor: EnXStyle.primaryBlue,
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18, backgroundColor: Colors.white10, 
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
    bool isMe = msg['sender_id'] == _myId || msg['is_me'] == 1;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const Duration(vertical: 4) != null ? const EdgeInsets.symmetric(vertical: 4) : EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isMe ? const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]) : null,
          color: isMe ? null : Colors.white10,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(msg['content'] ?? "", style: const TextStyle(color: Colors.white, fontSize: 15)),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      color: Colors.black,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Mensagem Pigeon...",
                hintStyle: TextStyle(color: Colors.white24),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF25D366)),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
