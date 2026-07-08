import 'package:flutter/material.dart';

void main() => runApp(const TestApp());

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Test')),
        body: const Center(child: Text('Hello Flutter!', style: TextStyle(fontSize: 24))),
      ),
    );
  }
}
