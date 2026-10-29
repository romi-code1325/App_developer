import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The tracking maths assumes an upright (portrait) camera frame.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const VirtualTryOnApp());
}
