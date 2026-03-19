import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart'; // Panggil layar login

void main() {
  runApp(const MyPSKDApp());
}

class MyPSKDApp extends StatelessWidget {
  const MyPSKDApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MyPSKD',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(), // Halaman pertama yang dibuka adalah Login
    );
  }
}