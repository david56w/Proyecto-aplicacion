import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier{
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme(bool isdark){
    _themeMode = isdark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}