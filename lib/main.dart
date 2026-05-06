import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const BantayDaanApp());
}

class BantayDaanApp extends StatelessWidget {
  const BantayDaanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bantay Daan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
        fontFamily: 'DMSans',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF4A261),
          surface: Color(0xFF152535),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
