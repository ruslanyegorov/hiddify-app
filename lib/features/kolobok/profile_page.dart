import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/kolobok/api_service.dart';
import 'package:hiddify/features/kolobok/language_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

const Color _kAccent = Color(0xFFF5A623);

class KolobokProfilePage extends ConsumerStatefulWidget {
  const KolobokProfilePage({
    super.key,
    required this.apiService,
    required this.onLogout,
    this.onGoToPremium,
  });

  final ApiService apiService;
  final VoidCallback onLogout;
  final VoidCallback? onGoToPremium;

  @override
  ConsumerState<KolobokProfilePage> createState() => _KolobokProfilePageState();
}

class _KolobokProfilePageState extends ConsumerState<KolobokProfilePage> {
  late Future<_ProfileData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ProfileData> _load() async {
    await initializeDateFormatting('ru');
    await initializeDateFormatting('en');
    final profile = await widget.apiService.getProfile();
    Map<String, dynamic> sub = {};
    List<Map<String, dynamic>> devices = [];
    try {
      sub = await widget.apiService.getSubscription();
    } catch (_) {}
    try {
      devices = await widget.apiService.getDevices();
    } catch (_) {}
    return _ProfileData(profile: profile, subscription: sub, devices: devices);
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _showEditSheet(
    BuildContext context,
    String currentName,
    String currentEmail,
    bool ru,
  ) async {
    final nameCtrl = TextEditingController(text: currentName);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                ru ? 'Изменить данные' : 'Change User Information',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 20),
              Text(ru ? 'Имя пользователя' : 'Full Name',
                  style: const TextStyle(color: Color(0xFF666666), fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              Text(ru ? 'Email' : 'Email',
                  style: const TextStyle(color: Color(0xFF666666), fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                enabled: false,
                controller: TextEditingController(text: currentEmail),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFEEEEEE),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF666666),
                        side: const BorderSide(color: Color(0xFFDDDDDD)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(ru ? 'Отмена' : 'Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: Text(ru ? 'Сохранить' : 'Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _renameDevice(int id, String current, bool ru) async {
    final ctrl = TextEditingController(text: current);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ru ? 'Переименовать' : 'Rename device'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: ru ? 'Название' : 'Device name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ru ? 'Отмена' : 'Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ru ? 'Сохранить' : 'Save')),
        ],
      ),
    );
    if (ok != true || ctrl.text.trim().isEmpty) return;
    try {
      await widget.apiService.renameDevice(id, ctrl.text.trim());
      _refresh();
    } catch (_) {}
  }

