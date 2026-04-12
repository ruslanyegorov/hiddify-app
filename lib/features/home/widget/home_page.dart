import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/home/widget/connection_button.dart';
import 'package:hiddify/features/kolobok/about_screen.dart';
import 'package:hiddify/features/kolobok/api_service.dart';
import 'package:hiddify/features/kolobok/auth_page.dart';
import 'package:hiddify/features/kolobok/help_screen.dart';
import 'package:hiddify/features/kolobok/language_notifier.dart';
import 'package:hiddify/features/kolobok/location_page.dart';
import 'package:hiddify/features/kolobok/profile_page.dart';
import 'package:hiddify/features/kolobok/settings_screen.dart';
import 'package:hiddify/features/kolobok/subscription_page.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/overview/profiles_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const Color _kAccent = Color(0xFFF5A623);
const Color _kBg = Color(0xFFF5F5F0);

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ApiService _api = ApiService();
  int _tabIndex = 0;

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
      backgroundColor: _kBg,
      drawer: _KolobokDrawer(
        apiService: _api,
        ru: ru,
        currentTab: _tabIndex,
        onNavigate: (tab) => setState(() => _tabIndex = tab),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF333333), size: 26),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Image.asset('assets/images/logo-2.png', height: 36, fit: BoxFit.contain),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () => setState(() => _tabIndex = 1),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _kAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _HomeTab(apiService: _api),
          SubscriptionPage(apiService: _api),
          KolobokProfilePage(
            apiService: _api,
            onLogout: () {
              if (!mounted) return;
              setState(() => _tabIndex = 0);
            },
            onGoToPremium: () => setState(() => _tabIndex = 1),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (v) => setState(() => _tabIndex = v),
        backgroundColor: Colors.white,
        indicatorColor: _kAccent.withValues(alpha: 0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined, color: Color(0xFF888888)),
            selectedIcon: const Icon(Icons.home_rounded, color: _kAccent),
            label: ru ? 'Главная' : 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.workspace_premium_outlined, color: Color(0xFF888888)),
            selectedIcon: const Icon(Icons.workspace_premium_rounded, color: _kAccent),
            label: ru ? 'Подписка' : 'Subscription',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded, color: Color(0xFF888888)),
            selectedIcon: const Icon(Icons.person_rounded, color: _kAccent),
            label: ru ? 'Профиль' : 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─────────────────── Sidebar Drawer ───────────────────

class _KolobokDrawer extends ConsumerStatefulWidget {
  const _KolobokDrawer({
    required this.apiService,
    required this.ru,
    required this.currentTab,
    required this.onNavigate,
  });

  final ApiService apiService;
  final bool ru;
  final int currentTab;
  final void Function(int tab) onNavigate;

  @override
  ConsumerState<_KolobokDrawer> createState() => _KolobokDrawerState();
}

class _KolobokDrawerState extends ConsumerState<_KolobokDrawer> {
  String _username = '';

  @override
  void initState() {
    super.initState();
    widget.apiService.getProfile().then((data) {
      final user = (data['user'] is Map) ? (data['user'] as Map).cast<String, dynamic>() : data;
      if (!mounted) return;
      setState(() {
        _username = user['username']?.toString() ?? user['name']?.toString() ?? '';
      });
    }).catchError((_) {});
  }

  void _go(int tab) {
    Navigator.pop(context);
    widget.onNavigate(tab);
  }

