import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _kAccent = Color(0xFFF5A623);

class KolobokAboutScreen extends StatelessWidget {
  const KolobokAboutScreen({super.key, this.ru = true});

  final bool ru;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF222222)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          ru ? 'О приложении' : 'About',
          style: const TextStyle(
            color: Color(0xFF222222),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: _kAccent,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Image.asset('assets/images/icon.png', height: 80),
                const SizedBox(height: 16),
                const Text(
                  'KOLOBOK VPN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ru ? 'Версия 1.0.0' : 'Version 1.0.0',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Roll Free. Stay Private.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.public_rounded, color: _kAccent),
                  title: Text(
                    ru ? 'Веб-сайт' : 'Website',
                    style: const TextStyle(color: Color(0xFF222222)),
                  ),
                  subtitle: const Text(
                    'kolobokvpn.com',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFCCCCCC)),
                  onTap: () => launchUrl(Uri.parse('https://kolobokvpn.com')),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.telegram, color: _kAccent),
                  title: const Text('Telegram', style: TextStyle(color: Color(0xFF222222))),
                  subtitle: const Text(
                    '@kolobokvpn',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFCCCCCC)),
                  onTap: () => launchUrl(Uri.parse('https://t.me/kolobokvpn')),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: _kAccent),
                  title: Text(
                    ru ? 'Политика конфиденциальности' : 'Privacy Policy',
                    style: const TextStyle(color: Color(0xFF222222)),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFCCCCCC)),
                  onTap: () => launchUrl(Uri.parse('https://kolobokvpn.com/privacy')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            ru
                ? '© 2025 Kolobok VPN. Все права защищены.'
                : '© 2025 Kolobok VPN. All rights reserved.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
