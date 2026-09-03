import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker {
  // ==========================================
  // ↓ UPDATE INI SETIAP RILIS BARU ↓
  // ==========================================
  static const String currentVersion = '1.0.1';
  static const int currentBuild = 2;
  // ==========================================

  // ← Endpoint GitHub Repository Releases
  static const String _githubRepo = 'faizazza-m/suntri.app';
  static const String _versionEndpoint = 'https://api.github.com/repos/$_githubRepo/releases/latest';

  /// Cek versi terbaru dari GitHub Releases.
  /// Tampilkan dialog update jika ada versi baru (berdasarkan tag_name).
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final response = await http
          .get(Uri.parse(_versionEndpoint))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      // Ambil tag_name dari GitHub (contoh: "v1.0.1" atau "1.0.1")
      String latestVersion = data['tag_name'] ?? '1.0.0';
      latestVersion = latestVersion.replaceAll(RegExp(r'[^0-9.]'), ''); // bersihkan huruf 'v'

      final String notes = data['body'] ?? 'Pembaruan bug dan optimalisasi sistem.';
      
      // Cari link download APK dari Assets
      String downloadUrl = '';
      if (data['assets'] != null && (data['assets'] as List).isNotEmpty) {
        final assets = data['assets'] as List;
        for (var asset in assets) {
          final url = asset['browser_download_url']?.toString() ?? '';
          if (url.endsWith('.apk')) {
            downloadUrl = url;
            break;
          }
        }
        if (downloadUrl.isEmpty) {
          downloadUrl = assets[0]['browser_download_url'] ?? '';
        }
      }

      if (downloadUrl.isEmpty) {
        downloadUrl = data['html_url'] ?? ''; // fallback ke halaman rilis github
      }

      // Bandingkan versi
      if (!_isNewer(latestVersion, currentVersion)) return;
      if (!context.mounted) return;

      _showUpdateDialog(
        context,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        downloadUrl: downloadUrl,
        notes: notes,
        force: false, // Bebas kalau dari GitHub
      );
    } catch (e) {
      debugPrint('UpdateChecker GitHub: $e');
    }
  }

  // Fungsi utilitas untuk membandingkan semantik versi (contoh: 1.0.1 > 1.0.0)
  static bool _isNewer(String latest, String current) {
    try {
      final l = latest.split('.');
      final c = current.split('.');
      final length = l.length > c.length ? l.length : c.length;
      
      for (int i = 0; i < length; i++) {
        final lVal = i < l.length ? int.tryParse(l[i]) ?? 0 : 0;
        final cVal = i < c.length ? int.tryParse(c[i]) ?? 0 : 0;
        if (lVal > cVal) return true;
        if (lVal < cVal) return false;
      }
    } catch (_) {}
    return false;
  }

  static void _showUpdateDialog(
    BuildContext context, {
    required String currentVersion,
    required String latestVersion,
    required String downloadUrl,
    required String notes,
    required bool force,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !force,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF107B5C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.system_update_rounded,
                  color: Color(0xFF107B5C), size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Update Tersedia',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _versionBadge('Sekarang', currentVersion, Colors.grey),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                const SizedBox(width: 8),
                _versionBadge('Terbaru', latestVersion, const Color(0xFF107B5C)),
              ],
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Perubahan:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              Text(notes,
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ],
        ),
        actions: [
          if (!force)
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Nanti', style: TextStyle(color: Colors.grey)),
            ),
          ElevatedButton.icon(
            onPressed: () async {
              final uri = Uri.parse(downloadUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Download Update'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF107B5C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _versionBadge(String label, String version, Color color) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 9, color: color, fontWeight: FontWeight.bold)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('v$version',
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
