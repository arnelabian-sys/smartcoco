import 'package:flutter/material.dart';
import 'theme.dart';
import 'routes/app_router.dart';

class SmartCocoApp extends StatelessWidget {
  const SmartCocoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartCoco',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      initialRoute: '/',
      onGenerateRoute: generateRoute,
    );
  }
}
