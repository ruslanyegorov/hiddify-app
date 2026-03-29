import 'package:flutter/material.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/kolobok/api_service.dart';
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
    return FutureBuilder<Map<String, dynamic>>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }
        final raw = snapshot.data!;
        final user = (raw['user'] is Map) ? (raw['user'] as Map).cast<String, dynamic>() : raw;
        final username = user['username']?.toString() ?? user['name']?.toString() ?? '-';
        final email = user['email']?.toString() ?? '-';
        final referral = user['referral_link']?.toString() ?? user['referral']?.toString() ?? '-';

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Профиль', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('Имя: $username'),
                  const SizedBox(height: 4),
                  Text('Email: $email'),
                  const SizedBox(height: 10),
                  Text('Реферальная ссылка:\n$referral'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () async {
                await widget.apiService.clearToken();
                if (ref.read(connectionNotifierProvider).value == const Connected()) {
                  await ref.read(connectionNotifierProvider.notifier).toggleConnection();
                }
                if (!mounted) return;
                widget.onLogout();
              },
              child: const Text('Выйти'),
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
