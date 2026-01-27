import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../style.dart'; 

class Login2 extends StatefulWidget {
  @override
  _Login2State createState() => _Login2State();
}

class _Login2State extends State<Login2> {
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;

  // PARIDADE: Apontando para o servidor local [cite: 2025-10-27]
  // Use '127.0.0.1' para iOS/Web ou '10.0.2.2' para Emulador Android
  final String serverUrl = "http://127.0.0.1:8080"; 

  Future<void> _finalizarLogin(String idPigeon) async {
    if (_passController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('$serverUrl/login_pigeon');
      
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id_pigeon": idPigeon, 
          "password": _passController.text,
        }),
      ).timeout(const Duration(seconds: 5)); // Evita que o app trave se o server cair

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['auth'] == 'success') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_authenticated', true); 
          await prefs.setString('dweller_id', idPigeon); 
          
          _mostrarMsg("Êxito: Acesso Concedido!", Colors.green);
          
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/into_splash', arguments: idPigeon);
        } else {
          _mostrarMsg("Erro: Senha Incorreta", Colors.red);
        }
      } else {
        _mostrarMsg("Servidor Offline ou Erro ${response.statusCode}", Colors.red);
      }
    } catch (e) {
      _mostrarMsg("Não foi possível conectar ao 127.0.0.1", Colors.orange);
      print("Erro de conexão local: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarMsg(String texto, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: cor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String idPigeon = ModalRoute.of(context)!.settings.arguments as String? ?? "";

    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF075E54)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Autenticação Local", 
          style: TextStyle(color: Color(0xFF075E54), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          children: [
            Text(
              "Conectando ao servidor local em $serverUrl\nIdentidade: $idPigeon",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 50),
            TextField(
              controller: _passController,
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                hintText: "Senha do Habitante",
                hintStyle: TextStyle(color: Colors.black38),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF075E54), width: 1.5)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF25D366), width: 2.0)),
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: _isLoading 
                ? const CircularProgressIndicator(color: Color(0xFF25D366))
                : FloatingActionButton(
                    onPressed: () => _finalizarLogin(idPigeon),
                    backgroundColor: const Color(0xFF25D366),
                    child: const Icon(Icons.check, color: Colors.white),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
