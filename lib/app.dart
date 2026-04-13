import 'package:flutter/material.dart';

/// Root application widget.
///
/// Locale, routing, and BlocProviders are wired in later plans.
class AgendaApp extends StatelessWidget {
  const AgendaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AGENDA',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(child: Text('AGENDA')),
      ),
    );
  }
}
