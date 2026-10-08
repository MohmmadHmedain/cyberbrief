import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/language_screen.dart';
import 'screens/reset_password_screen.dart';

class CyberGuardApp extends StatefulWidget {
  final Locale locale;

  const CyberGuardApp({super.key, required this.locale});

  @override
  State<CyberGuardApp> createState() => _CyberGuardAppState();
}

class _CyberGuardAppState extends State<CyberGuardApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.passwordRecovery) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/reset-password',
            (_) => false,
          );
        });
        return;
      }

      if (event == AuthChangeEvent.signedIn && session != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/home',
            (_) => false,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'CyberBreif',
      debugShowCheckedModeBanner: false,

      locale: widget.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00F59B)),
      ),

      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
        '/signup': (_) => const SignUpScreen(),
        '/language': (_) => const LanguageScreen(),
        '/reset-password': (_) => const ResetPasswordScreen(),
      },
    );
  }
}
