import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api_service.dart';

class UpdateService {
  static Future<void> checkAndPrompt(BuildContext context, ApiService api) async {
    if (!Platform.isAndroid) return;
    try {
      final info = await api.checkVersion();
      final serverBuild = info['build'];
      if (serverBuild == null) return;

      final pkg = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(pkg.buildNumber) ?? 0;

      if (serverBuild <= currentBuild) return;

      final apkUrl = info['apk_url']?.toString() ?? '';
      final serverVersion = info['version']?.toString() ?? '';
      final changelog = info['changelog']?.toString() ?? '';
      final force = info['force'] == true;

      if (!context.mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: !force,
        builder: (_) => _UpdateDialog(
          version: serverVersion,
          changelog: changelog,
          apkUrl: apkUrl,
          force: force,
        ),
      );
    } catch (_) {
      // Silent — don't break app startup on network errors
    }
  }
}

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({
    required this.version,
    required this.changelog,
    required this.apkUrl,
    required this.force,
  });

  final String version;
  final String changelog;
  final String apkUrl;
  final bool force;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  // null = idle, 0..1 = downloading, 1.0 = done
  double? _progress;
  bool _done = false;
  String? _error;
  String? _savedPath;
  final _dio = Dio();
  CancelToken? _cancelToken;

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _startDownload() async {
    setState(() {
      _progress = 0;
      _error = null;
      _done = false;
      _savedPath = null;
    });

    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/kolobok_update.apk';
      _cancelToken = CancelToken();

      await _dio.download(
        widget.apkUrl,
        path,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _progress = received / total);
          }
        },
      );

      if (!mounted) return;
      setState(() {
        _done = true;
        _savedPath = path;
        _progress = 1.0;
      });

      // Try to open the APK file via Intent (works on Android < 7 or if FileProvider is available)
      // Fallback to browser download URL
      await _openInstaller(path);
    } on DioException catch (e) {
      if (e.type != DioExceptionType.cancel && mounted) {
        setState(() {
          _error = 'Ошибка загрузки. Попробуйте ещё раз.';
          _progress = null;
          _done = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Ошибка загрузки. Попробуйте ещё раз.';
          _progress = null;
          _done = false;
        });
      }
    }
  }

  Future<void> _openInstaller(String path) async {
    // Try file:// URI first (Android ≤ 6), then fall back to the web URL
    final fileUri = Uri.file(path);
    bool opened = false;
    try {
      opened = await launchUrl(fileUri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!opened) {
      await launchUrl(Uri.parse(widget.apkUrl), mode: LaunchMode.externalApplication);
    }
  }

  String get _statusLabel {
    if (_done) return 'Готово! Открываем установщик...';
    if (_progress == null || _progress == 0) return 'Подготовка...';
    return 'Загрузка ${(_progress! * 100).toStringAsFixed(0)}%';
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF5A623);
    final downloading = _progress != null && !_done;

    return PopScope(
      canPop: !widget.force && !downloading,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.system_update_rounded, color: orange),
            const SizedBox(width: 8),
            Text('Версия ${widget.version}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Доступно новое обновление приложения.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (widget.changelog.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.changelog,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
            if (_progress != null) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _progress == 0 ? null : _progress,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(orange),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 6),
              Text(_statusLabel, style: Theme.of(context).textTheme.bodySmall),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
          ],
        ),
        actions: [
          if (!widget.force && !downloading)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Позже'),
            ),
          if (_done)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: orange),
              onPressed: () => _openInstaller(_savedPath!),
              child: const Text('Установить', style: TextStyle(color: Colors.white)),
            )
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: orange),
              onPressed: downloading ? null : _startDownload,
              child: Text(
                downloading ? 'Загрузка...' : 'Обновить',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
