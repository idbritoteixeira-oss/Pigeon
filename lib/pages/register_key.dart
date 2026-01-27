import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../style.dart'; // Mantendo a soberania visual

class RegisterKey extends StatefulWidget {
  @override
  _RegisterKeyState createState() => _RegisterKeyState();
}

class _RegisterKeyState extends State<RegisterKey> {
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  bool _isLoading = false;

  Future<void> _registrar(String idPigeon) async {
    if (_passController.text.isEmpty) {
      _mostrarMsg("Defina uma senha!", Colors.red);
      return;
    }
    
    if (_passController.text != _confirmPassController.text) {
      _mostrarMsg("Senhas diferentes!", Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('https://8b48ce67-8062-40e3-be2d-c28fd3ae4f01-00-117turwazmdmc.janeway.replit.dev/activate_pigeon');
      
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        // AQUI ESTAVA O ERRO: Mudamos de 'id_pub' para 'id_pigeon' 
        // para o C++ encontrar o arquivo em authtmp.
        body: jsonEncode({
          "id_pigeon": idPigeon,
          "password": _passController.text,
        }),
      );

      if (response.statusCode == 200) {
        _mostrarMsg("Chave registrada com êxito!", Colors.green);
        // Ponderação ética: Usamos Replacement para o usuário não voltar ao registro
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        // Agora o servidor devolve 404 se não achar o ID na pasta temporária
        final errorMsg = jsonDecode(response.body)['res'] ?? "Erro desconhecido";
        _mostrarMsg("Não ativado: $errorMsg", Colors.red);
      }
    } catch (e) {
      _mostrarMsg("Erro ao registrar no Dwellers EnX", Colors.orange);
      print("Erro no RegisterKey: $e");
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
    final Object? args = ModalRoute.of(context)!.settings.arguments;
    final String idPigeon = args != null ? args as String : "Erro: ID Nulo";

    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF075E54)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Registrar Chave", 
          style: TextStyle(color: Color(0xFF075E54), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: args == null 
        ? const Center(child: Text("Erro de Navegação", style: TextStyle(color: Colors.black))) 
        : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          children: [
            Text(
              "O ID $idPigeon é novo no Dwellers EnX. Crie uma senha segura para sua chave EnX1.",
              textAlign: TextAlign.center, 
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _passController,
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                hintText: "Nova Senha EnX1",
                hintStyle: TextStyle(color: Colors.black38),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF075E54))),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _confirmPassController,
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                hintText: "Confirme a Senha",
                hintStyle: TextStyle(color: Colors.black38),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF075E54))),
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton(
                onPressed: () => _registrar(idPigeon),
                backgroundColor: const Color(0xFF25D366),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Icon(Icons.cloud_upload, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
