import 'package:flutter/material.dart';
import 'package:hiddify/features/kolobok/language_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const Color _kAccent = Color(0xFFF5A623);

class KolobokSettingsScreen extends ConsumerWidget {
  const KolobokSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(kolobokLanguageProvider);
    final ru = lang != 'en';

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
          ru ? 'Настройки' : 'Settings',
          style: const TextStyle(
            color: Color(0xFF222222),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            children: [
              _SettingRow(
                icon: Icons.language_rounded,
                title: ru ? 'Язык' : 'Language',
                trailing: DropdownButton<String>(
                  value: lang == 'en' ? 'en' : 'ru',
                  underline: const SizedBox(),
                  style: const TextStyle(color: Color(0xFF333333), fontSize: 15),
                  dropdownColor: Colors.white,
                  items: const [
                    DropdownMenuItem(
                      value: 'ru',
                      child: Text('Русский', style: TextStyle(color: Color(0xFF333333))),
                    ),
                    DropdownMenuItem(
                      value: 'en',
                      child: Text('English', style: TextStyle(color: Color(0xFF333333))),
                    ),
                  ],
                  onChanged: (val) async {
                    if (val == null) return;
                    await ref.read(kolobokLanguageProvider.notifier).setLanguage(val);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: _kAccent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Color(0xFF222222), fontSize: 15),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
