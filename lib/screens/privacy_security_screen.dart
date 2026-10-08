// lib/screens/privacy_security_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_locale.dart';
import 'scan_history_screen.dart';
import 'privacy_policy_screen.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _saveScanHistory = true;

  bool get _isArabic => localeNotifier.value.languageCode == 'ar';

  String _t(String ar, String en) => _isArabic ? ar : en;

  TextDirection get _direction => _isArabic ? TextDirection.rtl : TextDirection.ltr;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _saveScanHistory = prefs.getBool('saveScanHistory') ?? true;
    });
  }

  Future<void> _updateSaveScanHistory(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('saveScanHistory', value);

    if (!mounted) return;
    setState(() {
      _saveScanHistory = value;
    });

    _showSnack(
      value
          ? _t('سيتم حفظ سجل الفحص محليًا على هذا الجهاز.', 'Scan history will be stored locally.')
          : _t('لن يتم حفظ سجل الفحص.', 'Scan history will not be stored.'),
    );
  }

  Future<void> _clearScanHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('scanHistory');
    if (!mounted) return;
    _showSnack(_t('تم مسح سجل الفحص.', 'Scan history cleared.'));
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Directionality(
          textDirection: _direction,
          child: Text(msg),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const background = Colors.black;

    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        return Directionality(
          textDirection: _direction,
          child: Scaffold(
            backgroundColor: background,
            appBar: AppBar(
              backgroundColor: background,
              title: Text(_t('الخصوصية والأمان', 'Privacy & Security')),
              centerTitle: true,
              elevation: 0,
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.cyanAccent.withOpacity(0.35),
                    ),
                  ),
                  child: Text(
                    _t(
                      'نحافظ على خصوصية بياناتك ونستخدمها فقط لتقديم إرشادات الأمن السيبراني ونتائج الفحص. يمكنك التحكم بطريقة حفظ معلوماتك واستخدامها من هذه الصفحة.',
                      'We keep your data private and use it only to provide cybersecurity guidance and scanning results. You can control how your information is stored and used from this page.',
                    ),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 12, bottom: 8),
                  child: Text(
                    _t('سجل الفحص', 'Scan History'),
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                SwitchListTile(
                  value: _saveScanHistory,
                  onChanged: _updateSaveScanHistory,
                  activeColor: Colors.cyan,
                  secondary: const Icon(Icons.history, color: Colors.cyanAccent),
                  title: Text(
                    _t('حفظ سجل الفحص', 'Save Scan History'),
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    _t('حفظ نتائج فحص الروابط والملفات السابقة على هذا الجهاز', 'Store past URL/file scans on this device'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.history_toggle_off,
                    color: Colors.lightBlueAccent,
                  ),
                  title: Text(
                    _t('عرض سجل الفحص', 'View Scan History'),
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    _t('مشاهدة نتائج فحص الروابط والملفات السابقة', 'See previous URL & file scan results'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ScanHistoryScreen(),
                      ),
                    );
                  },
                ),

                const Divider(color: Colors.grey),

                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 12, bottom: 8, top: 8),
                  child: Text(
                    _t('التحكم بالبيانات', 'Data Controls'),
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: Text(
                    _t('مسح سجل الفحص', 'Clear Scan History'),
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    _t('حذف جميع نتائج الفحص المحفوظة من هذا الجهاز', 'Remove all stored scan results from this device'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  onTap: _clearScanHistory,
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: Colors.blue),
                  title: Text(
                    _t('سياسة الخصوصية', 'Privacy Policy'),
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    _t('اقرأ كيف نتعامل مع بياناتك ونحميها', 'Read how we handle and protect your data'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
