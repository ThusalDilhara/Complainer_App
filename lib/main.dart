import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'CategoryPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ComplainerApp());
}

class ComplainerApp extends StatelessWidget {
  const ComplainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Complainer App',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const CategoryPage(),
    );
  }
}
