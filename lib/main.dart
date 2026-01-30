import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'style.dart'; 

// Importação das páginas originais
import 'pages/splashscreen.dart';
import 'pages/intoSplashscreen.dart'; 
import 'pages/login.dart';
import 'pages/login_2.dart';
import 'pages/register_key.dart';
import 'pages/home_pigeon.dart'; 
import 'pages/chat_view.dart';

// INJEÇÃO DAS NOVAS PÁGINAS: Conexão e Identidade [cite: 2025-10-27]
import 'pages/profile_view.dart';      // Seu perfil (Dono da conta)
import 'pages/profile_dweller.dart';   // Perfil do contato (Habitante)
import 'pages/qr_scanner_view.dart';   // Scanner de conexões

// REAVALIAÇÃO COGNITIVA: Trocado para o banco unificado PigeonDatabase
import 'database/pigeon_database.dart'; 

void main() async {
  // Inicialização vital para SharedPreferences e Sqflite
  WidgetsFlutterBinding.ensureInitialized();
  
  // PARIDADE: Inicializa o banco de dados unificado PigeonDatabase
  // Isso traz um sentimento de Confiança e evita que as queries falhem no primeiro boot
  await PigeonDatabase.instance.database;

  final prefs = await SharedPreferences.getInstance();
  final bool isAuthenticated = prefs.getBool('is_authenticated') ?? false;
  final String dwellerId = prefs.getString('dweller_id') ?? "";

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Pigeon EnX',
    theme: EnXStyle.theme, 
    
    // Se estiver autenticado e tiver um ID, vai direto para a Home
    initialRoute: (isAuthenticated && dwellerId.isNotEmpty) ? '/home_pigeon' : '/',
    
    routes: {
      '/': (context) => SplashScreen(),
      '/login': (context) => Login(),
      '/login-2': (context) => Login2(),
      '/register-key': (context) => RegisterKey(),
      '/into_splash': (context) => IntoSplashScreen(), 
      '/home_pigeon': (context) => HomePigeon(),
      '/chat': (context) => ChatView(),
      
      // NOVAS ROTAS INJETADAS PARA O ENX OS [cite: 2025-10-27]
      '/profile_view': (context) => ProfileView(),        // Rota do seu perfil
      '/profile_dweller': (context) => ProfileDweller(),  // Rota do perfil de quem você conversa
      '/qr_scanner': (context) => QrScannerView(),        // Rota do scanner de QR
    },
  ));
}
