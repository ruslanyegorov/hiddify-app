import 'package:flutter/material.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/home/widget/connection_button.dart';
import 'package:hiddify/features/kolobok/api_service.dart';
import 'package:hiddify/features/kolobok/auth_page.dart';
import 'package:hiddify/features/kolobok/profile_page.dart';
import 'package:hiddify/features/kolobok/subscription_page.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/overview/profiles_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ApiService _api = ApiService();
  int _tabIndex = 0;
  String? _selectedCountryKey;
  final Map<String, String> _countryProfileId = <String, String>{};

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _api.getToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final token = snapshot.data;
        if (token == null || token.isEmpty) {
          return AuthPage(
            onAuthenticated: () {
              if (!mounted) return;
              setState(() {});
            },
          );
        }
        return _buildMainShell();
      },
    );
  }

  Widget _buildMainShell() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Kolobok VPN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _HomeTab(
            apiService: _api,
            selectedCountryKey: _selectedCountryKey,
            onCountrySelected: _onCountrySelected,
          ),
          SubscriptionPage(apiService: _api),
          KolobokProfilePage(
            apiService: _api,
            onLogout: () {
              if (!mounted) return;
              setState(() {
                _tabIndex = 0;
                _selectedCountryKey = null;
                _countryProfileId.clear();
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (value) => setState(() => _tabIndex = value),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF7B2FBE).withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Главная'),
          NavigationDestination(icon: Icon(Icons.card_membership_outlined), selectedIcon: Icon(Icons.card_membership), label: 'Подписка'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }

  Future<void> _onCountrySelected(CountryNode node, String vlessConfig) async {
    final countryKey = node.key;
    _selectedCountryKey = countryKey;
    setState(() {});

    String? profileId = _countryProfileId[countryKey];
    if (profileId == null) {
      final before = await ref.read(profilesNotifierProvider.future);
      final beforeIds = before.map((e) => e.id).toSet();
      final repo = await ref.read(profileRepositoryProvider.future);
      final result = await repo.addLocal(vlessConfig).run();
      if (result.isLeft()) return;
      final after = await ref.read(profilesNotifierProvider.future);
      final created = after.where((e) => !beforeIds.contains(e.id)).toList();
      if (created.isNotEmpty) {
        profileId = created.first.id;
        _countryProfileId[countryKey] = profileId;
      }
    }
    if (profileId == null) return;

    await ref.read(profilesNotifierProvider.notifier).selectActiveProfile(profileId);
    await Future<void>.delayed(const Duration(milliseconds: 150));

    final status = ref.read(connectionNotifierProvider).valueOrNull;
    if (status == const Connected()) {
      final profile = await ref.read(activeProfileProvider.future);
      await ref.read(connectionNotifierProvider.notifier).reconnect(profile);
    } else if (status == const Disconnected()) {
      await ref.read(connectionNotifierProvider.notifier).mayConnect();
    }
  }
}

class _HomeTab extends ConsumerStatefulWidget {
  const _HomeTab({
    required this.apiService,
    required this.selectedCountryKey,
    required this.onCountrySelected,
  });

  final ApiService apiService;
  final String? selectedCountryKey;
  final Future<void> Function(CountryNode node, String vlessConfig) onCountrySelected;

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  late Future<({List<CountryNode> nodes, Map<String, String> configs})> _dataFuture;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({List<CountryNode> nodes, Map<String, String> configs})>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Ошибка загрузки: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
        }
        final nodes = snapshot.data!.nodes;
        final configs = snapshot.data!.configs;

        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _dataFuture = _load());
            await _dataFuture;
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 8),
              const Center(child: ConnectionButton()),
              const SizedBox(height: 20),
              const Text(
                'Выберите страну',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...nodes.map((node) {
                final selected = node.key == widget.selectedCountryKey;
                return _CountryCard(
                  node: node,
                  selected: selected,
                  loading: _actionLoading,
                  onTap: () async {
                    final config = configs[node.key];
                    if (config == null || config.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Нет конфига для страны ${node.name}')),
                      );
                      return;
                    }
                    setState(() => _actionLoading = true);
                    try {
                      await widget.onCountrySelected(node, config);
                    } finally {
                      if (mounted) setState(() => _actionLoading = false);
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<({List<CountryNode> nodes, Map<String, String> configs})> _load() async {
    final rawNodes = await widget.apiService.getNodes();
    final rawConfigs = await widget.apiService.getSubscriptionConfigs();
    final nodes = rawNodes.map(CountryNode.fromApi).toList();
    final configs = _parseConfigs(rawConfigs);
    return (nodes: nodes, configs: configs);
  }

  Map<String, String> _parseConfigs(Map<String, dynamic> raw) {
    final result = <String, String>{};
    final dynamic source = raw['data'] ?? raw['configs'] ?? raw;
    if (source is Map) {
      for (final entry in source.entries) {
        if (entry.value == null) continue;
        result[entry.key.toString().toLowerCase()] = entry.value.toString();
      }
    } else if (source is List) {
      for (final item in source.whereType<Map>()) {
        final map = item.cast<String, dynamic>();
        final key = (map['country_code'] ?? map['country'] ?? map['name'] ?? '').toString().toLowerCase();
        final config = (map['config'] ?? map['vless'] ?? map['url'] ?? '').toString();
        if (key.isNotEmpty && config.isNotEmpty) result[key] = config;
      }
    }
    return result;
  }
}

class _CountryCard extends StatelessWidget {
  const _CountryCard({
    required this.node,
    required this.selected,
    required this.loading,
    required this.onTap,
  });

  final CountryNode node;
  final bool selected;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: selected ? const Color(0xFF7B2FBE) : Colors.white.withValues(alpha: 0.95),
      child: ListTile(
        onTap: loading ? null : onTap,
        leading: Text(node.flag, style: const TextStyle(fontSize: 24)),
        title: Text(
          node.name,
          style: TextStyle(color: selected ? Colors.white : const Color(0xFF1A1A2E), fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Пинг: ${node.pingMs} ms',
          style: TextStyle(color: selected ? Colors.white70 : Colors.black54),
        ),
        trailing: selected
            ? const Icon(Icons.check_circle, color: Colors.white)
            : const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class CountryNode {
  CountryNode({
    required this.name,
    required this.code,
    required this.flag,
    required this.pingMs,
  });

  final String name;
  final String code;
  final String flag;
  final int pingMs;

  String get key => code.toLowerCase().isNotEmpty ? code.toLowerCase() : name.toLowerCase();

  factory CountryNode.fromApi(Map<String, dynamic> json) {
    final name = (json['name'] ?? json['country'] ?? json['title'] ?? 'Unknown').toString();
    final code = (json['code'] ?? json['country_code'] ?? json['iso'] ?? '').toString();
    final pingRaw = json['ping'] ?? json['latency'] ?? 0;
    final ping = int.tryParse(pingRaw.toString()) ?? 0;
    final flag = (json['flag']?.toString().isNotEmpty ?? false) ? json['flag'].toString() : _flagFromCode(code);
    return CountryNode(name: name, code: code, flag: flag, pingMs: ping);
  }

  static String _flagFromCode(String code) {
    final upper = code.toUpperCase();
    if (upper.length != 2) return '🌍';
    const int base = 127397;
    final int first = upper.codeUnitAt(0) + base;
    final int second = upper.codeUnitAt(1) + base;
    return String.fromCharCodes([first, second]);
  }
}
