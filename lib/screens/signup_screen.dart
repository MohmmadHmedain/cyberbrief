import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  static const route = '/signup';

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static const String _oauthRedirect = 'cyberguard://login-callback';
  final _usernameController = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();

  final Color _background = const Color(0xFF020617);
  final Color _accent     = const Color(0xFF00F59B);
  final Color _accentDeep = const Color(0xFF06B6D4);
  final Color _border     = const Color(0xFF06B6D4);

  bool _isLoading = false;

  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  SupabaseClient get sb => Supabase.instance.client;
  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();

    _authSub = sb.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if ((event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) && session != null) {
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateUsername(String value) {
    final username = value.trim();

    if (username.isEmpty) {
      return 'Username is required';
    }

    if (username.length < 3) {
      return 'Username must be at least 3 characters';
    }

    if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(username)) {
      return 'Only letters, numbers, and underscore (_) are allowed';
    }

    return null;
  }

  String? _validateEmail(String value) {
    final email = value.trim();

    if (email.isEmpty) {
      return 'Email is required';
    }

    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  String? _validateConfirmPassword(String value) {
    if (value.isEmpty) {
      return 'Confirm password is required';
    }

    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  bool _validateForm() {
    final usernameError = _validateUsername(_usernameController.text);
    final emailError = _validateEmail(_emailController.text);
    final passwordError = _validatePassword(_passwordController.text);
    final confirmError = _validateConfirmPassword(_confirmController.text);

    setState(() {
      _usernameError = usernameError;
      _emailError = emailError;
      _passwordError = passwordError;
      _confirmError = confirmError;
    });

    return usernameError == null &&
        emailError == null &&
        passwordError == null &&
        confirmError == null;
  }

  // ============ Supabase Sign Up ============
  Future<void> _signUpWithSupabase() async {
    final username = _usernameController.text.trim();
    final email    = _emailController.text.trim();
    final pass     = _passwordController.text;
    final confirm  = _confirmController.text;

    if (!_validateForm()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await sb.auth.signUp(
        email: email,
        password: pass,
      );

      if (res.user == null) {
        _show('Sign up failed');
        return;
      }

      // تخزين بيانات المستخدم في جدول profiles
      await sb.from('profiles').upsert({
        'user_id': res.user!.id,
        'email': res.user!.email,
        'display_name': username,
      });

      if (!mounted) return;
      // بعد التسجيل مباشرة ادخل على صفحة الهوم
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      _show('Error: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _onGoogle() async {
    try {
      setState(() => _isLoading = true);

      await sb.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _oauthRedirect,
      );
    } catch (e) {
      _show('Google sign up failed: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();

    if (!RegExp(r"^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(email)) {
      _show('Enter your email first');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await sb.auth.resetPasswordForEmail(
        email,
        redirectTo: _oauthRedirect,
      );
      _show('Password reset link sent to your email');
    } catch (e) {
      _show('Failed to send reset link: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _onFingerprint() {
    _show('Fingerprint sign up (not implemented yet)');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),

                    // Logo
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _accent, width: 3),
                      ),
                      child:
                          Icon(Icons.security_rounded, color: _accent, size: 40),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'CyberBreif',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        shadows: const [
                          Shadow(color: Colors.white24, blurRadius: 8),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Username
                    _buildTextField(
                      controller: _usernameController,
                      hint: 'Username',
                      icon: Icons.person_outline,
                      errorText: _usernameError,
                      onChanged: (value) {
                        setState(() => _usernameError = _validateUsername(value));
                      },
                    ),
                    const SizedBox(height: 14),

                    // Email
                    _buildTextField(
                      controller: _emailController,
                      hint: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      errorText: _emailError,
                      onChanged: (value) {
                        setState(() => _emailError = _validateEmail(value));
                      },
                    ),
                    const SizedBox(height: 14),

                    // Password
                    _buildTextField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock_outline,
                      obscure: true,
                      errorText: _passwordError,
                      onChanged: (value) {
                        setState(() {
                          _passwordError = _validatePassword(value);
                          _confirmError = _confirmController.text.isEmpty
                              ? _confirmError
                              : _validateConfirmPassword(_confirmController.text);
                        });
                      },
                    ),
                    const SizedBox(height: 14),

                    // Confirm Password
                    _buildTextField(
                      controller: _confirmController,
                      hint: 'Confirm Password',
                      icon: Icons.lock,
                      obscure: true,
                      errorText: _confirmError,
                      onChanged: (value) {
                        setState(() => _confirmError = _validateConfirmPassword(value));
                      },
                    ),
                    const SizedBox(height: 24),

                    // Sign Up + Login row
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed:
                                  _isLoading ? null : _signUpWithSupabase,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accent,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 6,
                              ),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      Navigator.pop(context); // رجوع للّوج إن
                                    },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white30),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: const Text(
                                'Login',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: _isLoading ? null : _forgotPassword,
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Google button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _onGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 3,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.black.withOpacity(0.08),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Image.network(
                                'https://developers.google.com/identity/images/g-logo.png',
                                width: 22,
                                height: 22,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.g_mobiledata,
                                    size: 26,
                                    color: Colors.black87,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Sign Up with Google',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Fingerprint button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _onFingerprint,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentDeep,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 4,
                        ),
                        icon: const Icon(Icons.fingerprint),
                        label: const Text(
                          'Login with Fingerprint',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),

          // overlay تحميل
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: _accent),
                    const SizedBox(height: 10),
                    const Text(
                      'Creating account...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    final hasError = errorText != null;
    final fieldBorderColor = hasError ? Colors.redAccent : _border.withOpacity(0.45);
    final focusedBorderColor = hasError ? Colors.redAccent : _accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasError) ...[
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 6),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    errorText,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white60),
            prefixIcon: Icon(icon, color: hasError ? Colors.redAccent : Colors.white70),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: fieldBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: fieldBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: focusedBorderColor, width: 1.4),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          ),
        ),
      ],
    );
  }
}

