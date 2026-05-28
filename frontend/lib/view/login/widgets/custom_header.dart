import 'package:flutter/material.dart';

class CustomHeader extends StatelessWidget {
  const CustomHeader({super.key});

@override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerLeft,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          height: 60,
          decoration: const BoxDecoration(
            color: Colors.blue,
          ),
        ),
      Positioned(
        left: 0,
        top: -30,  
        child: Image.asset(
            'assets/travelxtittle.png',
            height: 130,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}