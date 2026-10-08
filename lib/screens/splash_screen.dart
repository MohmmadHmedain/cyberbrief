import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'login_screen.dart'; // عدل المسار حسب مشروعك

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool animate = false;

  late AnimationController _fadeController;
  late Animation<double> _fade;

  // 🔤 أنيميشن كتابة
  late AnimationController _typeController;
  String displayedText1 = "";
  String displayedText2 = "";

  final String fullText1 = "Welcome to CyberGuard!";
  final String fullText2 = "Your all-in-one solution To protect\nyour device from threats";

  @override
  void initState() {
    super.initState();

    // Fade بسيط للشاشة
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    // كتابة النصوص تدريجيًا
    _typeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addListener(_updateTyping);

    Future.delayed(const Duration(milliseconds: 800), () {
      _typeController.forward();
    });

    // تكبير الشعار
    Future.delayed(Duration.zero, () => setState(() => animate = true));

    // بعد 6 ثوانٍ ننتقل للـ Login
    Future.delayed(const Duration(seconds: 6), () {
      if (!mounted) return;
      _goToLoginClean();
    });
  }

  void _updateTyping() {
    final progress = _typeController.value;
    final totalChars = fullText1.length + fullText2.length;
    final current = (progress * totalChars).floor();

    if (current <= fullText1.length) {
      displayedText1 = fullText1.substring(0, current);
      displayedText2 = "";
    } else {
      displayedText1 = fullText1;
      final secondCount = current - fullText1.length;
      displayedText2 = fullText2.substring(0, math.min(secondCount, fullText2.length));
    }
    setState(() {});
  }

  void _goToLoginClean() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 650),
        pageBuilder: (context, animation, _) => const LoginScreen(),
        transitionsBuilder: (context, animation, _, child) {
          final slideIn = Tween<Offset>(
            begin: const Offset(0, 0.10),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation);

          final fadeIn = Tween<double>(begin: 0, end: 1)
              .chain(CurveTween(curve: Curves.easeOut))
              .animate(animation);

          return SlideTransition(
            position: slideIn,
            child: FadeTransition(opacity: fadeIn, child: child),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _SplashContent(
        fade: _fade,
        animate: animate,
        text1: displayedText1,
        text2: displayedText2,
      ),
    );
  }
}

/*======================== واجهة السبلـاش ========================*/
class _SplashContent extends StatelessWidget {
  const _SplashContent({
    required this.fade,
    required this.animate,
    required this.text1,
    required this.text2,
  });

  final Animation<double> fade;
  final bool animate;
  final String text1;
  final String text2;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/icon/photo_2025-10-28_21-51-51.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(color: Colors.black.withOpacity(0.45)),

          Center(
            child: FadeTransition(
              opacity: fade,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // الشعار السداسي
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOut,
                    transform: Matrix4.identity()..scale(animate ? 1.0 : 0.85),
                    child: const _HexBadge(
                      size: 140,
                      child: Icon(
                        Icons.security_rounded,
                        size: 56,
                        color: Color(0xFF67C9E6),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // النصوص بأنيميشن الكتابة
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: Column(
                      children: [
                        Text(
                          text1,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          text2,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14.5,
                            height: 1.5,
                            color: Color(0xFF9EB0D0),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MiniBubble(icon: Icons.vpn_lock_rounded),
                      SizedBox(width: 22),
                      _MiniBubble(icon: Icons.shield_moon_rounded),
                      SizedBox(width: 22),
                      _MiniBubble(icon: Icons.phishing_rounded),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 110,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0x1A21D4FD), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/*======================== Widgets مساعدة ========================*/
class _MiniBubble extends StatelessWidget {
  const _MiniBubble({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0x2221D4FD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x3321D4FD)),
      ),
      child: Icon(icon, size: 18, color: const Color(0xFF67C9E6)),
    );
  }
}

class _HexBadge extends StatelessWidget {
  const _HexBadge({required this.child, required this.size});
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: Size(size, size), painter: _HexOutlinePainter()),
          Container(
            width: size * .60,
            height: size * .60,
            decoration: BoxDecoration(
              color: const Color(0x2221D4FD),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x4421D4FD)),
              boxShadow: const [
                BoxShadow(color: Color(0x3321D4FD), blurRadius: 24, spreadRadius: 2),
              ],
            ),
            child: Center(child: child),
          ),
        ],
      ),
    );
  }
}

class _HexOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x3321D4FD)
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
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
