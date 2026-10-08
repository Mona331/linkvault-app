import 'package:flutter/material.dart';
import 'package:linkvault_app/screens/signup.dart';

class WelcomeButton extends StatelessWidget {
  const WelcomeButton({super.key, required this.buttonText, this.onTap, this.color, this.fontcolor});
  final String buttonText;
  final Widget? onTap;
  final Color? color;
  final Color? fontcolor;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (e) => onTap!));
      },
      child: Container(
        padding: EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: color!,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(50),
            bottomRight: Radius.circular(50),
          ),
        ),
        child: Text(
          buttonText!,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold,color:fontcolor! ),
        ),
      ),
    );
  }
}
