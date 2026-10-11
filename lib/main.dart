import 'package:flutter/material.dart';
import 'package:linkvault_app/screens/welcome.dart';
import 'package:linkvault_app/services/api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  ApiService.testConnection();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: WelcomScreen());
  }
}
