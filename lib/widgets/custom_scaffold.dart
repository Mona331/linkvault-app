import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:linkvault_app/theme/theme.dart';

class CustomScaffold extends StatefulWidget {
  const CustomScaffold({super.key, this.child, this.titlet});
  final Widget? child;
  final Text? titlet;

  @override
  State<CustomScaffold> createState() => _CustomScaffoldState();
}

class _CustomScaffoldState extends State<CustomScaffold> {
  // int index = 2;

  @override
  Widget build(BuildContext context) {
    // final items = <Widget>[
    //   Icon(Icons.home, size: 30, color: Colors.white),
    //   Icon(Icons.favorite, size: 30, color: Colors.white),
    //   Icon(Icons.add, size: 30, color: Colors.white),
    //   Icon(Icons.person, size: 30, color: Colors.white),
    // ];
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        //title:titlrt,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      // bottomNavigationBar: CurvedNavigationBar(
      //   animationCurve: Curves.easeInOut,
      //   animationDuration: Duration(milliseconds: 300),
      //   backgroundColor: Colors.transparent,
      //   color: Color.fromARGB(175, 5, 99, 142),
      //   height: 60,
      //   index: index,
      //   items: items,
      //   onTap: (index) => setState(() => this.index = index),
      // ),
      body: Stack(
        children: [
          Image.asset(
            'assets/images/bg4.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          SafeArea(child: widget.child!),
        ],
      ),
    );
  }
}
