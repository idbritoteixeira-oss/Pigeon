import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _readyToContinue = false;

  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _readyToContinue = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/images/logo.png',
                width: 180,
                height: 180,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(30),
            child: Column(
              children: [
                if (!_readyToContinue)
                  CircularProgressIndicator(color: Colors.blueAccent)
                else ...[
                  Text(
                    "Bem-vindo(a) ao Pigeon",
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 15),
                  Text(
                    "Toque em \"Concordar e continuar\" para aceitar os Termos e Política de Privacidade Labs EnX.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                  SizedBox(height: 25),
                  // Botão com Gradiente inspirado no Logo
                  GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF8E2DE2), // Roxo (Início do gradiente)
                            Color(0xFF4A00E0), // Azul Profundo
                            Color(0xFF25D366), // Verde Pigeon (Fim do gradiente)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "CONCORDAR E CONTINUAR",
                          style: TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
