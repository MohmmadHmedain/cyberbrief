import 'package:flutter/material.dart';
import '../app_strings.dart';
import 'app_locale.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  static const Color _bg = Color(0xFF05070D);
  static const Color _panel = Color(0xFF0B1220);
  static const Color _panel2 = Color(0xFF101A2E);
  static const Color _cyan = Color(0xFF22D3EE);
  static const Color _green = Color(0xFF22C55E);
  static const Color _textSoft = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    final t = S.of;

    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        final current = locale.languageCode;

        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: _bg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              t(context, 'language'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0D1728),
                      Color(0xFF09111D),
                    ],
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.30),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.language_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t(context, 'language'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t(context, 'language_subtitle'),
                            style: const TextStyle(
                              color: _textSoft,
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _LanguageOptionCard(
                icon: Icons.public_rounded,
                accent: _cyan,
                title: t(context, 'english'),
                nativeLabel: 'English',
                subtitle: 'English • EN',
                selected: current == 'en',
                onTap: () async {
                  if (current == 'en') {
                    Navigator.pop(context);
                    return;
                  }
                  await setAppLocale('en');
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              const SizedBox(height: 14),
              _LanguageOptionCard(
                icon: Icons.translate_rounded,
                accent: _green,
                title: t(context, 'arabic'),
                nativeLabel: 'العربية',
                subtitle: 'العربية • AR',
                selected: current == 'ar',
                onTap: () async {
                  if (current == 'ar') {
                    Navigator.pop(context);
                    return;
                  }
                  await setAppLocale('ar');
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LanguageOptionCard extends StatelessWidget {
  const _LanguageOptionCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.nativeLabel,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String nativeLabel;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: selected
              ? [
                  accent.withOpacity(0.18),
                  const Color(0xFF101827),
                ]
              : [
                  const Color(0xFF0C1422),
                  const Color(0xFF0A101B),
                ],
        ),
        border: Border.all(
          color: selected ? accent : Colors.white.withOpacity(0.07),
          width: selected ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: accent.withOpacity(selected ? 0.20 : 0.12),
                    border: Border.all(
                      color: accent.withOpacity(selected ? 0.60 : 0.28),
                    ),
                  ),
                  child: Icon(icon, color: accent, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        nativeLabel,
                        style: TextStyle(
                          color: accent.withOpacity(0.95),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? accent : Colors.transparent,
                    border: Border.all(
                      color: selected ? accent : Colors.white24,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 18,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}