import 'package:flutter/material.dart';
import 'dart:async';
import 'login_page.dart';

class SplashScreen extends StatefulWidget{
  const SplashScreen({super.key});
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()),
      );
    });
  }
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Colors.blueAccent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/travelxtittle.png', width: 150, height: 150),
              const SizedBox(height: 20,),
              const Text("Travel X", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: 
              Colors.white),
            ],
          ),
        ),
      );
    }
  }