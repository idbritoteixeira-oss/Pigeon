import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../style.dart'; 
import '../services/pigeon_service.dart'; 
import '../models/pigeon_model.dart';
import '../database/database_helper.dart';
import '../services/alert_listener.dart'; // Importação do serviço de escuta ativa

class HomePigeon extends StatefulWidget {
  @override
  _HomePigeonState createState() => _HomePigeonState();
}

class _HomePigeonState extends State<HomePigeon> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PigeonService _pigeonService = PigeonService(); 
  final TextEditingController _newChatController = TextEditingController();
  
  // Instância do AlertListener para manter a conexão com o C++
  final AlertListener _alertListener = AlertListener();
  StreamSubscription? _alertSubscription;
  
  String _currentDwellerId = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSessionId(); 
  }

  @override
  void dispose() {
    // IMPORTANTE: Cancela a inscrição para evitar vazamento de memória e conflitos
    _alertSubscription?.cancel();
    _tabController.dispose();
    _newChatController.dispose();
    super.dispose();
  }

  Future<void> _loadSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    final String dwellerId = prefs.getString('dweller_id') ?? "";
    
    setState(() {
      _currentDwellerId = dwellerId;
    });

    // REAVALIAÇÃO COGNITIVA: Se o ID existir, iniciamos a escuta do Notifier [cite: 2025-10-27]
    if (dwellerId.isNotEmpty) {
      _startActiveAlerts(dwellerId);
    }
  }

  void _startActiveAlerts(String userId) {
    // Conecta ao socket de alertas (Porta 8080)
    _alertListener.startListening(userId);
    
    // Escuta o Stream. Se receber 'true', significa que o C++ enviou o byte 0x01
    _alertSubscription = _alertListener.onMessageReceived.listen((hasNewData) {
      if (hasNewData && mounted) {
        print("🔔 [EnX] Sinal de paridade detectado. Atualizando interface...");
        _handleRefresh(); 
      }
    });
  }

  // TRIUNFO: Sincroniza com C++ e busca a lista de conversas ativas [cite: 2025-10-27]
  Future<List<Map<String, dynamic>>> _getCombinedMessages(String userId) async {
    if (userId.isEmpty) return [];
    
    try {
      // Sincroniza novas mensagens (Build #26)
      await _pigeonService.fetchMessages(userId: userId);
    } catch (e) {
      print("Offline ou Erro de conexão: Mantendo dados locais.");
    }

    // PARIDADE: Em vez de buscar mensagens de um ID vazio, buscamos os chats recentes
    return await DatabaseHelper.instance.getRecentChats(userId); 
  }

  Future<void> _handleRefresh() async {
    await _loadSessionId(); 
    // O setState força o FutureBuilder a disparar novamente o _getCombinedMessages
    setState(() {}); 
    return await Future.delayed(const Duration(milliseconds: 500)); 
  }

  void _showNewChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EnXStyle.backgroundBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Adicionar", style: TextStyle(color: Colors.white, fontSize: 18)),
        content: TextField(
          controller: _newChatController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: "ID Pigeon...",
            hintStyle: TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF25D366))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF25D366), width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (_newChatController.text.isNotEmpty) {
                String peerId = _newChatController.text;
                Navigator.pop(context);
                Navigator.pushNamed(context, '/chat', arguments: peerId);
                _newChatController.clear();
              }
            },
            child: const Text("INICIAR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String argId = ModalRoute.of(context)!.settings.arguments as String? ?? "";
    final String activeId = argId.isNotEmpty ? argId : _currentDwellerId;

    return Scaffold(
      backgroundColor: EnXStyle.backgroundBlack, 
      appBar: AppBar(
        backgroundColor: EnXStyle.primaryBlue, 
        automaticallyImplyLeading: false, 
        title: const Text("Pigeon", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          Center(child: Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Text(activeId, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ))
        ],
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF25D366), 
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: "CHATS"),
            Tab(text: "EXPLORE"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RefreshIndicator(
            onRefresh: _handleRefresh,
            color: const Color(0xFF25D366),
            backgroundColor: EnXStyle.primaryBlue,
            child: _buildLiveChatList(activeId), 
          ),
          _buildExploreView(), 
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatDialog,
        backgroundColor: const Color(0xFF25D366),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildLiveChatList(String userId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getCombinedMessages(userId), 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF25D366)));
        } 
        
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return ListView( 
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 100),
              Center(child: Text("Nenhuma mensagem armazenada.", style: TextStyle(color: Colors.white38))),
            ],
          );
        }

        final messages = snapshot.data!;
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(), 
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            // MEMÓRIA-SEGMENTADA: Define quem é o outro na conversa [cite: 2025-10-27]
            final String contactId = msg['peer_id'] ?? msg['sender_id'] ?? "Desconhecido";

            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.white10,
                child: Icon(Icons.person, color: Colors.white70),
              ),
              title: Text(
                "Habitante $contactId", 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)
              ),
              subtitle: Text(
                msg['content'] ?? "", 
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white38, fontSize: 13)
              ),
              trailing: Text(
                msg['timestamp'].toString().contains('T') 
                    ? msg['timestamp'].toString().split('T').first.substring(5) 
                    : "Recente", 
                style: const TextStyle(fontSize: 11, color: Colors.white24)
              ),
              onTap: () {
                Navigator.pushNamed(context, '/chat', arguments: contactId);
              }, 
            );
          },
        );
      },
    );
  }

  Widget _buildExploreView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.explore_outlined, size: 80, color: EnXStyle.primaryBlue),
          SizedBox(height: 16),
          Text("Explore Dwellers", style: TextStyle(color: Colors.white54, fontSize: 16)),
        ],
      ),
    );
  }
}