  void _push(Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final ru = widget.ru;

    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.78,
      child: Container(
        color: _kAccent,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ru ? 'Привет,' : 'Hello,',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _username.isNotEmpty ? _username : (ru ? 'Пользователь' : 'User'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _DrawerItem(
                icon: Icons.home_rounded,
                label: ru ? 'Главная' : 'Home',
                selected: widget.currentTab == 0,
                onTap: () => _go(0),
              ),
              _DrawerItem(
                icon: Icons.person_rounded,
                label: ru ? 'Мой аккаунт' : 'My Account',
                selected: widget.currentTab == 2,
                onTap: () => _go(2),
              ),
              _DrawerItem(
                icon: Icons.workspace_premium_rounded,
                label: ru ? 'Подписка' : 'Subscription',
                selected: widget.currentTab == 1,
                onTap: () => _go(1),
              ),
              _DrawerItem(
                icon: Icons.settings_rounded,
                label: ru ? 'Настройки' : 'Settings',
                selected: false,
                onTap: () => _push(const KolobokSettingsScreen()),
              ),
              _DrawerItem(
                icon: Icons.help_outline_rounded,
                label: ru ? 'Помощь' : 'Help',
                selected: false,
                onTap: () => _push(KolobokHelpScreen(ru: ru)),
              ),
              _DrawerItem(
                icon: Icons.info_outline_rounded,
                label: ru ? 'О приложении' : 'About Us',
                selected: false,
                onTap: () => _push(KolobokAboutScreen(ru: ru)),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _go(1),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kAccent,
                      backgroundColor: Colors.white,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.workspace_premium_rounded, size: 20),
                    label: Text(
                      ru ? 'Перейти к Premium' : 'Go to Premium',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 22),
        title: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ─────────────────── Home Tab ───────────────────

class _HomeTab extends ConsumerStatefulWidget {
  const _HomeTab({required this.apiService});

  final ApiService apiService;

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  late Future<_HomeData> _dataFuture;
  LocationItem? _selectedLocation;
  final Map<String, String> _profileIdByKey = {};
  bool _actionLoading = false;

  // Connection timer
  DateTime? _connectedAt;
  Timer? _ticker;
  String _timerLabel = '00:00:00';

  // Disconnect banner
  bool _showDisconnectedBanner = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<_HomeData> _load() async {
    String subStatus = 'none';
    try {
      final sub = await widget.apiService.getSubscription();
      subStatus = sub['status']?.toString() ?? 'none';
    } catch (_) {}

    final rawCountries = await widget.apiService.getCountries();
    final rawConfigs = await widget.apiService.getSubscriptionConfigs();

    final locations = rawCountries.map((e) => _locationFromApi(e)).toList();
    final configs = _parseConfigs(rawConfigs);
    return _HomeData(locations: locations, configs: configs, subscriptionStatus: subStatus);
  }

  LocationItem _locationFromApi(Map<String, dynamic> json) {
    final name = (json['name'] ?? json['country'] ?? 'Unknown').toString();
    final code = (json['code'] ?? json['country_code'] ?? '').toString();
    final pingRaw = json['ping'] ?? json['latency'] ?? 0;
    final ping = int.tryParse(pingRaw.toString()) ?? 0;
    final flagRaw = json['flag_emoji'] ?? json['flag'];
    final flag = (flagRaw != null && flagRaw.toString().isNotEmpty)
        ? flagRaw.toString()
        : _flagFromCode(code);
    return LocationItem(name: name, code: code, flag: flag, pingMs: ping);
  }

  static String _flagFromCode(String code) {
    final upper = code.toUpperCase();
    if (upper.length != 2) return '🌍';
    const base = 127397;
    return String.fromCharCodes([upper.codeUnitAt(0) + base, upper.codeUnitAt(1) + base]);
  }

  Map<String, String> _parseConfigs(Map<String, dynamic> raw) {
    final result = <String, String>{};
    final dynamic source = raw['data'] ?? raw['configs'] ?? raw['items'] ?? raw;
    if (source is Map) {
      for (final e in source.entries) {
        if (e.value == null) continue;
        result[e.key.toString().toLowerCase()] = e.value.toString();
      }
    } else if (source is List) {
      for (final dynamic item in source) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        var key = '';
        final nested = map['node'];
        if (nested is Map) {
          key = (Map<String, dynamic>.from(nested)['country_code'] ?? '').toString().toLowerCase();
        }
        if (key.isEmpty) {
          key = (map['country_code'] ?? map['code'] ?? map['country'] ?? '').toString().toLowerCase();
        }
        final config = (map['vless_link'] ?? map['config'] ?? map['vless'] ?? '').toString();
        if (key.isNotEmpty && config.isNotEmpty) result[key] = config;
      }
    }
    return result;
  }

  void _startTimer() {
    _connectedAt = DateTime.now();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final elapsed = DateTime.now().difference(_connectedAt!);
      final h = elapsed.inHours.toString().padLeft(2, '0');
      final m = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
      final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
      setState(() => _timerLabel = '$h:$m:$s');
    });
  }

  void _stopTimer() {
    _ticker?.cancel();
    _ticker = null;
    _connectedAt = null;
    _timerLabel = '00:00:00';
  }

  Future<void> _openLocationSheet(
    List<LocationItem> locations,
    Map<String, String> configs,
  ) async {
    final result = await showModalBottomSheet<LocationItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationSheet(
        locations: locations,
        configs: configs,
        selectedKey: _selectedLocation?.key,
      ),
    );
    if (result == null || !mounted) return;
    await _selectLocation(result, configs);
  }

