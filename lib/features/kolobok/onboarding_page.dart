import 'package:flutter/material.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class KolobokOnboardingPage extends ConsumerStatefulWidget {
  const KolobokOnboardingPage({super.key});

  @override
  ConsumerState<KolobokOnboardingPage> createState() => _KolobokOnboardingPageState();
}

class _KolobokOnboardingPageState extends ConsumerState<KolobokOnboardingPage> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      icon: Icons.shield_rounded,
      title: 'Безопасно и надёжно',
      subtitle: 'Шифрование военного уровня\nзащитит ваши данные в сети',
    ),
    _Slide(
      icon: Icons.public_rounded,
      title: 'Серверы по всему миру',
      subtitle: 'Подключайтесь к серверам\nв разных странах мира',
    ),
    _Slide(
      icon: Icons.support_agent_rounded,
      title: 'Поддержка 24/7',
      subtitle: 'Мы всегда готовы помочь вам\nв любое время',
    ),
  ];

  Future<void> _complete() async {
    await ref.read(Preferences.introCompleted.notifier).update(true);
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: TextButton(
                  onPressed: _complete,
                  child: const Text(
                    'Пропустить',
                    style: TextStyle(color: Color(0xFF999999), fontSize: 14),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => _SlidePage(slide: _slides[i]),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _page ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _page
                        ? const Color(0xFFF5A623)
                        : const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A623),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _page == _slides.length - 1 ? 'Начать' : 'Далее',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

class _SlidePage extends StatelessWidget {
  const _SlidePage({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF3E0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              slide.icon,
              size: 90,
              color: const Color(0xFFF5A623),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF5A623),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF666666),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
