import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/pigeon_service.dart';

class ProfilePigeon extends StatefulWidget {
  @override
  _ProfilePigeonState createState() => _ProfilePigeonState();
}

class _ProfilePigeonState extends State<ProfilePigeon> {
  final PigeonService _pigeonService = PigeonService();
  String _dwellerId = "";
  String _globalName = "Carregando...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // REAVALIAÇÃO COGNITIVA: Recupera dados da memória consolidada [cite: 2025-10-27]
  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final name = await _pigeonService.getGlobalName();
    setState(() {
      _dwellerId = prefs.getString('dweller_id') ?? "0000000000";
      _globalName = name;
      _isLoading = false;
    });
  }

  // Ponderação Ética: Função para logout seguro [cite: 2025-10-27]
  void _handleLogout() async {
    await _pigeonService.logout();
    // Navega para login e limpa a pilha (Regulação comportamental) [cite: 2025-10-27]
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFF0F1013), // Tema Dark EnX
      appBar: AppBar(
        title: const Text("Perfil Dweller"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // SISTEMA DE QR (UI Component)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: QrImageView(
                  data: _dwellerId, // Número de telefone (Dweller ID)
                  version: QrVersions.auto,
                  size: 200.0,
                  gapless: false,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.circle,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // INFORMAÇÕES DO USUÁRIO (Paridade com PigeonCore) [cite: 2025-10-27]
            _buildInfoTile("Nome Global", _globalName, Icons.person, isEditable: true),
            _buildInfoTile("Dweller ID", _dwellerId, Icons.phone, isEditable: false),
            _buildInfoTile("Status", _pigeonService.getOnlineStatus(), Icons.circle, color: Colors.green),

            const SizedBox(height: 50),

            // BOTÃO LOGOUT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _handleLogout,
                  child: const Text("LOGOUT (Sair do EnX OS)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon, {bool isEditable = false, Color color = Colors.white}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      subtitle: Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      trailing: isEditable ? const Icon(Icons.edit, color: Colors.blue, size: 20) : null,
      onTap: isEditable ? () {
        // Implementar diálogo para mudar nome global aqui
      } : null,
    );
  }
}
