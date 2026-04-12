import 'package:flutter/material.dart';

const Color _kSheetBackground = Colors.white;
const Color _kAccent = Color(0xFFF5A623);
const Color _kSearchFill = Color(0xFFF3F3F3);

class LocationItem {
  const LocationItem({
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
}

class LocationSheet extends StatefulWidget {
  const LocationSheet({
    super.key,
    required this.locations,
    required this.configs,
    this.selectedKey,
  });

  final List<LocationItem> locations;
  final Map<String, String> configs;
  final String? selectedKey;

  @override
  State<LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<LocationSheet> {
  String _query = '';

  List<LocationItem> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.locations;
    return widget.locations.where((e) {
      return e.name.toLowerCase().contains(q) || e.code.toLowerCase().contains(q);
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
                  autofocus: false,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Поиск',
                    hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFAAAAAA)),
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
                child: _filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'Ничего не найдено',
                          style: TextStyle(color: Color(0xFFAAAAAA)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) {
                          final item = _filtered[i];
                          final selected = item.key == widget.selectedKey;
                          final config = widget.configs[item.key];
                          final hasConfig = config != null && config.isNotEmpty;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Material(
                              color: selected ? _kAccent : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              elevation: selected ? 0 : 1,
                              shadowColor: Colors.black12,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: hasConfig
                                    ? () => Navigator.pop(context, item)
                                    : null,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        item.flag,
                                        style: const TextStyle(fontSize: 28),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: selected
                                                    ? Colors.white
                                                    : const Color(0xFF222222),
                                              ),
                                            ),
                                            if (!hasConfig)
                                              Text(
                                                'Нет конфига',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: selected
                                                      ? Colors.white54
                                                      : const Color(0xFFAAAAAA),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      _PingBars(
                                        pingMs: item.pingMs,
                                        selected: selected,
                                      ),
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

class _PingBars extends StatelessWidget {
  const _PingBars({required this.pingMs, required this.selected});

  final int pingMs;
  final bool selected;

  Color get _color {
    if (selected) return Colors.white;
    if (pingMs <= 0) return const Color(0xFF4CAF50);
    if (pingMs < 80) return const Color(0xFF4CAF50);
    if (pingMs <= 150) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }

  Widget _bar(double h, bool active) {
    return Container(
      width: 4,
      height: h,
      decoration: BoxDecoration(
        color: active ? _color : _color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final level = pingMs <= 0
        ? 3
        : pingMs < 80
            ? 3
            : pingMs <= 150
                ? 2
                : 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _bar(8, level >= 1),
        const SizedBox(width: 2),
        _bar(13, level >= 2),
        const SizedBox(width: 2),
        _bar(18, level >= 3),
      ],
    );
  }
}
