import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_locale.dart';
import 'faq_screen.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final Color _background = const Color(0xFF020617);
  final Color _card = const Color(0xFF020617);
  final Color _accent = const Color(0xFF00F59B);
  final Color _border = const Color(0xFF06B6D4);

  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String _email = '';
  String _phone = '';
  String _type = '';
  String _severity = '';
  String _description = '';

  bool _sending = false;

  final List<String> _typeCodes = const [
    'account_hack',
    'phishing',
    'blackmail',
    'financial_fraud',
    'malware',
    'impersonation',
    'other',
  ];

  final List<String> _severityCodes = const [
    'low',
    'medium',
    'high',
    'critical',
  ];

  bool get _isArabic => localeNotifier.value.languageCode == 'ar';

  TextDirection get _textDirection =>
      _isArabic ? TextDirection.rtl : TextDirection.ltr;

  TextAlign get _textAlign => _isArabic ? TextAlign.right : TextAlign.left;

  String _t(String ar, String en) => _isArabic ? ar : en;

  String _typeLabel(String code) {
    final ar = {
      'account_hack': 'اختراق حساب',
      'phishing': 'تصيّد (Phishing)',
      'blackmail': 'ابتزاز إلكتروني',
      'financial_fraud': 'احتيال مالي',
      'malware': 'برمجيات خبيثة',
      'impersonation': 'انتحال شخصية',
      'other': 'أخرى',
    };

    final en = {
      'account_hack': 'Account hack',
      'phishing': 'Phishing',
      'blackmail': 'Cyber extortion',
      'financial_fraud': 'Financial fraud',
      'malware': 'Malware',
      'impersonation': 'Impersonation',
      'other': 'Other',
    };

    return (_isArabic ? ar : en)[code] ?? code;
  }

  String _severityLabel(String code) {
    final ar = {
      'low': 'منخفض',
      'medium': 'متوسط',
      'high': 'عالي',
      'critical': 'حرج',
    };

    final en = {
      'low': 'Low',
      'medium': 'Medium',
      'high': 'High',
      'critical': 'Critical',
    };

    return (_isArabic ? ar : en)[code] ?? code;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _sending = true);

    final sb = Supabase.instance.client;

    try {
      await sb.from('reports').insert({
        'user_id': sb.auth.currentUser?.id,
        'name': _name.trim(),
        'email': _email.trim(),
        'phone': _phone.trim(),
        'type': _type,
        'severity': _severity,
        'description': _description.trim(),
        'status': 'new',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('تم إرسال البلاغ بنجاح ✅', 'Report sent successfully ✅'))),
      );

      _formKey.currentState!.reset();
      setState(() {
        _name = '';
        _email = '';
        _phone = '';
        _type = '';
        _severity = '';
        _description = '';
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('فشل إرسال البلاغ: ${e.message}', 'Failed to send report: ${e.message}'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('فشل إرسال البلاغ: $e', 'Failed to send report: $e'))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        return Directionality(
          textDirection: _textDirection,
          child: Scaffold(
            backgroundColor: _background,
            appBar: AppBar(
              backgroundColor: _background,
              elevation: 0,
              centerTitle: true,
              title: Text(
                _t('تقديم بلاغ أمني', 'Submit Security Report'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: Column(
                          children: [
                            _hero(),
                            _formCard(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            floatingActionButton: FloatingActionButton(
              backgroundColor: _accent,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => FaqScreen()),
                );
              },
              child: Transform(
                alignment: Alignment.center,
                transform: _isArabic ? Matrix4.rotationY(math.pi) : Matrix4.identity(),
                child: const Icon(Icons.help_outline, color: Colors.black),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _hero() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _accent.withOpacity(0.10),
            boxShadow: [
              BoxShadow(
                color: _accent.withOpacity(0.7),
                blurRadius: 30,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            Icons.warning_amber_rounded,
            size: 40,
            color: _accent,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _t('تقديم بلاغ أمني', 'Submit Security Report'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: _accent.withOpacity(0.9),
                blurRadius: 20,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _t(
            'ساعدنا في الحفاظ على الأمن السيبراني من خلال الإبلاغ عن أي تهديدات أو حوادث أمنية',
            'Help us protect cybersecurity by reporting any threats or security incidents',
          ),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _formCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _card.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border.withOpacity(0.8)),
          ),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabeledField(
                  label: _t('الاسم الكامل *', 'Full name *'),
                  child: _buildTextField(
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? _t('الرجاء إدخال الاسم', 'Please enter your name')
                        : null,
                    onSaved: (v) => _name = v ?? '',
                  ),
                ),
                const SizedBox(height: 16),

                _buildLabeledField(
                  label: _t('البريد الإلكتروني *', 'Email *'),
                  child: _buildTextField(
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return _t('الرجاء إدخال البريد الإلكتروني', 'Please enter your email');
                      }
                      final email = v.trim();
                      final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
                      if (!ok) return _t('أدخل بريد إلكتروني صحيح', 'Enter a valid email address');
                      return null;
                    },
                    onSaved: (v) => _email = v ?? '',
                  ),
                ),
                const SizedBox(height: 16),

                _buildLabeledField(
                  label: _t('رقم الهاتف *', 'Phone number *'),
                  child: _buildTextField(
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? _t('الرجاء إدخال رقم الهاتف', 'Please enter your phone number')
                        : null,
                    onSaved: (v) => _phone = v ?? '',
                  ),
                ),
                const SizedBox(height: 20),

                _buildLabeledField(
                  label: _t('نوع البلاغ *', 'Report type *'),
                  child: _buildDropdown(
                    value: _type.isEmpty ? null : _type,
                    hint: _t('اختر نوع البلاغ', 'Select report type'),
                    items: _typeCodes
                        .map(
                          (code) => DropdownMenuItem<String>(
                            value: code,
                            child: Text(_typeLabel(code)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _type = v ?? ''),
                    validator: (v) {
                      if (v == null) return _t('اختر نوع البلاغ', 'Please select report type');
                      if ((v as String).isEmpty) return _t('اختر نوع البلاغ', 'Please select report type');
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),

                _buildLabeledField(
                  label: _t('مستوى الخطورة *', 'Severity level *'),
                  child: _buildDropdown(
                    value: _severity.isEmpty ? null : _severity,
                    hint: _t('اختر مستوى الخطورة', 'Select severity level'),
                    items: _severityCodes
                        .map(
                          (code) => DropdownMenuItem<String>(
                            value: code,
                            child: Text(_severityLabel(code)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _severity = v ?? ''),
                    validator: (v) {
                      if (v == null) return _t('اختر مستوى الخطورة', 'Please select severity level');
                      if ((v as String).isEmpty) return _t('اختر مستوى الخطورة', 'Please select severity level');
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),

                _buildLabeledField(
                  label: _t('وصف البلاغ *', 'Report description *'),
                  child: TextFormField(
                    maxLines: 5,
                    textDirection: _textDirection,
                    textAlign: _textAlign,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _t('يرجى شرح ما حدث بالتفصيل...', 'Please explain what happened in detail...'),
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                      filled: true,
                      fillColor: _background.withOpacity(0.5),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: _border.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: _accent, width: 1.5),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? _t('الرجاء إدخال وصف البلاغ', 'Please enter the report description')
                        : null,
                    onSaved: (v) => _description = v ?? '',
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _sending ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(_sending ? _t('جاري الإرسال...', 'Sending...') : _t('إرسال البلاغ', 'Submit Report')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledField({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildTextField({
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return TextFormField(
      keyboardType: keyboardType,
      textDirection: _textDirection,
      textAlign: _textAlign,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: _background.withOpacity(0.5),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _border.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _accent, width: 1.5),
        ),
      ),
      validator: validator,
      onSaved: onSaved,
    );
  }

  Widget _buildDropdown({
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
    String? value,
    String? hint,
    String? Function(Object?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      dropdownColor: _background,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: _background.withOpacity(0.5),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _border.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _accent, width: 1.5),
        ),
      ),
      hint: Text(
        hint ?? '',
        style: TextStyle(color: Colors.white.withOpacity(0.6)),
      ),
    );
  }
}
