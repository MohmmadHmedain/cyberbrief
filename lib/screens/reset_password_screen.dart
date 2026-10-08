import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_locale.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});
  static const route = '/reset-password';

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _hidePassword = true;
  bool _hideConfirm = true;

  final Color _accent = const Color(0xFF00F59B);
  final Color _cyan = const Color(0xFF06B6D4);
  final Color _background = const Color(0xFF020617);

  SupabaseClient get sb => Supabase.instance.client;

  bool get _isArabic => localeNotifier.value.languageCode == 'ar';
  TextDirection get _textDirection => _isArabic ? TextDirection.rtl : TextDirection.ltr;
  TextAlign get _textAlign => _isArabic ? TextAlign.right : TextAlign.left;
  String _t(String ar, String en) => _isArabic ? ar : en;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          textDirection: _textDirection,
          textAlign: _textAlign,
        ),
      ),
    );
  }

  Future<void> _updatePassword() async {
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (password.isEmpty || confirm.isEmpty) {
      _show(_t('يرجى تعبئة جميع الحقول', 'Please fill all fields'));
      return;
    }

    if (password.length < 6) {
      _show(_t('يجب أن تكون كلمة المرور 6 أحرف على الأقل', 'Password must be at least 6 characters'));
      return;
    }

    if (password != confirm) {
      _show(_t('كلمتا المرور غير متطابقتين', 'Passwords do not match'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await sb.auth.updateUser(UserAttributes(password: password));

      if (!mounted) return;
      _show(_t('تم تغيير كلمة المرور بنجاح', 'Password changed successfully'));

      await Future.delayed(const Duration(milliseconds: 700));
      await sb.auth.signOut();

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } catch (e) {
      _show(_t(
        'انتهت صلاحية الرابط أو لم يتم فتحه من التطبيق. أعد إرسال رابط جديد وحاول مرة أخرى.',
        'The link expired or was not opened from the app. Send a new link and try again.',
      ));
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
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
              foregroundColor: Colors.white,
              elevation: 0,
              title: Text(_t('إعادة تعيين كلمة المرور', 'Reset Password')),
            ),
            body: Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _accent, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: _cyan.withOpacity(0.25),
                                blurRadius: 28,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(Icons.lock_reset_rounded, color: _accent, size: 42),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'CyberBreif',
                          style: TextStyle(
                            color: _accent,
                            fontSize: 27,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _t(
                            'اكتب كلمة المرور الجديدة لحسابك',
                            'Enter your new account password',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 28),
                        _buildPasswordField(
                          controller: _passwordController,
                          hint: _t('كلمة المرور الجديدة', 'New Password'),
                          hidden: _hidePassword,
                          onToggle: () => setState(() => _hidePassword = !_hidePassword),
                        ),
                        const SizedBox(height: 14),
                        _buildPasswordField(
                          controller: _confirmController,
                          hint: _t('تأكيد كلمة المرور', 'Confirm Password'),
                          hidden: _hideConfirm,
                          onToggle: () => setState(() => _hideConfirm = !_hideConfirm),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updatePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              _t('حفظ كلمة المرور', 'Save Password'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black54,
                    child: Center(child: CircularProgressIndicator(color: _accent)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool hidden,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: hidden,
      textDirection: _textDirection,
      textAlign: _textAlign,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.07),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white60),
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(hidden ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: _cyan.withOpacity(0.45)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: _accent, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      ),
    );
  }
}
