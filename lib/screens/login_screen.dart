import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:math' as math;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  static const route = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  static const String _oauthRedirect = 'cyberguard://login-callback';

  final LocalAuthentication auth = LocalAuthentication();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isArabic = false;
  bool _isEmailValid = false;
  bool _isLocked = true;

  final Color _background = const Color(0xFF020617);
  final Color _accent = const Color(0xFF00F59B);
  final Color _accentDeep = const Color(0xFF06B6D4);
  final Color _border = const Color(0xFF06B6D4);

  late AnimationController _logoController;
  late Animation<double> _logoAnimation;
  late AnimationController _shimmerController;
  late AnimationController _lockRotateController;
  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  SupabaseClient get sb => Supabase.instance.client;
  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnimation = CurvedAnimation(parent: _entryController, curve: Curves.easeInOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 250), () => _entryController.forward());

    _logoController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _logoAnimation = Tween<double>(begin: 0.95, end: 1.08)
        .animate(CurvedAnimation(parent: _logoController, curve: Curves.easeInOut));
    _shimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _lockRotateController = AnimationController(vsync: this, duration: const Duration(seconds: 5));

    _emailController.addListener(_validateEmail);

    // لو المستخدم مسجّل دخول من قبل
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (sb.auth.currentSession != null && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });

    // مهم: بعد رجوع OAuth للتطبيق
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
    _logoController.dispose();
    _shimmerController.dispose();
    _lockRotateController.dispose();
    _entryController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    setState(() {
      _isEmailValid =
          RegExp(r"^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(_emailController.text);
    });
  }

  // ============== Supabase Sign Up (تقدر تنقلها لاحقاً لصفحة التسجيل) ==============
  Future<void> _signUp() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _show(_isArabic ? 'أدخل الإيميل وكلمة المرور' : 'Enter email and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _isLocked = true;
    });

    _lockRotateController
      ..reset()
      ..forward();

    try {
      final res = await sb.auth.signUp(email: _emailController.text.trim(), password: _passwordController.text);
      if (res.user == null) {
        _show(_isArabic ? 'فشل إنشاء الحساب' : 'Sign up failed');
        return;
      }
      await sb.from('profiles').upsert({
        'user_id': res.user!.id,
        'email': res.user!.email,
        'display_name': _emailController.text.split('@').first,
      });
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      _show('Error: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLocked = false;
      });
    }
  }

  // ============== Supabase Sign In ==============
  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _show(_isArabic ? 'الرجاء إدخال الإيميل وكلمة المرور' : 'Please enter email and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _isLocked = true;
    });

    _lockRotateController
      ..reset()
      ..forward();

    try {
      final res = await sb.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (res.user == null) {
        _show(_isArabic ? 'بيانات الدخول غير صحيحة' : 'Invalid credentials');
        return;
      }
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      _show('Error: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLocked = false;
      });
    }
  }

  // ============== Biometric ==============
  Future<void> _authenticate() async {
    try {
      final bool isSupported = await auth.isDeviceSupported();
      final bool canCheck = await auth.canCheckBiometrics;
      final available = await auth.getAvailableBiometrics();
      if (!isSupported || !canCheck || available.isEmpty) {
        _show(_isArabic ? 'الجهاز لا يدعم البصمة' : 'Biometrics not supported');
        return;
      }
      final didAuth = await auth.authenticate(
        localizedReason: _isArabic ? 'ضع بصمتك للدخول' : 'Please authenticate to login',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      if (didAuth) {
        final user = sb.auth.currentUser;
        if (user != null) {
          if (mounted) Navigator.pushReplacementNamed(context, '/home');
        } else {
          _show(_isArabic ? 'سجّل دخول مرة بالبريد لربط البصمة' : 'Sign in once to bind biometrics');
        }
      }
    } on PlatformException catch (e) {
      _show('Error: ${e.message}');
    }
  }

  // ============== Google (Supabase OAuth) ==============
  Future<void> _googleLogin() async {
    try {
      setState(() {
        _isLoading = true;
        _isLocked = true;
      });

      await sb.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _oauthRedirect,
      );
    } catch (e) {
      _show(_isArabic ? "فشل تسجيل الدخول عبر Google: $e" : "Google login failed: $e");
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLocked = false;
      });
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();

    if (!RegExp(r"^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(email)) {
      _show(_isArabic ? 'أدخل بريدك الإلكتروني أولاً' : 'Enter your email first');
      return;
    }

    setState(() {
      _isLoading = true;
      _isLocked = true;
    });

    try {
      await sb.auth.resetPasswordForEmail(
        email,
        redirectTo: _oauthRedirect,
      );
      _show(_isArabic ? 'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك' : 'Password reset link sent to your email');
    } catch (e) {
      _show(_isArabic ? 'فشل إرسال رابط إعادة التعيين: $e' : 'Failed to send reset link: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLocked = false;
      });
    }
  }

  void _toggleLanguage() => setState(() => _isArabic = !_isArabic);

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Scaffold(
          backgroundColor: _background,
          body: Stack(
            children: [
              _buildBackground(),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(onPressed: _toggleLanguage, icon: Icon(Icons.language, color: _accent)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildHexLogo(),
                      const SizedBox(height: 30),
                      _buildTextFields(),
                      const SizedBox(height: 20),
                      _buildActionButtons(),
                      const SizedBox(height: 14),
                      _buildSocialLogin(),
                      const SizedBox(height: 14),
                      _buildBiometricLogin(),
                    ],
                  ),
                ),
              ),
              if (_isLoading) _buildLoadingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() => Positioned.fill(child: Container(color: _background));

  Widget _buildHexLogo() {
    return ScaleTransition(
      scale: _logoAnimation,
      child: Column(
        children: [
          _HexBadge(
            size: 130,
            lineColor: _accent.withOpacity(0.25),
            glowColor: _accent.withOpacity(0.25),
            child: Icon(Icons.security_rounded, size: 52, color: _accent),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                final shimmerPos = (_shimmerController.value * 3) - 1;
                return ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      begin: Alignment(-1 - shimmerPos, 0),
                      end: Alignment(1 - shimmerPos, 0),
                      colors: [Colors.transparent, Colors.white.withOpacity(0.85), Colors.transparent],
                      stops: const [0.0, 0.5, 1.0],
                    ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height));
                  },
                  blendMode: BlendMode.srcATop,
                  child: Text(
                    "CyberBreif",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _accent,
                      letterSpacing: 0.6,
                      shadows: const [Shadow(color: Colors.white24, blurRadius: 8)],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFields() => Column(
        children: [
          TextField(
            controller: _emailController,
            decoration: _inputDecoration(
              hint: _isArabic ? "اسم المستخدم أو الإيميل" : "Username or Email",
              icon: Icons.person_outline,
              suffix: _isEmailValid ? const Icon(Icons.check_circle, color: Colors.lightGreenAccent) : null,
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: _inputDecoration(hint: _isArabic ? "كلمة المرور" : "Password", icon: Icons.lock_outline),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      );

  InputDecoration _inputDecoration({required String hint, required IconData icon, Widget? suffix}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white60),
      prefixIcon: Icon(icon, color: Colors.white70),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _border.withOpacity(0.45)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _border.withOpacity(0.45)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _accent),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 6,
                ),
                onPressed: _login,
                child: Text(
                  _isArabic ? "تسجيل الدخول" : "Login",
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
              child: Text(_isArabic ? "إنشاء حساب" : "Sign Up"),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _forgotPassword,
            child: Text(
              _isArabic ? 'نسيت كلمة المرور؟' : 'Forgot Password?',
              style: const TextStyle(color: Colors.white, fontSize: 12.5),
            ),
          ),
        ),
      ],
    );
  }

  // ===== Quick login buttons =====
  Widget _buildSocialLogin() => _buildQuickLoginButton(
        onTap: _googleLogin,
        title: _isArabic ? "تسجيل الدخول باستخدام Google" : "Login with Google",
        icon: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: _accent.withOpacity(0.10),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Image.network(
               'https://developers.google.com/identity/images/g-logo.png',
                width: 22,
                height: 22,
                errorBuilder: (context, error, stackTrace) {
                return const _GoogleLogo(size: 24);
                    },
           ),
        ),
        borderColor: _accentDeep.withOpacity(0.52),
        glowColor: _accentDeep.withOpacity(0.12),
        arrowColor: _accent,
      );

  Widget _buildBiometricLogin() => _buildQuickLoginButton(
        onTap: _authenticate,
        title: _isArabic ? "تسجيل الدخول بالبصمة" : "Login with Fingerprint",
        icon: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _accent.withOpacity(0.24),
                _accentDeep.withOpacity(0.20),
              ],
            ),
            border: Border.all(color: _accent.withOpacity(0.45)),
          ),
          child: Icon(Icons.fingerprint_rounded, color: _accent, size: 25),
        ),
        borderColor: _accent.withOpacity(0.48),
        glowColor: _accent.withOpacity(0.13),
        arrowColor: _accentDeep,
      );

  Widget _buildQuickLoginButton({
    required VoidCallback onTap,
    required String title,
    required Widget icon,
    required Color borderColor,
    required Color glowColor,
    required Color arrowColor,
  }) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.075),
            Colors.white.withOpacity(0.035),
          ],
        ),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                icon,
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: arrowColor.withOpacity(0.12),
                    border: Border.all(color: arrowColor.withOpacity(0.28)),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: arrowColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() => Container(
        color: Colors.black54,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: _accent),
            const SizedBox(height: 12),
            Text(_isArabic ? 'جارِ التحميل...' : 'Loading...', style: const TextStyle(color: Colors.white)),
          ]),
        ),
      );

  void _show(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}


