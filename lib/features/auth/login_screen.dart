import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/session/session_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    final error = await AuthService().signInWithGoogle();
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFF9B2020),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final role = SessionManager().currentRole;
    if (role == 'Admin' || role == 'Super Admin') {
      context.go('/dashboard');
    } else {
      context.go('/select-building');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EC),
      body: Stack(
        children: [
          // ── Decorative blobs ─────────────────────────────────────────
          Positioned(
            top: -80,
            right: -60,
            child: _Blob(size: 260, color: const Color(0xFFDDD0B8).withValues(alpha: 0.45)),
          ),
          Positioned(
            bottom: size.height * 0.08,
            left: -70,
            child: _Blob(size: 220, color: const Color(0xFFC5D3BE).withValues(alpha: 0.38)),
          ),
          Positioned(
            top: size.height * 0.42,
            right: -40,
            child: _Blob(size: 130, color: const Color(0xFFE8D0C0).withValues(alpha: 0.5)),
          ),
          Positioned(
            top: size.height * 0.22,
            left: -20,
            child: _Blob(size: 80, color: const Color(0xFFF0E4D0).withValues(alpha: 0.6)),
          ),

          // ── Main layout ───────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: size.height - MediaQuery.of(context).padding.top,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 28),

                          // ── Top bar ───────────────────────────────────
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3D2F),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Icon(
                                  Icons.business_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 11),
                              const Flexible(
                                child: Text(
                                  'FacilityPro',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1714),
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 13, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3D2F).withValues(alpha: 0.09),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Enterprise',
                                  style: TextStyle(
                                    color: Color(0xFF1E3D2F),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 56),

                          // ── Headline ──────────────────────────────────
                          const Text(
                            'Welcome\nback.',
                            style: TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1714),
                              height: 1.05,
                              letterSpacing: -2.0,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Sign in with your organisation Google account\nto manage your facilities seamlessly.',
                            style: TextStyle(
                              fontSize: 14.5,
                              color: Color(0xFF8C8278),
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 52),

                          // ── Continue with Google button ───────────────
                          GestureDetector(
                            onTap: _isLoading ? null : _signInWithGoogle,
                            child: Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFDDD5C8),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1A1714).withValues(alpha: 0.06),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: _isLoading
                                  ? const Center(
                                      child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF1E3D2F),
                                        ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _GoogleLogo(),
                                        const SizedBox(width: 12),
                                        const Flexible(
                                          child: Text(
                                            'Continue with Google',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1A1714),
                                              letterSpacing: 0.1,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // ── Divider ───────────────────────────────────
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: const Color(0xFFDDD5C8),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  'Secure access',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFAA9F94),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: const Color(0xFFDDD5C8),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // ── Trust badges ──────────────────────────────
                          Row(
                            children: [
                              _TrustBadge(
                                icon: Icons.shield_outlined,
                                text: 'SSL Encrypted',
                              ),
                              const SizedBox(width: 12),
                              _TrustBadge(
                                icon: Icons.verified_user_outlined,
                                text: 'SOC 2 Compliant',
                              ),
                              const SizedBox(width: 12),
                              _TrustBadge(
                                icon: Icons.lock_clock_outlined,
                                text: '2FA Ready',
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // ── Account not set up info ───────────────────
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEE8DF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 16,
                                  color: Color(0xFF8C8278),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Access is granted by your administrator. Use your company Google account to sign in.',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF6B6560),
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // ── Footer ────────────────────────────────────
                          Center(
                            child: Text(
                              '© 2025 FacilityPro Inc.  ·  v4.2.1',
                              style: TextStyle(
                                fontSize: 11,
                                color: const Color(0xFF8C8278).withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Google Logo ───────────────────────────────────────────────────────────────

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Clip to circle
    canvas.clipRect(Rect.fromCircle(center: center, radius: radius));

    final paint = Paint()..style = PaintingStyle.fill;

    // Draw the four colored arcs of the Google G
    // Blue segment (top)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57, 1.0,
      true,
      paint,
    );

    // Red segment (top-left)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -2.62, 1.05,
      true,
      paint,
    );

    // Yellow segment (bottom-left)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      1.57, 1.05,
      true,
      paint,
    );

    // Green segment (bottom-right)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0.52, 1.05,
      true,
      paint,
    );

    // White inner circle
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.58, paint);

    // Blue right bar of G
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(center.dx - 0.5, center.dy - radius * 0.2, radius * 0.95, radius * 0.4),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Decorative Blob ──────────────────────────────────────────────────────────

class _Blob extends StatelessWidget {
  final double size;
  final Color color;

  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

// ── Trust Badge ──────────────────────────────────────────────────────────────

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TrustBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEEE8DF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF5A7A65)),
            const SizedBox(height: 5),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B6560),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
