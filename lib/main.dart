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
import 'pages/profile_view.dart';      
import 'pages/profile_dweller.dart';   
import 'database/pigeon_database.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await PigeonDatabase.instance.database;

  final prefs = await SharedPreferences.getInstance();
  final bool isAuthenticated = prefs.getBool('is_authenticated') ?? false;
  final String dwellerId = prefs.getString('dweller_id') ?? "";

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Pigeon EnX',
    theme: EnXStyle.theme, 
    
    initialRoute: (isAuthenticated && dwellerId.isNotEmpty) ? '/home_pigeon' : '/',
    
    routes: {
      '/': (context) => SplashScreen(),
      '/login': (context) => Login(),
      '/login-2': (context) => Login2(),
      '/register-key': (context) => RegisterKey(),
      '/into_splash': (context) => IntoSplashScreen(), 
      '/home_pigeon': (context) => HomePigeon(),
      '/chat': (context) => ChatView(),
      '/profile_view': (context) => ProfileView(),        
      '/profile_dweller': (context) => ProfileDweller(),  
    },

    onUnknownRoute: (settings) => MaterialPageRoute(
      builder: (context) => HomePigeon(),
    ),
  ));
}
