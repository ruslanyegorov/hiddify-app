import 'package:flutter/material.dart';
import 'package:hiddify/features/kolobok/api_service.dart';
import 'package:hiddify/features/kolobok/language_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

const Color _kTextPrimary = Color(0xFF333333);
const Color _kTextHeading = Color(0xFF1A1A2E);
const Color _kPayOrange = Color(0xFFF5A623);

// Константы цен
const String _kPriceRub = '199 ₽/мес';
const String _kPriceUsdt = '≈ 2.20 USDT/мес';

class SubscriptionPage extends ConsumerStatefulWidget {
  const SubscriptionPage({super.key, required this.apiService});

  final ApiService apiService;

  @override
  ConsumerState<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends ConsumerState<SubscriptionPage> {
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    await initializeDateFormatting('ru');
    await initializeDateFormatting('en');
    return widget.apiService.getSubscription();
  }

  String _formatExpiresAt(String raw, String language) {
    if (raw.isEmpty || raw == '-') {
      return raw;
    }
    final dt = DateTime.tryParse(raw);
    if (dt == null) {
      return raw;
    }
    final loc = language == 'en' ? 'en' : 'ru';
    return DateFormat('d MMMM yyyy', loc).format(dt.toLocal());
  }

  bool _subscriptionLooksPresent(Map<String, dynamic> subscription) {
    final exp = subscription['expires_at'] ?? subscription['active_until'];
    if (exp == null) {
      return false;
    }
    final s = exp.toString().trim();
    if (s.isEmpty || s == '-') {
      return false;
    }
    return DateTime.tryParse(s) != null || s.length > 4;
  }

  String _statusLine(Map<String, dynamic> subscription, String language) {
    final raw = subscription['status']?.toString().trim().toLowerCase() ?? '';
    final hasSub = _subscriptionLooksPresent(subscription);
    final active = language == 'en' ? 'Status: Active' : 'Статус: Активна';
    final dash = language == 'en' ? 'Status: —' : 'Статус: —';
    if (raw.isEmpty || raw == 'unknown') {
      return hasSub ? active : dash;
    }
    final prefix = language == 'en' ? 'Status: ' : 'Статус: ';
    return '$prefix${subscription['status']}';
  }

  String _priceLine(String language) {
    return language == 'en' ? _kPriceUsdt : _kPriceRub;
  }

  String _planDescription(String language) {
    return language == 'en' ? '1 month • 3 devices' : '1 месяц • 3 устройства';
  }

  String _currentSubscriptionTitle(String language) {
    return language == 'en' ? 'Current subscription' : 'Текущая подписка';
  }

  String _activeUntilLabel(String language) {
    return language == 'en' ? 'Active until: ' : 'Активна до: ';
  }

  String _tariffTitle(String language) {
    return language == 'en' ? 'Plan' : 'Тариф';
  }

  String _payLabel(String language) {
    return language == 'en' ? 'Subscribe' : 'Оплатить';
  }

  String _snackMessage(String language) {
    return language == 'en' ? 'Payment will be available soon' : 'Оплата будет подключена позже';
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(kolobokLanguageProvider);
    return FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              language == 'en' ? 'Error: ${snapshot.error}' : 'Ошибка: ${snapshot.error}',
              style: const TextStyle(color: _kTextPrimary),
              textAlign: TextAlign.center,
            ),
          );
        }
        final subscription = snapshot.data!;
        final expiresRaw = subscription['expires_at']?.toString() ?? subscription['active_until']?.toString() ?? '-';
        final expiresFormatted = _formatExpiresAt(expiresRaw, language);

        return RefreshIndicator(
          color: _kPayOrange,
          onRefresh: () async {
            setState(() => _dataFuture = _load());
            await _dataFuture;
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentSubscriptionTitle(language),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _kTextHeading,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_activeUntilLabel(language)}$expiresFormatted',
                      style: const TextStyle(color: _kTextPrimary, fontSize: 14),
                    ),
                    Text(
                      _statusLine(subscription, language),
                      style: const TextStyle(color: _kTextPrimary, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _tariffTitle(language),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _kTextHeading,
                ),
              ),
              const SizedBox(height: 8),
              _panel(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _priceLine(language),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              color: _kTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _planDescription(language),
                            style: const TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPayOrange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(_snackMessage(language))),
                        );
                      },
                      child: Text(_payLabel(language)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _panel({required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(14)}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
