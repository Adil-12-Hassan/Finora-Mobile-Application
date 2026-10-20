import 'package:flutter/material.dart';

class FinoraLogo extends StatelessWidget {
  const FinoraLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'assets/finora_logo.jpg',
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: 'Finora logo',
      ),
    );
  }
}
