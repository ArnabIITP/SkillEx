import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'Screen/User/Login.dart';
import 'Screen/User/setup.dart';
 // your root widget

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // 🔥 This is required
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ProfileSetupPage(),
    );
  }
}