class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.16;
    final rect = Rect.fromLTWH(stroke, stroke, size.width - stroke * 2, size.height - stroke * 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.20, 1.25, false, paint);

    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 1.05, 1.15, false, paint);

    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.20, 1.05, false, paint);

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 3.25, 1.25, false, paint);

    final linePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.square;

    final y = size.height * 0.52;
    canvas.drawLine(Offset(size.width * 0.52, y), Offset(size.width * 0.86, y), linePaint);
    canvas.drawLine(Offset(size.width * 0.86, y), Offset(size.width * 0.86, size.height * 0.67), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/*======================== Hex Badge ========================*/
class _HexBadge extends StatelessWidget {
  const _HexBadge({
    required this.child,
    required this.size,
    this.lineColor = const Color(0x3321D4FD),
    this.glowColor = const Color(0x3321D4FD),
  });

  final Widget child;
  final double size;
  final Color lineColor;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: Size(size, size), painter: _HexOutlinePainter(lineColor)),
          Container(
            width: size * .60,
            height: size * .60,
            decoration: BoxDecoration(
              color: glowColor.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: lineColor.withOpacity(0.7)),
              boxShadow: [BoxShadow(color: glowColor, blurRadius: 24, spreadRadius: 2)],
            ),
            child: Center(child: child),
          ),
        ],
      ),
    );
  }
}

class _HexOutlinePainter extends CustomPainter {
  _HexOutlinePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final r = size.width / 2 * 0.9;
    final cx = size.width / 2;
    final cy = size.height / 2;

    for (int i = 0; i < 6; i++) {
      final angle = (60.0 * i - 30) * math.pi / 180.0;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
