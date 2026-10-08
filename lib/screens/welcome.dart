import 'package:flutter/material.dart';
import 'package:linkvault_app/screens/signin.dart';
import 'package:linkvault_app/screens/signup.dart';
import 'package:linkvault_app/theme/theme.dart';
import 'package:linkvault_app/widgets/custom_scaffold.dart';
import 'package:linkvault_app/widgets/welcome_button.dart';

class WelcomScreen extends StatefulWidget {
  const WelcomScreen({super.key});

  @override
  State<WelcomScreen> createState() => _WelcomScreenState();
}

class _WelcomScreenState extends State<WelcomScreen> {
  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            flex:8 ,
            child: Container(
            padding: EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 48.0,
            ),
            child: Center(child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Welcome Back!\n',
                    style: TextStyle(
                      fontSize: 45.0,
                      fontWeight: FontWeight.w600,
                    )
                  ),
                  TextSpan(
                    text: 'Enter your details to access your LinkVault account.',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        )
                  )
                ]
              ),
              
            )),
          )),
          Flexible(
             flex: 1,
            child: Align(
              alignment: Alignment.bottomRight,
              child: Row(
              
              children: [
                Expanded(child: WelcomeButton(
                  buttonText: 'Sign in',
                  fontcolor: Colors.white,
                  onTap: SignInScreen(),
                   color: Colors.transparent,
                )),
                Expanded(child: WelcomeButton(
                   buttonText: 'Sign up',
                    fontcolor: lightColorScheme.primary,
                   onTap: SignUpScreen(),
                   color: Colors.white,
                )),
              ],
                        ),
            )),

        ],
      ),
    );
  }
}
