import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/agent_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

class NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AgentProvider(),
      child: const CoderApp(),
    ),
  );
}

class CoderApp extends StatelessWidget {
  const CoderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coder — AI Code Generation',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: NoGlowScrollBehavior(),
          child: child!,
        );
      },
      home: const HomeScreen(),
    );
  }
}
