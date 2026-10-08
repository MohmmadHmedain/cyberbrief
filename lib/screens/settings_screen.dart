import 'package:flutter/material.dart';

import '../app_strings.dart';       // ✅ الترجمة
import 'app_locale.dart';           // ✅ لإظهار اللغة الحالية (إذا تحب)
import 'language_screen.dart';

import 'profile_screen.dart';
import 'about_app_screen.dart';
import 'privacy_security_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = S.of;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(t(context, 'settings')),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== Account =====
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8, top: 8),
            child: Text(
              t(context, 'account'),
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.cyan),
            title: Text(
              t(context, 'profile'),
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              t(context, 'profile_sub'),
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white70),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),

          const Divider(color: Colors.grey),

          // ===== Preferences =====
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8, top: 8),
            child: Text(
              t(context, 'preferences'),
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),

          SwitchListTile(
            title: Text(
              t(context, 'enable_notifications'),
              style: const TextStyle(color: Colors.white),
            ),
            value: true,
            onChanged: (val) {},
            activeColor: Colors.cyan,
            secondary: const Icon(Icons.notifications_none, color: Colors.cyan),
          ),

          const Divider(color: Colors.grey),

          // ===== Security & Privacy =====
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8, top: 8),
            child: Text(
              t(context, 'security_privacy'),
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.security, color: Colors.cyan),
            title: Text(
              t(context, 'privacy_security'),
              style: const TextStyle(color: Colors.white),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white70),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()),
              );
            },
          ),

          const Divider(color: Colors.grey),

          // ===== General =====
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8, top: 8),
            child: Text(
              t(context, 'general'),
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),

          // Language tile (مع عرض اللغة الحالية)
          ValueListenableBuilder<Locale>(
            valueListenable: localeNotifier,
            builder: (context, locale, _) {
              final currentLang =
                  (locale.languageCode == 'ar') ? 'العربية' : 'English';

              return ListTile(
                leading: const Icon(Icons.language, color: Colors.greenAccent),
                title: Text(
                  t(context, 'language'),
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  currentLang,
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LanguageScreen()),
                  );
                },
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.blueAccent),
            title: Text(
              t(context, 'about_app'),
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              t(context, 'about_sub'),
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white70),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AboutAppScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}