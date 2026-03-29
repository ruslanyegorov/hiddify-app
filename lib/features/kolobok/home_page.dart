import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hiddify/features/kolobok/api_service.dart';
import 'package:hiddify/features/kolobok/location_page.dart';

const Color _kAccent = Color(0xFFF5A623);
const Color _kBackground = Color(0xFFF5F5F0);
const Color _kBorder = Color(0xFFE0E0E0);

const String _kTrialWelcomeMessage = 'Добро пожаловать! У вас 7 дней бесплатного доступа';

enum _VpnState { disconnected, connecting, connected }

class KolobokHomePage extends StatefulWidget {
  const KolobokHomePage({super.key, required this.apiService});

  final ApiService apiService;

  @override
  State<KolobokHomePage> createState() => _KolobokHomePageState();
}

class _KolobokHomePageState extends State<KolobokHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Map<String, dynamic>> _countries = [];
  int _selectedCountryIndex = 0;
  Map<String, dynamic>? _selectedLocation;
  String _username = '';
  String _displayIp = '—';
  bool _dataLoading = true;

  _VpnState _vpnState = _VpnState.disconnected;
  DateTime? _connectedAt;
  Timer? _connectionTicker;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _connectionTicker?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _dataLoading = true);

    var countries = <Map<String, dynamic>>[];
    var username = '';
    var ip = '—';

    try {
      countries = await widget.apiService.getCountries();
    } catch (_) {}

    try {
      final profile = await widget.apiService.getProfile();
      final user = (profile['user'] is Map)
          ? (profile['user'] as Map).cast<String, dynamic>()
          : profile;
      username = user['username']?.toString() ?? user['name']?.toString() ?? '';
      ip = profile['ip']?.toString() ??
          user['ip']?.toString() ??
          user['public_ip']?.toString() ??
          '—';
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _countries = countries;
      _selectedCountryIndex = 0;
      _username = username;
      _displayIp = ip;
      _dataLoading = false;
    });
  }

  void _stopConnectionTicker() {
    _connectionTicker?.cancel();
    _connectionTicker = null;
    _connectedAt = null;
  }

  void _startConnectionTicker() {
    _connectionTicker?.cancel();
    _connectedAt = DateTime.now();
    _connectionTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _onPowerTap() async {
    if (_vpnState == _VpnState.connecting) return;
    if (_vpnState == _VpnState.connected) {
      _stopConnectionTicker();
      setState(() => _vpnState = _VpnState.disconnected);
      return;
    }
    setState(() => _vpnState = _VpnState.connecting);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    if (_vpnState != _VpnState.connecting) return;
    setState(() => _vpnState = _VpnState.connected);
    _startConnectionTicker();
  }

  Map<String, dynamic> _currentLocation() {
    if (_selectedLocation != null) {
      return _selectedLocation!;
    }
    if (_countries.isEmpty) {
      return {
        'flag': '🌍',
        'country': 'Авто',
        'city': 'Лучший сервер',
      };
    }
    return _countries[_selectedCountryIndex.clamp(0, _countries.length - 1)];
  }

  String _countryLabel(Map<String, dynamic> c) {
    return c['country']?.toString() ??
        c['country_name']?.toString() ??
        c['name']?.toString() ??
        'Неизвестно';
  }

  String _cityLabel(Map<String, dynamic> c) {
    return c['city']?.toString() ?? c['location']?.toString() ?? '';
  }

  String _flagLabel(Map<String, dynamic> c) {
    return c['flag']?.toString() ?? c['emoji']?.toString() ?? '🌍';
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Скоро')),
    );
  }

  Future<void> _openLocationPicker() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: LocationSheet(initial: _selectedLocation),
      ),
    );
    if (result != null && mounted) {
      setState(() => _selectedLocation = result);
    }
  }

  String _connectionDurationText() {
    if (_connectedAt == null) return '00:00:00';
    final d = DateTime.now().difference(_connectedAt!);
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Widget _trialWelcomeBanner() {
    return const Material(
      color: Color(0xFFFFF3E0),
      elevation: 1,
      shadowColor: Colors.black12,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          _kTrialWelcomeMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.35,
            color: Color(0xFF5D4037),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = _currentLocation();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _kBackground,
      drawer: _buildDrawer(context),
      appBar: AppBar(
        backgroundColor: _kBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF333333)),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        centerTitle: true,
        title: Image.asset(
          'assets/images/logo-2.png',
          height: 96,
          fit: BoxFit.contain,
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: _kAccent,
              child: Icon(Icons.person, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _trialWelcomeBanner(),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/world_map.png',
                    fit: BoxFit.cover,
                    color: Colors.white.withValues(alpha: 0.35),
                    colorBlendMode: BlendMode.modulate,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_dataLoading)
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(child: CircularProgressIndicator(color: _kAccent)),
                              ),
                            _locationCard(loc),
                            const SizedBox(height: 14),
                            Center(child: _changeLocationButton()),
                            if (_vpnState == _VpnState.connected) ...[
                              const SizedBox(height: 24),
                              Text(
                                _connectionDurationText(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: _kAccent,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ваш IP: $_displayIp',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF444444),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(child: _speedBadge(Icons.download_rounded, '12.4 МБ/с', 'Загрузка')),
                                  const SizedBox(width: 12),
                                  Expanded(child: _speedBadge(Icons.upload_rounded, '3.1 МБ/с', 'Отдача')),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    _bottomWaveSection(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationCard(Map<String, dynamic> loc) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(_flagLabel(loc), style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _countryLabel(loc),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222222),
                    ),
                  ),
                  if (_cityLabel(loc).isNotEmpty)
                    Text(
                      _cityLabel(loc),
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                ],
              ),
            ),
            Icon(
              _vpnState == _VpnState.connected ? Icons.signal_cellular_alt : Icons.signal_cellular_alt_outlined,
              color: _vpnState == _VpnState.connected ? _kAccent : _kBorder,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _changeLocationButton() {
    return OutlinedButton.icon(
      onPressed: _openLocationPicker,
      icon: const Icon(Icons.keyboard_arrow_up_rounded, color: _kAccent),
      label: const Text(
        'Сменить локацию',
        style: TextStyle(
          color: _kAccent,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: _kAccent, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        backgroundColor: Colors.white.withValues(alpha: 0.9),
      ),
    );
  }

  Widget _speedBadge(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(icon, color: _kAccent, size: 26),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomWaveSection() {
    return SizedBox(
      height: 200,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _OrangeWavePainter(color: _kAccent),
            ),
          ),
          Positioned(
            top: -36,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  elevation: 6,
                  shadowColor: Colors.black38,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _onPowerTap,
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: _vpnState == _VpnState.connecting
                          ? const Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(color: _kAccent, strokeWidth: 3),
                            )
                          : const Icon(
                              Icons.power_settings_new,
                              size: 48,
                              color: _kAccent,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _vpnState == _VpnState.connected
                      ? 'Отключиться'
                      : _vpnState == _VpnState.connecting
                          ? 'Подключение…'
                          : 'Подключиться',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: _kAccent,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                _username.isEmpty ? 'Привет!' : 'Привет, $_username',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Пробный период: 7 дней',
                    style: TextStyle(
                      color: Color(0xF2FFFFFF),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                    child: LinearProgressIndicator(
                      value: 1,
                      minHeight: 8,
                      backgroundColor: Colors.black26,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD699)),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _drawerTile(Icons.home_outlined, 'Главная', () {}),
                  _drawerTile(Icons.account_circle_outlined, 'Мой аккаунт', _showComingSoon),
                  _drawerTile(Icons.settings_outlined, 'Настройки', _showComingSoon),
                  _drawerTile(Icons.help_outline, 'Помощь', _showComingSoon),
                  _drawerTile(Icons.info_outline, 'О приложении', _showComingSoon),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: OutlinedButton(
                onPressed: _showComingSoon,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Перейти на Премиум',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}

class _OrangeWavePainter extends CustomPainter {
  _OrangeWavePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 45);
    path.quadraticBezierTo(size.width * 0.25, 8, size.width * 0.5, 28);
    path.quadraticBezierTo(size.width * 0.75, 48, size.width, 22);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _OrangeWavePainter oldDelegate) => oldDelegate.color != color;
}
