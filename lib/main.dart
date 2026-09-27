import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'theme/apple_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SpectraFieldApp());
}

class SpectraFieldApp extends StatelessWidget {
  const SpectraFieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spectra | Forensic Analysis',
      debugShowCheckedModeBanner: false,
      theme: AppleTheme.themeData,
      home: const LoginScreen(),
    );
  }
}
