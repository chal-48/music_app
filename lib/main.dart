import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/music_provider.dart';
import 'package:music_app/screens/main_wrapper.dart';
import 'firebase_options.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MusicProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Premium Music',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black, // Jet Black
        primaryColor: const Color(0xFFFF5500), // Vivid Orange
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF5500),
          secondary: Color(0xFFFF5500),
          surface: Color(0xFF121212),
        ),
        useMaterial3: true,
        fontFamily: 'Sans-serif', 
      ),
      home: const MainWrapper(),
    );
  }
}