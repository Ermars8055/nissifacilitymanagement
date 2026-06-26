import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../network/api_client.dart';

class UpdateService {
  static Future<void> checkForUpdate(BuildContext context) async {
    if (!Platform.isAndroid) return; // APK updates only on Android

    try {
      final info = await PackageInfo.fromPlatform();
      final current = info.version; // e.g. "1.0.0"

      final data = await ApiClient.get('/Version/latest') as Map<String, dynamic>;
      final latest = data['version'] as String;
      final apkUrl = data['apkUrl'] as String;
      final notes = data['releaseNotes'] as String? ?? '';

      if (_isNewer(latest, current) && context.mounted) {
        _showUpdateDialog(context, latest, apkUrl, notes);
      }
    } catch (_) {
      // Silent fail — never block the user because of an update check
    }
  }

  static bool _isNewer(String latest, String current) {
    final l = latest.split('.').map(int.parse).toList();
    final c = current.split('.').map(int.parse).toList();
    for (int i = 0; i < 3; i++) {
      if ((l.elementAtOrNull(i) ?? 0) > (c.elementAtOrNull(i) ?? 0)) return true;
      if ((l.elementAtOrNull(i) ?? 0) < (c.elementAtOrNull(i) ?? 0)) return false;
    }
    return false;
  }

  static void _showUpdateDialog(BuildContext context, String version, String apkUrl, String notes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UpdateDialog(version: version, apkUrl: apkUrl, notes: notes),
    );
  }
}

class _UpdateDialog extends StatefulWidget {
  final String version;
  final String apkUrl;
  final String notes;
  const _UpdateDialog({required this.version, required this.apkUrl, required this.notes});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  Future<void> _download() async {
    setState(() { _downloading = true; _error = null; });
    try {
      final dir = await getExternalStorageDirectory() ?? await getTemporaryDirectory();
      final path = '${dir.path}/FacilityPro_update.apk';

      await Dio().download(
        widget.apkUrl,
        path,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _progress = received / total);
          }
        },
      );

      await OpenFile.open(path);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() { _downloading = false; _error = 'Download failed. Check your connection.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.system_update_rounded, color: Color(0xFF2D6B4F), size: 30),
          ),
          const SizedBox(height: 16),
          Text('Update Available — v${widget.version}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A1714)),
              textAlign: TextAlign.center),
          if (widget.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(widget.notes,
                style: const TextStyle(fontSize: 13, color: Color(0xFF8C8278), height: 1.4),
                textAlign: TextAlign.center),
          ],
          const SizedBox(height: 20),
          if (_downloading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                backgroundColor: const Color(0xFFEEE8DF),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2D6B4F)),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _progress > 0 ? 'Downloading... ${(_progress * 100).toStringAsFixed(0)}%' : 'Starting download...',
              style: const TextStyle(fontSize: 12, color: Color(0xFF8C8278)),
            ),
          ] else ...[
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(fontSize: 13, color: Color(0xFF9B2020))),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Later', style: TextStyle(color: Color(0xFF8C8278))),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: _download,
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(color: const Color(0xFF1E3D2F), borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Text('Update Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
