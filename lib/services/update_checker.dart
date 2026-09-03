import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker {
  // ==========================================
  // ↓ UPDATE INI SETIAP RILIS BARU ↓
  // ==========================================
  static const String currentVersion = '1.0.0';
  static const int currentBuild = 1;
  // ==========================================

  // ← Ganti dengan URL Railway kamu
  static const String _baseUrl = 'https://suntri-production.up.railway.app';
  static const String _versionEndpoint = '$_baseUrl/api/mobile/app-version';

  /// Cek versi terbaru dari server.
  /// Tampilkan dialog update jika ada versi baru.
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final response = await http
          .get(Uri.parse(_versionEndpoint))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final String latestVersion = data['version'] ?? '1.0.0';
      final int latestBuild = data['build'] as int? ?? 1;
      final String downloadUrl = data['download_url'] ?? '';
      final String notes = data['notes'] ?? '';
      final bool forceUpdate = data['force'] == true;

      // Tidak perlu update
      if (latestBuild <= currentBuild) return;
      if (downloadUrl.isEmpty) return;
      if (!context.mounted) return;

      _showUpdateDialog(
        context,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        downloadUrl: downloadUrl,
        notes: notes,
        force: forceUpdate,
      );
    } catch (e) {
      // Gagal cek update — lanjut saja, tidak ganggu user
      debugPrint('UpdateChecker: $e');
    }
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
