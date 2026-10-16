import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 2400);
  late final AnimationController _controller;
  late final Animation<double> _drawAnim;
  late final Animation<double> _textAnim;
  ProviderSubscription<AuthState>? _authSubscription;
  bool _animationDone = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration)
      ..forward();
    _drawAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.7, curve: Curves.easeInOut),
    );
    _textAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 1, curve: Curves.easeIn),
    );

    _authSubscription = ref.listenManual<AuthState>(
      authStateProvider,
      (_, _) => _navigate(),
    );

    _controller.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _animationDone = true;
          _navigate();
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.close();
    _controller.dispose();
    super.dispose();
  }

  void _navigate() {
    if (!mounted || _navigated || !_animationDone) return;

    final auth = ref.read(authStateProvider);
    if (auth.bootstrapping) return;

    _navigated = true;
    if (auth.isLoggedIn) {
      if (auth.role == 'admin') {
        context.go('/admin');
      } else if (auth.role == 'employee') {
        context.go('/employee/completed-movements');
      } else if (auth.role == 'staff') {
        context.go('/staff/home');
      } else {
        context.go('/home');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    const gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF79B8C8), Color(0xFF0D6C86)],
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 260,
              height: 240,
              child: AnimatedBuilder(
                animation: _drawAnim,
                builder: (_, _) => CustomPaint(
                  painter: _GlassPainter(
                    progress: _drawAnim.value,
                    gradient: gradient,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _textAnim,
              child: Column(
                children: [
                  ShaderMask(
                    shaderCallback: (b) => gradient.createShader(b),
                    child: const Text(
                      'AMED',
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  ShaderMask(
                    shaderCallback: (b) => gradient.createShader(b),
                    child: const Text(
                      'GLASS',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 8,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassPainter extends CustomPainter {
  final double progress;
  final LinearGradient gradient;

  _GlassPainter({required this.progress, required this.gradient});

  static const _viewBoxWidth = 600.0;
  static const _viewBoxHeight = 560.0;

  static final List<List<Offset>> _shapes = [
    [
      const Offset(70, 130),
      const Offset(70, 410),
      const Offset(140, 395),
      const Offset(140, 145),
    ],
    [
      const Offset(120, 80),
      const Offset(120, 460),
      const Offset(200, 440),
      const Offset(200, 100),
    ],
    [
      const Offset(200, 50),
      const Offset(570, 180),
      const Offset(570, 450),
      const Offset(200, 530),
    ],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.width / _viewBoxWidth).clamp(
      0.0,
      size.height / _viewBoxHeight,
    );
    final offsetX = (size.width - _viewBoxWidth * scale) / 2;
    final offsetY = (size.height - _viewBoxHeight * scale) / 2;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = gradient.createShader(
        const Rect.fromLTWH(0, 0, _viewBoxWidth, _viewBoxHeight),
      );

    final fullPath = Path();
    for (final pts in _shapes) {
      fullPath.moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        fullPath.lineTo(pts[i].dx, pts[i].dy);
      }
      fullPath.close();
    }

    final animatedPath = Path();
    for (final metric in fullPath.computeMetrics()) {
      animatedPath.addPath(
        metric.extractPath(0, metric.length * progress),
        Offset.zero,
      );
    }

    canvas.drawPath(animatedPath, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GlassPainter old) =>
      old.progress != progress || old.gradient != gradient;
}
