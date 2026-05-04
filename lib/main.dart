import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    // Ignore le bug connu du keyboard embedder
    if (details.toString().contains('physical != 0 && logical != 0')) return;
    FlutterError.presentError(details);
  };
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkSession()),
      ],
      child: const GestiAbsencesApp(),
    ),
  );
}

class GestiAbsencesApp extends StatelessWidget {
  const GestiAbsencesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GestiAbsences',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const _SplashRouter(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

/// Redirige vers login ou home selon la session
class _SplashRouter extends StatelessWidget {
  const _SplashRouter();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isLoggedIn) return const HomeScreen();
    return const LoginScreen();
  }
}
