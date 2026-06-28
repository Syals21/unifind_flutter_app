import 'package:flutter/material.dart';
import 'views/splash_screen.dart';

void main() {
  runApp(const UniFindApp());
}

class UniFindApp extends StatelessWidget {
  const UniFindApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF155EEF);

    return MaterialApp(
      title: 'UniFind',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        scaffoldBackgroundColor: const Color.fromARGB(255, 234, 244, 255),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 11, 59, 141),
          foregroundColor: Color(0xFFF1F5FF),
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFFF5F8FF),
          elevation: 1,
          margin: EdgeInsets.zero,
        ),
        drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFFF1F5FF)),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F8FF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD5DEED)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD5DEED)),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
