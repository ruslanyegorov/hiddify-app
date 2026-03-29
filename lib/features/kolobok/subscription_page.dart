import 'package:flutter/material.dart';
import 'package:hiddify/features/kolobok/api_service.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key, required this.apiService});

  final ApiService apiService;

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  late Future<({Map<String, dynamic> subscription, List<Map<String, dynamic>> plans})> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({Map<String, dynamic> subscription, List<Map<String, dynamic>> plans})>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }
        final subscription = snapshot.data!.subscription;
        final plans = snapshot.data!.plans;
        final expiresAt = subscription['expires_at']?.toString() ?? subscription['active_until']?.toString() ?? '-';

        return RefreshIndicator(
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
                    const Text('Текущая подписка', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Активна до: $expiresAt'),
                    Text('Статус: ${subscription['status'] ?? 'unknown'}'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text('Тарифы', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              ...plans.map((plan) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _panel(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan['name']?.toString() ?? 'План',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(plan['description']?.toString() ?? ''),
                          ],
                        ),
                      ),
                      Text(plan['price']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7B2FBE)),
                        onPressed: () {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(const SnackBar(content: Text('Оплата будет подключена позже')));
                        },
                        child: const Text('Оплатить'),
                      ),
                    ],
                  ),
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  Future<({Map<String, dynamic> subscription, List<Map<String, dynamic>> plans})> _load() async {
    final subscription = await widget.apiService.getSubscription();
    final plans = await widget.apiService.getPlans();
    return (subscription: subscription, plans: plans);
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