  Future<void> _selectLocation(LocationItem item, Map<String, String> configs) async {
    setState(() {
      _selectedLocation = item;
      _actionLoading = true;
    });

    try {
      final config = configs[item.key];
      if (config == null || config.isEmpty) {
        setState(() => _actionLoading = false);
        return;
      }

      String? profileId = _profileIdByKey[item.key];
      if (profileId == null) {
        final before = await ref.read(profilesNotifierProvider.future);
        final beforeIds = before.map((e) => e.id).toSet();
        final repo = await ref.read(profileRepositoryProvider.future);
        final result = await repo.addLocal(config).run();
        if (result.isLeft()) {
          setState(() => _actionLoading = false);
          return;
        }
        final after = await ref.read(profilesNotifierProvider.future);
        final created = after.where((e) => !beforeIds.contains(e.id)).toList();
        if (created.isNotEmpty) {
          profileId = created.first.id;
          _profileIdByKey[item.key] = profileId;
        }
      }
      if (profileId == null) {
        setState(() => _actionLoading = false);
        return;
      }

      await ref.read(profilesNotifierProvider.notifier).selectActiveProfile(profileId);
      await Future<void>.delayed(const Duration(milliseconds: 150));

      final status = ref.read(connectionNotifierProvider).valueOrNull;
      if (status == const Connected()) {
        final profile = await ref.read(activeProfileProvider.future);
        await ref.read(connectionNotifierProvider.notifier).reconnect(profile);
      } else if (status == const Disconnected()) {
        await ref.read(connectionNotifierProvider.notifier).mayConnect();
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ru = ref.watch(kolobokLanguageProvider) != 'en';

    // Listen to connection status for timer and banner
    ref.listen(connectionNotifierProvider, (prev, next) {
      final prevStatus = prev?.valueOrNull;
      final nextStatus = next.valueOrNull;
      if (nextStatus == const Connected() && prevStatus != const Connected()) {
        _startTimer();
        setState(() => _showDisconnectedBanner = false);
      } else if (nextStatus == const Disconnected() && prevStatus != const Disconnected()) {
        _stopTimer();
        setState(() => _showDisconnectedBanner = true);
        Future<void>.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _showDisconnectedBanner = false);
        });
      }
    });

    final connStatus = ref.watch(connectionNotifierProvider);
    final isConnected = connStatus.value == const Connected();
    final isConnecting = connStatus.value == const Connecting() ||
        connStatus.value == const Disconnecting();

