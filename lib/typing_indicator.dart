import 'package:flutter/material.dart';

class TypingIndicator extends StatelessWidget {
  final bool showIndicator;

  TypingIndicator({required this.showIndicator});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300), // Animation duration
      height: showIndicator ? 40 : 0,
      alignment: Alignment.centerLeft,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Text('Typing...', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
