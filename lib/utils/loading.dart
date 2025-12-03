import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class Loading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Design Colors
    final Color _backgroundColor = const Color(0xFF000000); // Black Background
    final Color _accentColor = const Color(0xFFFF3B30); // Red Theme Color

    return Container(
      color: _backgroundColor,
      child: Center(
        child: SizedBox(
          width: 150, // Adjust size as needed
          height: 150,
          child: Lottie.asset(
            'assets/loading circle.json',
            delegates: LottieDelegates(
              values: [
                ValueDelegate.color(
                  const ['**'], // Targets all layers
                  value: _accentColor,
                ),
              ],
            ),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
