import 'package:flutter/material.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/home/widget/connection_button.dart';
import 'package:hiddify/features/home/widget/dns_lookup_latency.dart';
import 'package:hiddify/features/kolobok/api_service.dart';
import 'package:hiddify/features/kolobok/auth_page.dart';
import 'package:hiddify/features/kolobok/language_notifier.dart';
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

const Color _kKolobokAccent = Color(0xFFF5A623);
const Color _kKolobokBackground = Color(0xFFF5F5F0);

class _HomePageState extends ConsumerState<HomePage> {
  final ApiService _api = ApiService();
  int _tabIndex = 0;
  String? _selectedCountryKey;
  final Map<String, String> _countryProfileId = <String, String>{};

  @override
  Widget build(BuildContext context) {
    ref.watch(kolobokLanguageProvider);
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
    final lang = ref.watch(kolobokLanguageProvider);
    final ru = lang != 'en';
    return Scaffold(
      backgroundColor: _kKolobokBackground,
      appBar: AppBar(
        backgroundColor: _kKolobokBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Image.asset(
          'assets/images/logo-2.png',
          height: 40,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF222222)),
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
        indicatorColor: _kKolobokAccent.withValues(alpha: 0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined, color: Color(0xFF333333)),
            selectedIcon: const Icon(Icons.home, color: _kKolobokAccent),
            label: ru ? 'Главная' : 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.card_membership_outlined, color: Color(0xFF333333)),
            selectedIcon: const Icon(Icons.card_membership, color: _kKolobokAccent),
            label: ru ? 'Подписка' : 'Subscription',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline, color: Color(0xFF333333)),
            selectedIcon: const Icon(Icons.person, color: _kKolobokAccent),
            label: ru ? 'Профиль' : 'Profile',
          ),
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

class _ConnectionStatusCaption extends ConsumerWidget {
  const _ConnectionStatusCaption();

  static String _label(AsyncValue<ConnectionStatus> a, bool ru) {
    return switch (a) {
      AsyncData(value: Disconnected()) => ru ? 'Нажмите для подключения' : 'Tap to Connect',
      AsyncData(value: Connecting()) => ru ? 'Подключение...' : 'Connecting...',
      AsyncData(value: Connected()) => ru ? 'Подключено' : 'Connected',
      AsyncData(value: Disconnecting()) => ru ? 'Подключение...' : 'Connecting...',
      _ => ru ? 'Нажмите для подключения' : 'Tap to Connect',
    };
  }

