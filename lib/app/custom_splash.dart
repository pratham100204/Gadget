import 'package:flutter/material.dart';

class CustomSplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF000000), // Black background
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Spacer to push content to center
          Spacer(flex: 2),

          // App icon in center
          Center(
            child: Image.asset(
              'assets/splash_icon.png',
              width: 200,
              height: 200,
            ),
          ),

          // Spacer between icon and bottom section
          Spacer(flex: 2),

          // Bottom section with "Powered by" text and college logo
          Column(
            children: [
              Text(
                'Powered by',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 8),
              Image.asset(
                'assets/clglogo.png',
                width: 150,
                height: 60,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 40),
            ],
          ),
        ],
      ),
    );
  }
}
