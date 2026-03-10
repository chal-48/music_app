import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🌟 Import เพิ่มเติม

import 'screens/music_provider.dart';
import 'screens/profile_screen.dart'; 
import 'screens/auth_screen.dart';
import 'screens/main_wrapper.dart';
import 'screens/onboarding_screen.dart'; // 🌟 อย่าลืม import หน้า Onboarding ของคุณ (ตั้งชื่อไฟล์ตามที่คุณมีได้เลย)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, 
  ); 

  // 🌟 เช็คว่าเปิดแอปครั้งแรกหรือไม่
  final prefs = await SharedPreferences.getInstance();
  final showOnboarding = prefs.getBool('showOnboarding') ?? true; // ถ้าไม่มีค่าแปลว่าเปิดครั้งแรก (true)

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()), 
        ChangeNotifierProvider(create: (_) => MusicProvider()),    
      ],
      // 🌟 ส่งค่าไปให้ MyApp
      child: MyApp(showOnboarding: showOnboarding),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool showOnboarding; // 🌟 รับค่ามาจาก main()
  const MyApp({super.key, required this.showOnboarding});

  // 🌟 ฟังก์ชันตัดสินใจว่าจะไปหน้าไหน
  Widget _getInitialScreen() {
    if (showOnboarding) {
      return const OnboardingScreen(); // 1. ถ้าเพิ่งโหลดแอปครั้งแรก ไปหน้า Onboarding
    } else if (FirebaseAuth.instance.currentUser == null) {
      return const AuthScreen(); // 2. ถ้าดู Onboarding แล้ว แต่ยังไม่ล็อกอิน ไปหน้า Auth
    } else {
      return const MainWrapper(); // 3. ถ้าล็อกอินแล้ว ไปหน้า Home
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark, 
        scaffoldBackgroundColor: Colors.black,
      ),
      home: _getInitialScreen(), // 🌟 เรียกใช้ฟังก์ชันเลือกหน้า
    );
  }
}