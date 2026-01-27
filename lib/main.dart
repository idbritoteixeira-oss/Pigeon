import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'style.dart'; 
import 'pages/splashscreen.dart';
import 'pages/intoSplashscreen.dart'; 
import 'pages/login.dart';
import 'pages/login_2.dart';
import 'pages/register_key.dart';
import 'pages/home_pigeon.dart'; 
import 'pages/chat_view.dart';
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
    },
  ));
}
