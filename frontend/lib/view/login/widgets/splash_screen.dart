import 'package:flutter/material.dart';
import 'dart:async';
import '../login_page.dart';
// ignore: unused_import
import '../../dashboard/dashboard.dart';

class SplashScreen extends StatefulWidget {
  final bool isLoggedIn;

  const SplashScreen({super.key, required this.isLoggedIn,});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      if (mounted){
        if(widget.isLoggedIn){
          Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const DashboardPage(userName: '',)),);
        } else {
          Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => LoginPage()),);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 29, 160),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/travelxtittle.png', width: 300, height: 300),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
