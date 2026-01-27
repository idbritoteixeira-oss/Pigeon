import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../style.dart'; // Importando a soberania visual

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _idController = TextEditingController();
  bool _isLoading = false;

  // REAVALIAÇÃO COGNITIVA: Host local injetado para paridade com o C++ [cite: 2025-10-27]
  final String serverUrl = "https://8b48ce67-8062-40e3-be2d-c28fd3ae4f01-00-117turwazmdmc.janeway.replit.dev/";

  Future<void> _verificarStatus() async {
    if (_idController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      // PARIDADE: Apontando para o endpoint check_status local
      final url = Uri.parse('$serverUrl/check_status');
      
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id_pigeon": _idController.text}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Se stat for true, o Habitante existe (vai para senha)
        // Se for false, é novo (vai para registro)
        if (data['stat'] == true) {
          Navigator.pushNamed(context, '/login-2', arguments: _idController.text);
        } else {
          Navigator.pushNamed(context, '/register-key', arguments: _idController.text);
        }
      } else {
        _mostrarMsg("Erro local EnX: ${response.statusCode}", Colors.red);
      }
    } catch (e) {
      _mostrarMsg("Não foi possível conectar ao Servidor C++ (127.0.0.1)", Colors.orange);
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
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Verifique seu número", 
          style: TextStyle(color: Color(0xFF075E54), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          children: [
            const Text(
              "O Pigeon verificará sua autenticidade no ambiente local. Certifique-se de que o servidor C++ está ouvindo na porta 8080.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 50),
            TextField(
              controller: _idController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                hintText: "Número Pigeon (10 dígitos)",
                hintStyle: TextStyle(color: Colors.black38),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF075E54), width: 1.5)),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF25D366), width: 2.0)),
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: _isLoading 
                ? const CircularProgressIndicator(color: Color(0xFF25D366))
                : FloatingActionButton(
                    onPressed: _verificarStatus,
                    backgroundColor: const Color(0xFF25D366),
                    child: const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
