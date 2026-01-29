import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../style.dart'; 
import '../services/pigeon_service.dart'; 
import '../models/pigeon_model.dart';
import '../database/pigeon_database.dart'; 

class HomePigeon extends StatefulWidget {
  @override
  _HomePigeonState createState() => _HomePigeonState();
}

class _HomePigeonState extends State<HomePigeon> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PigeonService _pigeonService = PigeonService(); 
  final TextEditingController _newChatController = TextEditingController();
  
  // ALÍVIO: Timer para busca automática (Polling) em vez de Sockets instáveis [cite: 2025-10-27]
  Timer? _pollingTimer;
  String _currentDwellerId = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSessionId(); 
  }

  @override
  void dispose() {
    // REAVALIAÇÃO COGNITIVA: Cancelar o timer é vital para evitar vazamento de memória [cite: 2025-10-27]
    _pollingTimer?.cancel();
    _tabController.dispose();
    _newChatController.dispose();
    super.dispose();
  }

  Future<void> _loadSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    final String dwellerId = prefs.getString('dweller_id') ?? "";
    
    if (mounted) {
      setState(() {
        _currentDwellerId = dwellerId;
      });
    }

    if (dwellerId.isNotEmpty) {
      _startPollingMessages(dwellerId);
    }
  }

  // TRIUNFO: A cada 10 segundos, o App pergunta ao C++ se há novidades [cite: 2025-10-27]
  void _startPollingMessages(String userId) {
    _pollingTimer?.cancel(); // Limpa timers antigos por segurança
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (mounted) {
        print("🕊️ [Pigeon] Verificando novas mensagens via Polling...");
        await _pigeonService.fetchMessages(userId: userId);
        // Atualiza a UI se o usuário estiver na aba de CHATS
        if (_tabController.index == 0) {
          setState(() {}); 
        }
      }
    });
  }

  Future<List<Map<String, dynamic>>> _getCombinedMessages(String userId) async {
    if (userId.isEmpty) return [];
    
    // O fetchMessages agora é gerenciado pelo Timer, mas o Refresh manual continua disponível
    return await PigeonDatabase.instance.getRecentChats(userId); 
  }

  Future<void> _handleRefresh() async {
    if (_currentDwellerId.isNotEmpty) {
      await _pigeonService.fetchMessages(userId: _currentDwellerId);
    }
    if (mounted) {
      setState(() {}); 
    }
  }

  // ... (Funções _showNewChatDialog, build e UI permanecem as mesmas, 
  // apenas removendo referências ao AlertListener)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EnXStyle.backgroundBlack, 
      appBar: AppBar(
        backgroundColor: EnXStyle.primaryBlue, 
        automaticallyImplyLeading: false, 
        title: const Text("Pigeon", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          Center(child: Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Text(_currentDwellerId, style: const TextStyle(color: Colors.white38, fontSize: 12)),
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
            child: _buildLiveChatList(_currentDwellerId), 
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
              Center(child: Text("Nenhuma conversa ativa.", style: TextStyle(color: Colors.white38))),
            ],
          );
        }

        final messages = snapshot.data!;
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(), 
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            final String contactId = msg['peer_id'] ?? "Desconhecido";

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
              trailing: const Icon(Icons.chevron_right, color: Colors.white12, size: 16),
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
}
