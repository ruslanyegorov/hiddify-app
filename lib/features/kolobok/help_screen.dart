import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _kAccent = Color(0xFFF5A623);

class KolobokHelpScreen extends StatelessWidget {
  const KolobokHelpScreen({super.key, this.ru = true});

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
          ru ? 'Помощь' : 'Help',
          style: const TextStyle(
            color: Color(0xFF222222),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _faqSection(ru),
          const SizedBox(height: 16),
          _contactSection(context, ru),
        ],
      ),
    );
  }

  Widget _faqSection(bool ru) {
    final items = ru
        ? [
            ('Как подключиться?', 'Выберите страну на главном экране и нажмите кнопку питания.'),
            ('Сколько устройств можно подключить?', 'К одному аккаунту можно привязать до 2 устройств.'),
            ('Что делать если нет подключения?', 'Попробуйте сменить страну или перезапустить приложение.'),
            ('Как продлить подписку?', 'Перейдите в раздел "Подписка" и выберите нужный тариф.'),
          ]
        : [
            ('How to connect?', 'Select a country on the home screen and tap the power button.'),
            ('How many devices can I use?', 'You can link up to 2 devices per account.'),
            ('What if connection fails?', 'Try changing the country or restarting the app.'),
            ('How to renew subscription?', 'Go to "Subscription" and choose a plan.'),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            ru ? 'Частые вопросы' : 'FAQ',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
            ),
          ),
        ),
        ...items.map((item) => _FaqTile(question: item.$1, answer: item.$2)),
      ],
    );
  }

  Widget _contactSection(BuildContext context, bool ru) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.telegram, color: _kAccent),
            title: Text(
              ru ? 'Написать в Telegram' : 'Contact via Telegram',
              style: const TextStyle(color: Color(0xFF222222)),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFCCCCCC)),
            onTap: () => launchUrl(Uri.parse('https://t.me/kolobokvpn')),
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: const Icon(Icons.email_outlined, color: _kAccent),
            title: Text(
              ru ? 'Написать на email' : 'Send email',
              style: const TextStyle(color: Color(0xFF222222)),
            ),
            subtitle: const Text(
              'support@kolobokvpn.com',
              style: TextStyle(color: Color(0xFF888888), fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFCCCCCC)),
            onTap: () => launchUrl(Uri.parse('mailto:support@kolobokvpn.com')),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          widget.question,
          style: const TextStyle(
            color: Color(0xFF222222),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          _expanded ? Icons.expand_less : Icons.expand_more,
          color: _kAccent,
        ),
        onExpansionChanged: (v) => setState(() => _expanded = v),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              widget.answer,
              style: const TextStyle(color: Color(0xFF666666), fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
