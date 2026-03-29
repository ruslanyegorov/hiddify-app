import 'package:flutter/material.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/kolobok/api_service.dart';
import 'package:hiddify/features/kolobok/language_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class KolobokProfilePage extends ConsumerStatefulWidget {
  const KolobokProfilePage({super.key, required this.apiService, required this.onLogout});

  final ApiService apiService;
  final VoidCallback onLogout;

  @override
  ConsumerState<KolobokProfilePage> createState() => _KolobokProfilePageState();
}

class _KolobokProfilePageState extends ConsumerState<KolobokProfilePage> {
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = widget.apiService.getProfile();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(kolobokLanguageProvider);
    final ru = lang != 'en';

    return FutureBuilder<Map<String, dynamic>>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              ru ? 'Ошибка: ${snapshot.error}' : 'Error: ${snapshot.error}',
              style: const TextStyle(color: Color(0xFF333333)),
              textAlign: TextAlign.center,
            ),
          );
        }
        final raw = snapshot.data!;
        final user = (raw['user'] is Map) ? (raw['user'] as Map).cast<String, dynamic>() : raw;
        final username = user['username']?.toString() ?? user['name']?.toString() ?? '-';
        final email = user['email']?.toString() ?? '-';

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ru ? 'Профиль' : 'Profile',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    ru ? 'Имя: $username' : 'Name: $username',
                    style: const TextStyle(color: Color(0xFF333333)),
                  ),
                  const SizedBox(height: 4),
                  Text('Email: $email', style: const TextStyle(color: Color(0xFF333333))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ru ? 'Язык' : 'Language',
                  style: const TextStyle(color: Color(0xFF333333)),
                ),
                DropdownButton<String>(
                  value: lang == 'en' ? 'en' : 'ru',
                  style: const TextStyle(color: Color(0xFF333333), fontSize: 16),
                  dropdownColor: Colors.white,
                  items: const [
                    DropdownMenuItem(value: 'ru', child: Text('Русский', style: TextStyle(color: Color(0xFF333333)))),
                    DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(color: Color(0xFF333333)))),
                  ],
                  onChanged: (val) async {
                    if (val == null) return;
                    await ref.read(kolobokLanguageProvider.notifier).setLanguage(val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF5A623),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await widget.apiService.clearToken();
                if (ref.read(connectionNotifierProvider).value == const Connected()) {
                  await ref.read(connectionNotifierProvider.notifier).toggleConnection();
                }
                if (!mounted) return;
                widget.onLogout();
              },
              child: Text(ru ? 'Выйти' : 'Log out'),
            ),
          ],
        );
      },
    );
  }

  Widget _panel({required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }
}
