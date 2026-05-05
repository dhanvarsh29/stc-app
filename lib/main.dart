import 'package:flutter/material.dart';

import 'screens/home_screen.dart';


void main() {
  runApp(const SmartTrafficApp());
}

class SmartTrafficApp extends StatelessWidget {
  const SmartTrafficApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Traffic Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF181D27),
        cardColor: const Color(0xFF232A3A),
        colorScheme: ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.greenAccent,
          background: const Color(0xFF181D27),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF232A3A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          shadowColor: Colors.black54,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            elevation: 6,
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
