import 'package:flutter/material.dart';
import '../style.dart';
import '../database/pigeon_database.dart';

class ProfileDweller extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // REAVALIAÇÃO COGNITIVA: Captura o ID passado pelo ChatView [cite: 2025-10-27]
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
            // Avatar Centralizado
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
                  Container(
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Color(0xFF25D366), shape: BoxShape.circle),
                    child: const Icon(Icons.verified, color: Colors.black, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Habitante $peerId",
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Protocolo Pigeon Ativo",
              style: TextStyle(color: Color(0xFF25D366), fontSize: 14, letterSpacing: 1.2),
            ),

            const SizedBox(height: 40),

            // Seção de Informações (Ponderação Ética sobre Dados) [cite: 2025-10-27]
            _buildInfoTile(Icons.fingerprint, "ID de Cidadão", peerId),
            _buildInfoTile(Icons.security, "Criptografia", "Ponto-a-Ponto (Janeway)"),
            _buildInfoTile(Icons.location_on, "Localização", "Setor EnX OS"),

            const SizedBox(height: 30),

            // Botão de Ação: Limpar Conversa (Livre-arbítrio) [cite: 2025-10-27]
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
                label: const Text("LIMPAR MEMÓRIA-SEGMENTADA"),
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
        content: const Text("Isso apagará todas as mensagens locais com este habitante. Esta ação é irreversível.", 
          style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          TextButton(
            onPressed: () async {
              // TRIUNFO: Usa o método que criamos na DB para limpar [cite: 2025-10-27]
              // Note: Você precisará passar o seu dweller_id aqui se quiser ser específico
              // Por enquanto, deletamos do peer_id global na tabela
              await PigeonDatabase.instance.clearChat("global", peerId); 
              Navigator.pop(context);
              Navigator.pop(context); // Volta para a Home
            }, 
            child: const Text("APAGAR", style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );
  }
}
