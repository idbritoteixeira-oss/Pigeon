import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../style.dart'; // Mantendo a soberania visual

class Login2 extends StatefulWidget {
  @override
  _Login2State createState() => _Login2State();
}

class _Login2State extends State<Login2> {
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;

  Future<void> _finalizarLogin(String idPigeon) async {
    if (_passController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('https://8b48ce67-8062-40e3-be2d-c28fd3ae4f01-00-117turwazmdmc.janeway.replit.dev/login_pigeon');
      
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id_pub": idPigeon, // Enviando o id_pigeon para o servidor
          "password": _passController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['auth'] == 'success') {
          // --- CONSOLIDAÇÃO DA SESSÃO ---
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_authenticated', true); 
          
          // IMPORTANTE: Salvamos o idPigeon (0123456789) como dweller_id
          // Isso evita que o sistema "pule" para a pub_id longa depois.
          await prefs.setString('dweller_id', idPigeon); 
          
          _mostrarMsg("Êxito: Acesso Concedido!", Colors.green);
          
          Navigator.pushReplacementNamed(
            context, 
            '/into_splash', 
            arguments: idPigeon // Passando o ID correto adiante
          );
        }
      } else {
        _mostrarMsg("Erro: Senha Incorreta", Colors.red);
      }
    } catch (e) {
      _mostrarMsg("Erro de Conexão EnX", Colors.orange);
      print("Erro no Login: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarMsg(String texto, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: cor),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Recebendo o ID (ex: 0123456789) vindo da tela anterior
    final String idPigeon = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF075E54)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Digite sua senha", 
          style: TextStyle(color: Color(0xFF075E54), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          children: [
            Text(
              "O Pigeon $idPigeon foi localizado. Insira sua senha para autenticar sua sessão.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 50),
            TextField(
              controller: _passController,
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                hintText: "Senha",
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