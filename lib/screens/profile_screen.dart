import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_locale.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  SupabaseClient get sb => Supabase.instance.client;

  late Future<Map<String, dynamic>?> _profileFuture;

  bool get _isArabic => localeNotifier.value.languageCode == 'ar';

  TextDirection get _textDirection =>
      _isArabic ? TextDirection.rtl : TextDirection.ltr;

  String _t(String ar, String en) => _isArabic ? ar : en;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<Map<String, dynamic>?> _loadProfile() async {
    final userResp = await sb.auth.getUser();
    final user = userResp.user;
    if (user == null) return null;

    final profileRow = await sb
        .from('profiles')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    return {
      'profile': profileRow,
      'authEmail': user.email,
    };
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
              title: Text(_t('الملف الشخصي', 'Profile')),
              backgroundColor: Colors.black,
            ),
            body: FutureBuilder<Map<String, dynamic>?>(
              future: _profileFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '${_t('حدث خطأ', 'Error')}: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }

                final data = snapshot.data;

                if (data == null) {
                  return Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (_) => false,
                        );
                      },
                      child: Text(
                        _t(
                          'لا يوجد مستخدم مسجّل. انتقل إلى تسجيل الدخول',
                          'No user logged in. Go to Login',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }

                final profile = data['profile'] as Map<String, dynamic>?;
                final authEmail = data['authEmail'] as String?;

                final name = profile?['display_name'] ?? _t('بدون اسم', 'No name');
                final email = profile?['email'] ?? authEmail ?? '';

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.cyan,
                        child: Icon(Icons.person, size: 60, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        email,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 32),

                      ListTile(
                        leading: const Icon(Icons.edit, color: Colors.blue),
                        title: Text(
                          _t('تعديل الملف الشخصي', 'Edit Profile'),
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProfileScreen(),
                            ),
                          );

                          setState(() {
                            _profileFuture = _loadProfile();
                          });
                        },
                      ),

                      ListTile(
                        leading: const Icon(Icons.lock, color: Colors.red),
                        title: Text(
                          _t('تغيير كلمة المرور', 'Change Password'),
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChangePasswordScreen(),
                            ),
                          );
                        },
                      ),

                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.orange),
                        title: Text(
                          _t('تسجيل الخروج', 'Logout'),
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () async {
                          await sb.auth.signOut();
                          if (!mounted) return;
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (_) => false,
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
