import 'package:flutter/material.dart';
import 'package:hiddify/features/kolobok/api_service.dart';
import 'package:hiddify/features/kolobok/language_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

const Color _kAccent = Color(0xFFF5A623);
const Color _kAccentDark = Color(0xFFE09015);

class SubscriptionPage extends ConsumerStatefulWidget {
  const SubscriptionPage({super.key, required this.apiService});

  final ApiService apiService;

  @override
  ConsumerState<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends ConsumerState<SubscriptionPage> {
  late Future<_SubData> _dataFuture;
  int? _selectedPlanId;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  Future<_SubData> _load() async {
    await initializeDateFormatting('ru');
    await initializeDateFormatting('en');
    final sub = await widget.apiService.getSubscription();
    List<Map<String, dynamic>> plans = [];
    try {
      plans = await widget.apiService.getPlans();
    } catch (_) {}
    return _SubData(subscription: sub, plans: plans);
  }

  String _formatDate(String raw, String lang) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final loc = lang == 'en' ? 'en' : 'ru';
    return DateFormat('d MMMM yyyy', loc).format(dt.toLocal());
  }

  int _daysLeft(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return 0;
    return dt.toLocal().difference(DateTime.now()).inDays.clamp(0, 99999);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(kolobokLanguageProvider);
    final ru = lang != 'en';

    return FutureBuilder<_SubData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: _kAccent));
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ru ? 'Ошибка загрузки' : 'Loading error',
                  style: const TextStyle(color: Color(0xFFC62828)),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => setState(() => _dataFuture = _load()),
                  style: ElevatedButton.styleFrom(backgroundColor: _kAccent),
                  child: Text(ru ? 'Повторить' : 'Retry',
                      style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data!;
        final sub = data.subscription;
        final plans = data.plans;
        final status = sub['status']?.toString() ?? 'none';
        final isActive = status == 'active';
        final expiresRaw = sub['expires_at']?.toString() ?? '';

        return RefreshIndicator(
          color: _kAccent,
          onRefresh: () async {
            setState(() => _dataFuture = _load());
            await _dataFuture;
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_kAccent, _kAccentDark],
                  stops: [0.0, 0.6],
                ),
              ),
              constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height - 130),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      ru ? 'Подписка' : 'Get Premium',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Features
                    _FeatureRow(
                      icon: Icons.devices_rounded,
                      title: ru ? 'Несколько устройств' : 'Multi-Device',
                      subtitle: ru ? 'До 2 устройств на аккаунт' : 'Use on up to 2 devices',
                    ),
                    const SizedBox(height: 10),
                    _FeatureRow(
                      icon: Icons.bolt_rounded,
                      title: ru ? 'Быстрое соединение' : 'Faster',
                      subtitle: ru ? 'Без ограничений скорости' : 'Unlimited bandwidth',
                    ),
                    const SizedBox(height: 10),
                    _FeatureRow(
                      icon: Icons.public_rounded,
                      title: ru ? 'Все серверы' : 'All Servers',
                      subtitle: ru ? 'Серверы по всему миру' : 'Servers in all countries',
                    ),

                    const SizedBox(height: 28),

                    // If active — show current info
                    if (isActive && expiresRaw.isNotEmpty) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ru ? 'Активная подписка' : 'Active Subscription',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  '${ru ? 'До:' : 'Until:'} ${_formatDate(expiresRaw, lang)}',
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.timer_outlined, color: Colors.white70, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  '${_daysLeft(expiresRaw)} ${ru ? 'дней осталось' : 'days left'}',
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        ru ? 'Продлить подписку' : 'Renew Subscription',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      Text(
                        ru ? 'Выберите тариф' : 'Select Your Subscription',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Plans list
                    if (plans.isEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          ru ? 'Тарифы недоступны' : 'No plans available',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      )
                    else
                      ...plans.map((plan) {
                        final id = plan['id'] is int
                            ? plan['id'] as int
                            : int.tryParse('${plan['id']}') ?? 0;
                        final name = plan['name']?.toString() ?? '';
                        final price = (plan['price'] as num?)?.toDouble() ?? 0.0;
                        final priceUsdt = (plan['price_usdt'] as num?)?.toDouble() ?? 0.0;
                        final duration = plan['duration_days'] is int
                            ? plan['duration_days'] as int
                            : int.tryParse('${plan['duration_days']}') ?? 30;
                        final selected = _selectedPlanId == id;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PlanTile(
                            name: name,
                            price: price,
                            priceUsdt: priceUsdt,
                            duration: duration,
                            selected: selected,
                            ru: ru,
                            onTap: () => setState(() => _selectedPlanId = id),
                          ),
                        );
                      }),

                    const SizedBox(height: 28),

                    // Subscribe button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _selectedPlanId == null
                            ? null
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ru
                                          ? 'Оплата будет доступна в ближайшее время'
                                          : 'Payment coming soon',
                                    ),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _kAccent,
                          disabledBackgroundColor: Colors.white.withValues(alpha: 0.4),
                          disabledForegroundColor: Colors.white70,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.workspace_premium_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              isActive
                                  ? (ru ? 'Продлить подписку' : 'Renew Subscription')
                                  : (ru ? 'Оформить подписку' : 'Get Premium'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
      ],
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.name,
    required this.price,
    required this.priceUsdt,
    required this.duration,
    required this.selected,
    required this.ru,
    required this.onTap,
  });

  final String name;
  final double price;
  final double priceUsdt;
  final int duration;
  final bool selected;
  final bool ru;
  final VoidCallback onTap;

  String get _durationLabel {
    if (duration <= 31) return ru ? '$duration дней' : '$duration days';
    if (duration <= 93) return ru ? '3 месяца' : '3 months';
    if (duration <= 185) return ru ? '6 месяцев' : '6 months';
    if (duration <= 370) return ru ? '1 год' : '1 year';
    return ru ? '2 года' : '2 years';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: selected
              ? Border.all(color: Colors.white, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isNotEmpty ? name : _durationLabel,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selected ? _kAccent : Colors.white,
                    ),
                  ),
                  if (priceUsdt > 0)
                    Text(
                      '≈ ${priceUsdt.toStringAsFixed(2)} USDT',
                      style: TextStyle(
                        fontSize: 11,
                        color: selected ? _kAccent.withValues(alpha: 0.7) : Colors.white60,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '${price.toStringAsFixed(0)} ₽',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: selected ? _kAccent : Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _kAccent : Colors.transparent,
                border: Border.all(
                  color: selected ? _kAccent : Colors.white60,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SubData {
  const _SubData({required this.subscription, required this.plans});

  final Map<String, dynamic> subscription;
  final List<Map<String, dynamic>> plans;
}
