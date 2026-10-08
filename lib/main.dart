import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'screens/app_locale.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qbduqcazeoyuqgixprhi.supabase.co',
  );

  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  if (supabaseAnonKey.isEmpty) {
    throw Exception(
      'SUPABASE_ANON_KEY is not configured. '
      'Run Flutter with --dart-define=SUPABASE_ANON_KEY=YOUR_KEY',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // Load saved language before app starts
  await loadSavedLocale();

  runApp(const CyberGuardRoot());
}

class CyberGuardRoot extends StatelessWidget {
  const CyberGuardRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        return CyberGuardApp(locale: locale);
      },
    );
  }
}