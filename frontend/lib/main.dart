import 'package:flutter/material.dart';

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
      home: const BerandaScreen(),
    );
  }
}

class BerandaScreen extends StatelessWidget {
  const BerandaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MyPSKD App'), centerTitle: true),
      body: const Center(
        child: Text(
          'Aplikasi Frontend Berjalan Sukses! 🚀',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
//test