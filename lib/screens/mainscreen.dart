import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import 'package:linkvault_app/screens/home.dart';
import 'package:linkvault_app/screens/favorite.dart';
import 'package:linkvault_app/screens/add.dart';
import 'package:linkvault_app/screens/profile.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  final List<Widget> pages = [
    Home(),
    FavoriteScreen(),
    AddLink(),
    ProfileScreen(),
  ];

  final List<Widget> items = [
    const Icon(Icons.home, size: 28, color: Colors.white),
   const Icon(Icons.favorite, size: 28, color: Colors.white),
    const Icon(Icons.add, size: 28, color: Colors.white),
    const Icon(Icons.person, size: 28, color: Colors.white),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: currentIndex, children: pages),

      bottomNavigationBar: CurvedNavigationBar(
        index: currentIndex,
        height: 60,
        backgroundColor: Colors.transparent,
        color: const Color.fromARGB(175, 5, 99, 142),
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        items: items,
        onTap: (selectedIndex) {
          setState(() {
            currentIndex = selectedIndex;
          });
        },
      ),
    );
  }
}
