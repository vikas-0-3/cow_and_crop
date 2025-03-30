import 'package:flutter/material.dart';
import 'splash_screen.dart';

void main() {
  runApp(const CowAndCropApp());
}

class CowAndCropApp extends StatelessWidget {
  const CowAndCropApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cow and Crop',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const SplashScreen(),
    );
  }
}