    return FutureBuilder<_HomeData>(
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
                  style: const TextStyle(color: Color(0xFFC62828), fontSize: 16),
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
        final locations = data.locations;
        final configs = data.configs;
        final subStatus = data.subscriptionStatus;

        return Stack(
          children: [
            // World map background
            Positioned.fill(
              child: Opacity(
                opacity: 0.25,
                child: Image.asset('assets/images/world_map.png', fit: BoxFit.cover),
              ),
            ),
            Column(
              children: [
                // Disconnected banner
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _showDisconnectedBanner
                      ? Container(
                          key: const ValueKey('banner'),
                          width: double.infinity,
                          color: const Color(0xFFE8F5E9),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 18),
                              const SizedBox(width: 8),
                              Text(
                                ru ? 'Успешно отключено' : 'Disconnected from server',
                                style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('no_banner')),
                ),
                // Subscription banner
                if (subStatus != 'active')
                  Material(
                    color: const Color(0xFFFFF3E0),
                    child: InkWell(
                      onTap: () {
                        final homeState = context.findAncestorStateOfType<_HomePageState>();
                        homeState?.setState(() => homeState._tabIndex = 1);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: _kAccent, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                ru
                                    ? 'Подписка неактивна. Нажмите для оформления.'
                                    : 'No active subscription. Tap to subscribe.',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF5D4037)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Location card
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 2)),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: _selectedLocation != null
                                ? Text(_selectedLocation!.flag, style: const TextStyle(fontSize: 24))
                                : const Icon(Icons.public_rounded, color: Color(0xFFAAAAAA), size: 24),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedLocation?.name ?? (ru ? 'Лучший сервер' : 'Best Location'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _kAccent,
                                ),
                              ),
                              Text(
                                ru ? 'Быстрый сервер' : 'Fastest Server',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                              ),
                            ],
                          ),
                        ),
                        if (_selectedLocation != null)
                          _PingBarsSmall(pingMs: _selectedLocation!.pingMs),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Change Location button
                OutlinedButton.icon(
                  onPressed: _actionLoading
                      ? null
                      : () => _openLocationSheet(locations, configs),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kAccent,
                    side: const BorderSide(color: _kAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  icon: const Icon(Icons.expand_more_rounded, size: 18),
                  label: Text(ru ? 'Сменить локацию' : 'Change Location'),
                ),

                // Connected timer + IP
                if (isConnected)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      children: [
                        Text(
                          _timerLabel,
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: _kAccent,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ru ? 'Время подключения' : 'Session time',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                        ),
                      ],
                    ),
                  ),

                const Spacer(),

                // Power button + orange wave
                _PowerWave(
                  ru: ru,
                  isConnected: isConnected,
                  isConnecting: isConnecting,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────── Power + Wave area ───────────────────

class _PowerWave extends ConsumerWidget {
  const _PowerWave({
    required this.ru,
    required this.isConnected,
    required this.isConnecting,
  });

  final bool ru;
  final bool isConnected;
  final bool isConnecting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Orange wave at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 140,
            child: Container(
              decoration: const BoxDecoration(
                color: _kAccent,
                borderRadius: BorderRadius.vertical(top: Radius.circular(48)),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    isConnected
                        ? (ru ? 'Подключено' : 'Connected')
                        : isConnecting
                            ? (ru ? 'Подключение...' : 'Connecting...')
                            : (ru ? 'Нажмите для подключения' : 'Tap to Connect'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Concentric circles decoration
          Positioned(
            bottom: 60,
            child: Opacity(
              opacity: 0.15,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            child: Opacity(
              opacity: 0.1,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ),
          // Power button
          Positioned(
            top: 0,
            child: const ConnectionButton(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────── Small ping bars ───────────────────

class _PingBarsSmall extends StatelessWidget {
  const _PingBarsSmall({required this.pingMs});

  final int pingMs;

  Color get _color {
    if (pingMs <= 0 || pingMs < 80) return const Color(0xFF4CAF50);
    if (pingMs <= 150) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }

  int get _level {
    if (pingMs <= 0 || pingMs < 80) return 3;
    if (pingMs <= 150) return 2;
    return 1;
  }

  Widget _bar(double h, bool active) => Container(
        width: 4,
        height: h,
        decoration: BoxDecoration(
          color: active ? _color : _color.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(2),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _bar(7, _level >= 1),
        const SizedBox(width: 2),
        _bar(11, _level >= 2),
        const SizedBox(width: 2),
        _bar(15, _level >= 3),
      ],
    );
  }
}

// ─────────────────── Data model ───────────────────

class _HomeData {
  const _HomeData({
    required this.locations,
    required this.configs,
    required this.subscriptionStatus,
  });

  final List<LocationItem> locations;
  final Map<String, String> configs;
  final String subscriptionStatus;
}

// ─────────────────── CountryNode kept for legacy ───────────────────

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
    final name = (json['name'] ?? json['country'] ?? 'Unknown').toString();
    final code = (json['code'] ?? json['country_code'] ?? '').toString();
    final pingRaw = json['ping'] ?? json['latency'] ?? 0;
    final ping = int.tryParse(pingRaw.toString()) ?? 0;
    final flagRaw = json['flag_emoji'] ?? json['flag'];
    final flag = (flagRaw != null && flagRaw.toString().isNotEmpty)
        ? flagRaw.toString()
        : _flagFromCode(code);
    return CountryNode(name: name, code: code, flag: flag, pingMs: ping);
  }

  static String _flagFromCode(String code) {
    final upper = code.toUpperCase();
    if (upper.length != 2) return '🌍';
    const base = 127397;
    return String.fromCharCodes([upper.codeUnitAt(0) + base, upper.codeUnitAt(1) + base]);
  }
}
