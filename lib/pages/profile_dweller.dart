import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../style.dart';
import '../database/pigeon_database.dart';
import '../services/pigeon_service.dart'; // Importado para checar status

class ProfileDweller extends StatefulWidget {
  @override
  State<ProfileDweller> createState() => _ProfileDwellerState();
}

class _ProfileDwellerState extends State<ProfileDweller> {
  final PigeonService _pigeonService = PigeonService();
  bool _isOnline = false;
  bool _checkingStatus = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkStatus();
  }

  // TRIUNFO: Verifica se o habitante está online ao abrir o perfil [cite: 2025-10-27]
  Future<void> _checkStatus() async {
    final String peerId = ModalRoute.of(context)?.settings.arguments as String? ?? "000";
    bool online = await _pigeonService.checkPeerStatus(peerId);
    if (mounted) {
      setState(() {
        _isOnline = online;
        _checkingStatus = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String peerId = ModalRoute.of(context)?.settings.arguments as String? ?? "000";

    return Scaffold(
      backgroundColor: EnXStyle.backgroundBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: EnXStyle.primaryBlue.withOpacity(0.1),
                    child: Text(
                      peerId.isNotEmpty ? peerId[0] : "?",
                      style: const TextStyle(fontSize: 40, color: EnXStyle.primaryBlue, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // REGULAÇÃO COMPORTAMENTAL: Selo muda de cor conforme o status real [cite: 2025-10-27]
                  Container(
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isOnline ? const Color(0xFF25D366) : Colors.grey, 
                      shape: BoxShape.circle
                    ),
                    child: Icon(
                      _isOnline ? Icons.verified : Icons.cloud_off, 
                      color: Colors.black, 
                      size: 20
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Nome: $peerId",
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              _checkingStatus ? "Verificando sinal..." : (_isOnline ? "Online" : " "),
              style: TextStyle(
                color: _isOnline ? const Color(0xFF25D366) : Colors.white38, 
                fontSize: 14, 
                letterSpacing: 1.2
              ),
            ),

            const SizedBox(height: 40),

            _buildInfoTile(Icons.fingerprint, "ID", peerId),
            _buildInfoTile(Icons.security, "Criptografia", "Start-To-End (EnX603)"),
            _buildInfoTile(
              _isOnline ? Icons.location_on : Icons.location_off, 
              "Status de Rede", 
              _isOnline ? "Conectado ao EnX" : "Sinal Perdido"
            ),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withOpacity(0.1),
                  foregroundColor: Colors.redAccent,
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: Colors.redAccent, width: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.delete_sweep),
                label: const Text("LIMPAR CONVERSA"),
                onPressed: () => _confirmClearChat(context, peerId),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: EnXStyle.primaryBlue, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmClearChat(BuildContext context, String peerId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EnXStyle.backgroundBlack,
        title: const Text("Limpar Conversa?", style: TextStyle(color: Colors.white)),
        content: const Text("Isso apagará todas as mensagens locais. Esta ação é irreversível.", 
          style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final String myId = prefs.getString('dweller_id') ?? "global";
              await PigeonDatabase.instance.clearChat(myId, peerId); 
              
              if (context.mounted) {
                Navigator.pop(context); 
                Navigator.pop(context); 
                Navigator.pop(context); 
              }
            }, 
            child: const Text("APAGAR", style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );
  }
}
