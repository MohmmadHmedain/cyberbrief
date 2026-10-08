import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_locale.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  final Color _accent = const Color(0xFF67C9E6);

  SupabaseClient get sb => Supabase.instance.client;

  bool get _isArabic => localeNotifier.value.languageCode == 'ar';

  TextDirection get _textDirection =>
      _isArabic ? TextDirection.rtl : TextDirection.ltr;

  TextAlign get _textAlign => _isArabic ? TextAlign.right : TextAlign.left;

  String _t(String ar, String en) => _isArabic ? ar : en;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
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

  Future<void> _changePassword() async {
    final current = _currentController.text.trim();
    final newPass = _newController.text.trim();
    final confirm = _confirmController.text.trim();

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _show(_t('يرجى تعبئة جميع الحقول', 'Please fill all fields'));
      return;
    }

    if (newPass.length < 6) {
      _show(_t(
        'يجب أن تكون كلمة المرور 6 أحرف على الأقل',
        'Password must be at least 6 characters',
      ));
      return;
    }

    if (newPass != confirm) {
      _show(_t(
        'كلمتا المرور الجديدتان غير متطابقتين',
        'New passwords do not match',
      ));
      return;
    }

    final user = sb.auth.currentUser;
    if (user?.email == null) {
      _show(_t('لا يوجد مستخدم مسجل الدخول', 'No logged-in user'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Verify the current password by signing in again.
      await sb.auth.signInWithPassword(
        email: user!.email!,
        password: current,
      );

      // Update the password in Supabase.
      await sb.auth.updateUser(
        UserAttributes(password: newPass),
      );

      _show(_t('تم تحديث كلمة المرور بنجاح', 'Password updated successfully'));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _show(_t(
        'حدث خطأ أثناء تحديث كلمة المرور. تأكد من كلمة المرور الحالية وحاول مرة أخرى.',
        'Error updating password. Check your current password and try again.',
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
            backgroundColor: Colors.black,
            appBar: AppBar(
              title: Text(_t('تغيير كلمة المرور', 'Change Password')),
              backgroundColor: Colors.black,
            ),
            body: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildField(
                        controller: _currentController,
                        hint: _t('كلمة المرور الحالية', 'Current Password'),
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _newController,
                        hint: _t('كلمة المرور الجديدة', 'New Password'),
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _confirmController,
                        hint: _t(
                          'تأكيد كلمة المرور الجديدة',
                          'Confirm New Password',
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            _t('حفظ', 'Save'),
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
                if (_isLoading)
                  Container(
                    color: Colors.black45,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      obscureText: true,
      textDirection: _textDirection,
      textAlign: _textAlign,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white60),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF67C9E6)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
