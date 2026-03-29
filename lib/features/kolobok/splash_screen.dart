import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/features/kolobok/api_service.dart';

/// Точка входа: после анимации ведёт на `/home`.
/// Редирект GoRouter откроет intro при необходимости; при отсутствии токена [HomePage] покажет [AuthPage].
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const int _steps = 40;
  static const Duration _tick = Duration(milliseconds: 50);

  final ApiService _api = ApiService();
  double _progress = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_tick, (t) {
      if (!mounted) return;
      setState(() {
        _progress += 1 / _steps;
        if (_progress >= 1) {
          _progress = 1;
          t.cancel();
          _timer = null;
          unawaited(_finishAndNavigate());
        }
      });
    });
  }

  Future<void> _finishAndNavigate() async {
    await _api.getToken();
    if (!mounted) return;
    context.go('/home');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5A623),
      body: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Image.asset('assets/images/icon.png'),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'KOLOBOK VPN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Roll Free. Stay Private.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 48, left: 40, right: 40),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
