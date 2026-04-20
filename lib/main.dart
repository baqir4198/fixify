import 'package:flutter/material.dart';
import 'package:handyman_app/screens/main_wrapper.dart';

void main() {
  runApp(const HandyManApp());
}

class HandyManApp extends StatelessWidget {
  const HandyManApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HandyMan App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MainWrapper(),
    );
  }
}