  Future<void> _deleteDevice(int id, String name, bool ru) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ru ? 'Удалить устройство' : 'Remove device'),
        content: Text(ru ? 'Удалить "$name"?' : 'Remove "$name"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ru ? 'Отмена' : 'Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                ru ? 'Удалить' : 'Remove',
                style: const TextStyle(color: Colors.red),
              )),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.apiService.deleteDevice(id);
      _refresh();
    } catch (_) {}
  }

  String _formatDate(String raw, String lang) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat('d MMMM yyyy', lang == 'en' ? 'en' : 'ru').format(dt.toLocal());
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

    return FutureBuilder<_ProfileData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: _kAccent));
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(ru ? 'Ошибка' : 'Error',
                    style: const TextStyle(color: Color(0xFFC62828))),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _refresh,
                  style: ElevatedButton.styleFrom(backgroundColor: _kAccent),
                  child: Text(ru ? 'Повторить' : 'Retry',
                      style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data!;
        final profileRaw = data.profile;
        final user = (profileRaw['user'] is Map)
            ? (profileRaw['user'] as Map).cast<String, dynamic>()
            : profileRaw;
        final username = user['username']?.toString() ?? user['name']?.toString() ?? '-';
        final email = user['email']?.toString() ?? '-';
        final userId = user['id']?.toString() ?? '';

        final sub = data.subscription;
        final subStatus = sub['status']?.toString() ?? 'none';
        final isActive = subStatus == 'active';
        final expiresRaw = sub['expires_at']?.toString() ?? '';
        final days = expiresRaw.isNotEmpty ? _daysLeft(expiresRaw) : 0;

        final devices = data.devices;

        return RefreshIndicator(
          color: _kAccent,
          onRefresh: () async => _refresh(),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Orange header card
              Container(
                color: _kAccent,
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top + 16,
                  left: 20,
                  right: 20,
                  bottom: 24,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Email: $email',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                      onPressed: () => _showEditSheet(context, username, email, ru),
                    ),
                  ],
                ),
              ),

              // Info rows
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    if (userId.isNotEmpty)
                      _InfoRow(
                        label: 'My ID',
                        value: 'AH_$userId',
                        canCopy: true,
                      ),
                    if (userId.isNotEmpty) const Divider(height: 1),
                    _InfoRow(
                      label: ru ? 'Тип' : 'Type',
                      value: isActive ? 'PREMIUM' : 'FREE',
                      valueColor: isActive ? _kAccent : const Color(0xFF888888),
                      trailing: isActive && days > 0
                          ? Text(
                              '$days ${ru ? 'дн. осталось' : 'days left'}',
                              style: const TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 12,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Devices section
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ru ? 'Устройства' : 'Devices',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _kAccent,
                          ),
                        ),
                        Text(
                          '${devices.length}/2',
                          style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (devices.isEmpty)
                      Text(
                        ru ? 'Нет привязанных устройств' : 'No devices registered',
                        style: const TextStyle(color: Color(0xFF888888), fontSize: 14),
                      )
                    else
                      ...devices.map((dev) {
                        final id = dev['id'] is int
                            ? dev['id'] as int
                            : int.tryParse('${dev['id']}') ?? 0;
                        final name = dev['name']?.toString() ?? '';
                        final platform = dev['platform']?.toString() ?? '';
                        final lastSeen = dev['last_seen_at']?.toString() ?? '';
                        final icon = switch (platform.toLowerCase()) {
                          'android' => Icons.android,
                          'ios' => Icons.phone_iphone,
                          'windows' => Icons.desktop_windows,
                          'macos' => Icons.laptop_mac,
                          'linux' => Icons.computer,
                          _ => Icons.devices_rounded,
                        };

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(icon, color: _kAccent, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: Color(0xFF222222),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (lastSeen.isNotEmpty)
                                      Text(
                                        _formatDate(lastSeen, lang),
                                        style: const TextStyle(
                                          color: Color(0xFFAAAAAA),
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: _kAccent),
                                onPressed: () => _renameDevice(id, name, ru),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                onPressed: () => _deleteDevice(id, name, ru),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Language
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(ru ? 'Язык' : 'Language',
                        style: const TextStyle(color: Color(0xFF333333), fontSize: 15)),
                    DropdownButton<String>(
                      value: lang == 'en' ? 'en' : 'ru',
                      underline: const SizedBox(),
                      style: const TextStyle(color: Color(0xFF333333), fontSize: 15),
                      dropdownColor: Colors.white,
                      items: const [
                        DropdownMenuItem(
                            value: 'ru',
                            child: Text('Русский', style: TextStyle(color: Color(0xFF333333)))),
                        DropdownMenuItem(
                            value: 'en',
                            child: Text('English', style: TextStyle(color: Color(0xFF333333)))),
                      ],
                      onChanged: (val) async {
                        if (val == null) return;
                        await ref.read(kolobokLanguageProvider.notifier).setLanguage(val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Go to Premium button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: widget.onGoToPremium,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.workspace_premium_rounded),
                    label: Text(ru ? 'Перейти к Premium' : 'Go to Premium'),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Sign Out button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await widget.apiService.clearToken();
                      if (ref.read(connectionNotifierProvider).value == const Connected()) {
                        await ref.read(connectionNotifierProvider.notifier).toggleConnection();
                      }
                      if (!mounted) return;
                      widget.onLogout();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Color(0xFFEEEEEE)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: Text(ru ? 'Выйти' : 'Sign Out'),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.canCopy = false,
    this.trailing,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool canCopy;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF888888), fontSize: 14),
            ),
          ),
          const Text(' : ', style: TextStyle(color: Color(0xFFCCCCCC))),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? const Color(0xFF222222),
                fontSize: 14,
                fontWeight: valueColor != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (trailing != null) trailing!,
          if (canCopy)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Скопировано'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFFCCCCCC)),
            ),
        ],
      ),
    );
  }
}

class _ProfileData {
  const _ProfileData({
    required this.profile,
    required this.subscription,
    required this.devices,
  });

  final Map<String, dynamic> profile;
  final Map<String, dynamic> subscription;
  final List<Map<String, dynamic>> devices;
}
