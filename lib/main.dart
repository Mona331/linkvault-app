import 'package:flutter/material.dart';
import 'package:linkvault_app/screens/home.dart';
import 'package:linkvault_app/screens/welcome.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
     debugShowCheckedModeBanner: false,
      home:  WelcomScreen(),
    );
  }
}

