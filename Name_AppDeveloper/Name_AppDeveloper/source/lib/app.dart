import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'ui/home_screen.dart';

class VirtualTryOnApp extends StatelessWidget {
  const VirtualTryOnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Try-On',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const HomeScreen(),
    );
  }
}
