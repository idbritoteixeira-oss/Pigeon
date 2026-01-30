import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/pigeon_service.dart';
import '../style.dart';

class ProfileView extends StatefulWidget {
  @override
  _ProfileViewState createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final PigeonService _pigeonService = PigeonService();
  String _dwellerId = "";
  String _globalName = "Carregando...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final name = await _pigeonService.getGlobalName();
    if (mounted) {
      setState(() {
        _dwellerId = prefs.getString('dweller_id') ?? "0000000000";
        _globalName = name;
        _isLoading = false;
      });
    }
  }

  void _showEditNameDialog(BuildContext context) {
    TextEditingController _nameController = TextEditingController(text: _globalName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1B1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Editar Nome", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _nameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Digite seu nome...",
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EnXStyle.primaryBlue)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF25D366))),
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
            child: const Text("Salvar", style: TextStyle(color: Colors.black)),
            onPressed: () async {
              if (_nameController.text.isNotEmpty) {
                await _pigeonService.setGlobalName(_nameController.text);
                setState(() => _globalName = _nameController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Nome atualizado com sucesso!")),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    await _pigeonService.logout();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F1013),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF25D366))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F1013),
      appBar: AppBar(
        title: const Text("Perfil Pigeon", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 50),
            
            const Center(
              child: Icon(
                Icons.account_circle,
                size: 120,
                color: Colors.white10,
              ),
            ),
            
            const SizedBox(height: 40),
            
            _buildProfileTile(
              label: "Nome",
              value: _globalName,
              icon: Icons.person_outline,
              trailing: const Icon(Icons.edit, color: EnXStyle.primaryBlue, size: 20),
              onTap: () => _showEditNameDialog(context),
            ),
            
            _buildProfileTile(
              label: "Meu ID Pigeon",
              value: _dwellerId,
              icon: Icons.fingerprint,
            ),

            _buildProfileTile(
              label: "Status de Rede",
              value: _pigeonService.getOnlineStatus(),
              icon: Icons.sensors,
              valueColor: const Color(0xFF25D366),
            ),

            const SizedBox(height: 60),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.redAccent, width: 0.5),
                    ),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text("Encerrar Sessão Pigeon", style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _handleLogout(context),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required String label, 
    required String value, 
    required IconData icon, 
    Widget? trailing, 
    VoidCallback? onTap,
    Color? valueColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
      leading: Icon(icon, color: Colors.white24),
      title: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      subtitle: Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontSize: 17, fontWeight: FontWeight.w500)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
