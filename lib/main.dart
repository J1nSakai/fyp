import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:saysketch_v2/views/intro_view.dart';

void main() {
  Provider.debugCheckInvalidValueType = null;
  runApp(const MyApp());
  SemanticsBinding.instance.ensureSemantics();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  void toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Provider<VoidCallback>.value(
      value: toggleTheme,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        debugShowMaterialGrid: false,
        title: 'V-Architect',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2D3250),
            secondary: const Color(0xFF7077A1),
            tertiary: const Color(0xFFF6B17A),
            surface: const Color(0xFFF7F7F9),
          ),
          useMaterial3: true,
          fontFamily: GoogleFonts.outfit().fontFamily,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Color(0xFF2D3250),
          ),
          iconTheme: const IconThemeData(
            color: Color(0xFF7077A1),
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            brightness: Brightness.dark,
            seedColor: const Color(0xFF2D3250),
            secondary: const Color(0xFF9BA3D4),
            tertiary: const Color(0xFFF6B17A),
            surface: const Color(0xFF1A1B26),
          ),
          useMaterial3: true,
          fontFamily: GoogleFonts.outfit().fontFamily,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Color(0xFF1A1B26),
          ),
          iconTheme: const IconThemeData(
            color: Color(0xFF9BA3D4),
          ),
        ),
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: const IntroView(),
      ),
    );
  }
}
