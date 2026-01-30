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
  
  Timer? _chatPollingTimer;
  
  String? _myId;
  String _peerId = ""; 
  bool _isLoading = true;
  // REAVALIAÇÃO COGNITIVA: Estado local para o status do parceiro [cite: 2025-10-27]
  bool _isPeerOnline = false;

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
      
      // Busca status inicial do par
      _checkPeerPresence();

      _startChatPolling();
    } catch (e) {
      print("Erro ao inicializar chat: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // TRIUNFO: Verifica a presença do parceiro no servidor [cite: 2025-10-27]
  Future<void> _checkPeerPresence() async {
    if (_peerId.isEmpty) return;
    bool online = await _pigeonService.checkPeerStatus(_peerId);
    if (mounted) {
      setState(() => _isPeerOnline = online);
    }
  }

  void _startChatPolling() {
    _chatPollingTimer?.cancel();
    _chatPollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (mounted && _myId != null) {
        // Sincroniza mensagens
        int antes = _messages.length;
        await _syncWithServer();
        
        // REGULAÇÃO COMPORTAMENTAL: Aproveita o poll para checar se o amigo sumiu ou voltou [cite: 2025-10-27]
        await _checkPeerPresence();
        
        if (_messages.length > antes) {
          if (await Vibration.hasVibrator() ?? false) Vibration.vibrate(duration: 50);
          try { await _audioPlayer.play(AssetSource('sounds/push.mp3')); } catch (_) {}
        }
      }
    });
  }

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
    _chatPollingTimer?.cancel();
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
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/profile_dweller', arguments: _peerId);
              },
              child: Stack(
                children: [
                  const CircleAvatar(
                    radius: 18, 
                    backgroundColor: Colors.white10, 
                    child: Icon(Icons.person, color: Colors.white70, size: 20)
                  ),
                  // PARIDADE: A bolinha agora reflete se o AMIGO está online via Presence Map [cite: 2025-10-27]
                  if (_isPeerOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366),
                          shape: BoxShape.circle,
                          border: Border.all(color: EnXStyle.primaryBlue, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Habitante $_peerId", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                // ALÍVIO: Texto dinâmico de status [cite: 2025-10-27]
                Text(
                  _isPeerOnline ? "Online agora" : "Visto por último recentemente", 
                  style: TextStyle(fontSize: 10, color: _isPeerOnline ? const Color(0xFF25D366) : Colors.white54)
                ),
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
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isMe 
            ? const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]) 
            : null,
          color: isMe ? null : Colors.white10,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg['content'] ?? "", 
              style: const TextStyle(color: Colors.white, fontSize: 15)
            ),
            const SizedBox(height: 2),
            Text(
              msg['timestamp'] ?? "",
              style: const TextStyle(color: Colors.white24, fontSize: 9),
            )
          ],
        ),
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
              onSubmitted: (_) => _sendMessage(),
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
