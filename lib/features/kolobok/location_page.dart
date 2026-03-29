import 'package:flutter/material.dart';

const Color _kSheetBackground = Color(0xFFF5F5F0);
const Color _kAccent = Color(0xFFF5A623);
const Color _kSearchFill = Color(0xFFF0F0F0);

final List<Map<String, dynamic>> _kLocations = [
  {'country': 'Германия', 'city': 'Франкфурт', 'flag': '🇩🇪', 'ping': 45},
  {'country': 'Нидерланды', 'city': 'Амстердам', 'flag': '🇳🇱', 'ping': 60},
  {'country': 'Финляндия', 'city': 'Хельсинки', 'flag': '🇫🇮', 'ping': 95},
];

bool _sameLocation(Map<String, dynamic> a, Map<String, dynamic>? b) {
  if (b == null) return false;
  return a['country'] == b['country'] && a['city'] == b['city'];
}

class LocationSheet extends StatefulWidget {
  const LocationSheet({super.key, this.initial});

  final Map<String, dynamic>? initial;

  @override
  State<LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<LocationSheet> {
  String _query = '';

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return List<Map<String, dynamic>>.from(_kLocations);
    return _kLocations.where((e) {
      final country = e['country']?.toString().toLowerCase() ?? '';
      final city = e['city']?.toString().toLowerCase() ?? '';
      return country.contains(q) || city.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sheetH = MediaQuery.sizeOf(context).height * 0.88;

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        height: sheetH,
        child: Container(
          decoration: const BoxDecoration(
            color: _kSheetBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC4C4C4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Сменить локацию',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Поиск',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF333333)),
                    filled: true,
                    fillColor: _kSearchFill,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: _filtered.length,
                  itemBuilder: (context, i) {
                    final item = _filtered[i];
                    final selected = _sameLocation(item, widget.initial);
                    final country = item['country']?.toString() ?? '';
                    final city = item['city']?.toString() ?? '';
                    final flag = item['flag']?.toString() ?? '🌍';
                    final ping = item['ping'] is int ? item['ping'] as int : int.tryParse('${item['ping']}') ?? 999;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: selected ? _kAccent : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        elevation: selected ? 0 : 1,
                        shadowColor: Colors.black12,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pop(context, item),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Text(flag, style: const TextStyle(fontSize: 32)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        country,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: selected ? Colors.white : const Color(0xFF222222),
                                        ),
                                      ),
                                      Text(
                                        city,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: selected ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF333333),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _PingIndicator(ping: ping),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PingIndicator extends StatelessWidget {
  const _PingIndicator({required this.ping});

  final int ping;

  Color get _barColor {
    if (ping < 80) return const Color(0xFF4CAF50);
    if (ping <= 150) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }

  Widget _bar(double height) {
    return Container(
      width: 4,
      height: height,
      decoration: BoxDecoration(
        color: _barColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _bar(8),
        const SizedBox(width: 2),
        _bar(13),
        const SizedBox(width: 2),
        _bar(18),
      ],
    );
  }
}