  static Color _color(AsyncValue<ConnectionStatus> a) {
    return switch (a) {
      AsyncData(value: Disconnected()) => const Color(0xFF666666),
      AsyncData(value: Connecting()) => _kKolobokAccent,
      AsyncData(value: Connected()) => const Color(0xFF4CAF50),
      AsyncData(value: Disconnecting()) => _kKolobokAccent,
      _ => const Color(0xFF666666),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(connectionNotifierProvider);
    final ru = ref.watch(kolobokLanguageProvider) != 'en';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        _label(async, ru),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          color: _color(async),
        ),
      ),
    );
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
    final ru = ref.watch(kolobokLanguageProvider) != 'en';
    return FutureBuilder<({List<CountryNode> nodes, Map<String, String> configs})>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                ru ? 'Ошибка загрузки: ${snapshot.error}' : 'Loading error: ${snapshot.error}',
                style: const TextStyle(color: Color(0xFFC62828)),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final nodes = snapshot.data!.nodes;
        final configs = snapshot.data!.configs;

        return LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            return RefreshIndicator(
              color: _kKolobokAccent,
              onRefresh: () async {
                setState(() => _dataFuture = _load());
                await _dataFuture;
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: h > 0 ? h : MediaQuery.sizeOf(context).height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.3,
                          child: Image.asset(
                            'assets/images/world_map.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Expanded(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ConnectionButton(),
                                  SizedBox(height: 16),
                                  _ConnectionStatusCaption(),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF5A623),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  ru ? 'Выберите страну' : 'Select country',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxHeight: h > 0 ? h * 0.42 : 280),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    physics: const ClampingScrollPhysics(),
                                    itemCount: nodes.length,
                                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final node = nodes[index];
                                      final selected = node.key == widget.selectedCountryKey;
                                      return _CountryCard(
                                        node: node,
                                        selected: selected,
                                        loading: _actionLoading,
                                        onTap: () async {
                                          final config = configs[node.key];
                                          if (config == null || config.isEmpty) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                backgroundColor: Colors.white,
                                                content: Text(
                                                  'Нет конфига для страны ${node.name}',
                                                  style: const TextStyle(color: Color(0xFF333333)),
                                                ),
                                              ),
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
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<({List<CountryNode> nodes, Map<String, String> configs})> _load() async {
    try {
      await widget.apiService.activatePlan('1');
    } catch (_) {}
    final rawCountries = await widget.apiService.getCountries();
    final rawConfigs = await widget.apiService.getSubscriptionConfigs();
    final nodes = rawCountries.map((e) => CountryNode.fromApi(e)).toList();
    final configs = _parseConfigs(rawConfigs);
    return (nodes: nodes, configs: configs);
  }

  Map<String, String> _parseConfigs(Map<String, dynamic> raw) {
    final result = <String, String>{};
    final dynamic source = raw['data'] ?? raw['configs'] ?? raw['items'] ?? raw;
    if (source is Map) {
      for (final entry in source.entries) {
        if (entry.value == null) continue;
        result[entry.key.toString().toLowerCase()] = entry.value.toString();
      }
    } else if (source is List) {
      for (final dynamic item in source) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        var key = '';
        final nested = map['node'];
        if (nested is Map) {
          final n = Map<String, dynamic>.from(nested);
          key = (n['country_code'] ?? '').toString().toLowerCase();
        }
        if (key.isEmpty) {
          key = (map['country_code'] ?? map['code'] ?? map['country'] ?? map['name'] ?? '').toString().toLowerCase();
        }
        final config = (map['vless_link'] ?? map['config'] ?? map['vless'] ?? map['url'] ?? '').toString();
        if (key.isNotEmpty && config.isNotEmpty) {
          result[key] = config;
        }
      }
    }
    return result;
  }
}

class _CountryCard extends StatefulWidget {
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
  State<_CountryCard> createState() => _CountryCardState();
}

class _CountryCardState extends State<_CountryCard> {
  int? _lookupMs;

  @override
  void initState() {
    super.initState();
    if (widget.node.pingMs > 0) {
      return;
    }
    measureDnsLookupLatencyMs().then((ms) {
      if (!mounted) return;
      setState(() => _lookupMs = ms);
    });
  }

  @override
  void didUpdateWidget(covariant _CountryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node.key != widget.node.key) {
      _lookupMs = null;
      if (widget.node.pingMs > 0) {
        return;
      }
      measureDnsLookupLatencyMs().then((ms) {
        if (!mounted) return;
        setState(() => _lookupMs = ms);
      });
    }
  }

  Widget? _pingSubtitle() {
    if (widget.node.pingMs > 0) {
      return Text(
        'Пинг: ${widget.node.pingMs} мс',
        style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
      );
    }
    final ms = _lookupMs;
    if (ms != null && ms > 0) {
      return Text(
        'Пинг: $ms мс',
        style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.loading ? null : widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: widget.selected ? Border.all(color: _kKolobokAccent, width: 2) : null,
            boxShadow: const [
              BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: Text(widget.node.flag, style: const TextStyle(fontSize: 24)),
            title: Text(
              widget.node.name,
              style: const TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.w600),
            ),
            subtitle: _pingSubtitle(),
            trailing: widget.selected
                ? const Icon(Icons.check_circle, color: _kKolobokAccent)
                : const Icon(Icons.chevron_right_rounded, color: Color(0xFF333333)),
          ),
        ),
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
    final flagRaw = json['flag_emoji'] ?? json['flag'] ?? json['emoji'];
    final flag = (flagRaw != null && flagRaw.toString().isNotEmpty)
        ? flagRaw.toString()
        : _flagFromCode(code);
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
