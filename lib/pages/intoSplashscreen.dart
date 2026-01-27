import 'package:flutter/material.dart';
import 'dart:async';
import '../services/alert_listener.dart'; // Certifique-se de que o caminho está correto

class IntoSplashScreen extends StatefulWidget {
  @override
  _IntoSplashScreenState createState() => _IntoSplashScreenState();
}

class _IntoSplashScreenState extends State<IntoSplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  // Instância do ouvinte de alertas do PigeonNotifier [cite: 2025-10-27]
  final AlertListener _alertListener = AlertListener(); 

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // Inicia o processo de conexão em background
    _startPigeonSync();
  }

  void _startPigeonSync() {
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        final String? pubId = ModalRoute.of(context)?.settings.arguments as String?;

        // REAVALIAÇÃO COGNITIVA: Ativamos a escuta do socket ANTES de ir para a Home [cite: 2025-10-27]
        if (pubId != null && pubId != "---") {
          _alertListener.startListening(pubId); // Conecta na rota /listen_alerts do C++
          print("📡 [EnX] Escuta de alertas ativada para $pubId");
        }

        Navigator.pushReplacementNamed(
          context, 
          '/home_pigeon', 
          arguments: pubId 
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Recupera o ID vindo do login para exibir na tela (Visual)
    final String pubId = ModalRoute.of(context)!.settings.arguments as String? ?? "---";

    return Scaffold(
      backgroundColor: const Color(0xFF121212), 
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/enx_os_logo.png', width: 140), 
                  const SizedBox(height: 40),
                  FadeTransition(
                    opacity: _animation,
                    child: const Column(
                      children: [
                        Icon(Icons.sync, size: 50, color: Color(0xFF25D366)),
                        SizedBox(height: 15),
                        Text(
                          "SINCRONIZANDO", 
                          style: TextStyle(
                            color: Colors.white70, 
                            fontSize: 10, 
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w300
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Image.asset('assets/images/logo.png', width: 100),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 50),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Dweller: $pubId", 
                    style: const TextStyle(
                      color: Color(0xFF25D366), 
                      fontFamily: 'Monospace',
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Acesso Concedido!", 
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
