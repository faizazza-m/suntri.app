// ============================================================
// SUPABASE SERVICE
// Replaces Laravel API — direct connection to Supabase.
//
// SETUP: Run this SQL once in Supabase SQL Editor
// (Dashboard → SQL Editor → New Query):
//
// CREATE EXTENSION IF NOT EXISTS pgcrypto;
//
// CREATE OR REPLACE FUNCTION verify_login(p_email TEXT, p_password TEXT)
// RETURNS TABLE(id BIGINT, name TEXT, email TEXT, role_id INT, role_name TEXT, is_active INT)
// LANGUAGE plpgsql SECURITY DEFINER AS $$
// DECLARE v_hash TEXT;
// BEGIN
//   SELECT replace(u.password, '$2y$', '$2a$') INTO v_hash
//   FROM users u WHERE u.email = p_email AND u.is_active = 1;
//   IF v_hash IS NULL THEN RETURN; END IF;
//   RETURN QUERY
//     SELECT u.id, u.name, u.email, u.role_id, r.name::TEXT, u.is_active
//     FROM users u
//     JOIN roles r ON r.id = u.role_id
//     WHERE u.email = p_email AND crypt(p_password, v_hash) = v_hash;
// END; $$;
//
// GRANT EXECUTE ON FUNCTION verify_login(TEXT, TEXT) TO anon;
// ============================================================

import 'dart:convert';
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_dotenv/flutter_dotenv.dart';

String get _supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
String get _supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

// Role ID → App Role name mapping (from Supabase roles table)
const Map<int, String> _roleMap = {
  1: 'Admin',
  2: 'Musyrif',
  3: 'Wali',
  4: 'Santri',
  5: 'Guru',
  6: 'Mudir',
};

class SupabaseService {
  static Map<String, String> get _headers => {
        'apikey': _supabaseAnonKey,
        'Authorization': 'Bearer $_supabaseAnonKey',
        'Content-Type': 'application/json',
      };

  // ─── Generic GET helper ──────────────────────────────────────
  static Future<List<dynamic>> _getTable(String table,
      {String? select, String? extraQuery}) async {
    var urlStr = '$_supabaseUrl/rest/v1/$table';
    final params = <String>[];
    if (select != null) params.add('select=${Uri.encodeComponent(select)}');
    if (extraQuery != null) params.add(extraQuery);
    if (params.isNotEmpty) urlStr += '?${params.join('&')}';

    try {
      final response =
          await http.get(Uri.parse(urlStr), headers: _headers).timeout(
                const Duration(seconds: 15),
              );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded;
      }
      debugPrint('Supabase GET $table → ${response.statusCode}: ${response.body}');
    } catch (e) {
      debugPrint('Supabase GET $table error: $e');
    }
    return [];
  }

  // ─── Generic POST helper ─────────────────────────────────────
  static Future<Map<String, dynamic>?> postTable(String table, Map<String, dynamic> data, {bool upsert = false}) async {
    var urlStr = '$_supabaseUrl/rest/v1/$table';
    final customHeaders = Map<String, String>.from(_headers);
    if (upsert) {
      customHeaders['Prefer'] = 'return=representation, resolution=merge-duplicates';
    } else {
      customHeaders['Prefer'] = 'return=representation';
    }

    try {
      final response = await http
          .post(Uri.parse(urlStr), headers: customHeaders, body: jsonEncode(data))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final List<dynamic> resData = jsonDecode(response.body);
        if (resData.isNotEmpty) return resData.first as Map<String, dynamic>;
      } else {
        debugPrint('POST error on $table: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('POST exception on $table: $e');
    }
    return null;
  }

  // ─── LOGIN: query users table directly, verify bcrypt client-side ──
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      String? resolvedEmail = email;
      final bool isEmail = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);

      // If it's not an email, assume it's a NIS and try to find the Wali's email
      if (!isEmail) {
        final santriUrl = '$_supabaseUrl/rest/v1/santri?nis=eq.${Uri.encodeComponent(email)}&select=id&limit=1';
        final santriRes = await http.get(Uri.parse(santriUrl), headers: _headers);
        if (santriRes.statusCode == 200) {
          final santriRows = jsonDecode(santriRes.body);
          if (santriRows is List && santriRows.isNotEmpty) {
            final santriId = santriRows[0]['id'];
            final waliUrl = '$_supabaseUrl/rest/v1/wali_santri?santri_id=eq.$santriId&select=user_id&limit=1';
            final waliRes = await http.get(Uri.parse(waliUrl), headers: _headers);
            if (waliRes.statusCode == 200) {
              final waliRows = jsonDecode(waliRes.body);
              if (waliRows is List && waliRows.isNotEmpty) {
                final userId = waliRows[0]['user_id'];
                final userUrl = '$_supabaseUrl/rest/v1/users?id=eq.$userId&select=email&limit=1';
                final userRes = await http.get(Uri.parse(userUrl), headers: _headers);
                if (userRes.statusCode == 200) {
                  final userRows = jsonDecode(userRes.body);
                  if (userRows is List && userRows.isNotEmpty) {
                    resolvedEmail = userRows[0]['email'];
                  }
                }
              }
            }
          }
        }
      }

      // 1. Fetch user by email (include password hash + contact info)
      final url =
          '$_supabaseUrl/rest/v1/users?email=eq.${Uri.encodeComponent(resolvedEmail ?? email)}'
          '&select=id,name,email,role_id,is_active,password,phone&limit=1';
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return {'status': 'error', 'message': 'Gagal menghubungi server (${response.statusCode})'};
      }

      final rows = jsonDecode(response.body);
      if (rows is! List || rows.isEmpty) {
        return {'status': 'error', 'message': isEmail ? 'Email tidak ditemukan' : 'NIS tidak ditemukan atau akun Wali belum ditautkan'};
      }

      final u = rows[0] as Map<String, dynamic>;

      // 2. Check account active
      if (u['is_active'] != 1 && u['is_active'] != true) {
        return {'status': 'error', 'message': 'Akun tidak aktif'};
      }

      // 3. Verify bcrypt password (PHP uses $2y$, bcrypt lib uses $2a$ - equivalent)
      final storedHash = (u['password'] as String? ?? '')
          .replaceFirst('\$2y\$', '\$2a\$');
      if (storedHash.isEmpty) {
        return {'status': 'error', 'message': 'Password tidak terkonfigurasi'};
      }

      final isValid = BCrypt.checkpw(password, storedHash);
      if (!isValid) {
        return {'status': 'error', 'message': 'Password salah'};
      }

      // 4. Build user object
      final roleId = (u['role_id'] as int?) ?? 1;
      final roleName = _roleMap[roleId] ?? 'Admin';
      return {
        'status': 'success',
        'user': {
          'id': u['id'].toString(),
          'name': u['name'],
          'email': u['email'],
          'phone': u['phone'] ?? '',
          'role': roleName,
          'role_id': roleId,
          'is_active': u['is_active'],
        },
      };
    } catch (e) {
      debugPrint('SupabaseService.login error: $e');
      return {'status': 'error', 'message': 'Gagal terhubung ke Supabase: $e'};
    }
  }

  // ─── UPDATE PROFILE ─────────────────────────────────────────
  static Future<Map<String, dynamic>> updateProfile({
    required String id,
    required String email,
    required String phone,
    String? newPassword,
  }) async {
    try {
      final url = '$_supabaseUrl/rest/v1/users?id=eq.$id';
      final payload = <String, dynamic>{
        'email': email,
        'phone': phone,
      };
      
      if (newPassword != null && newPassword.isNotEmpty) {
        // Hash it like Laravel does ($2y$)
        final hashed = BCrypt.hashpw(newPassword, BCrypt.gensalt());
        final laravelHash = hashed.replaceFirst('\$2a\$', '\$2y\$');
        payload['password'] = laravelHash;
      }

      final response = await http.patch(
        Uri.parse(url),
        headers: {
          ..._headers,
          'Prefer': 'return=minimal',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'status': 'success'};
      } else {
        return {'status': 'error', 'message': 'Gagal update profil (${response.statusCode})'};
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ─── FULL DATA SYNC ───────────────────────────────────────────
  static Future<Map<String, dynamic>> syncAll() async {
    try {
      // Fetch all tables in parallel
      final results = await Future.wait([
        _getTable('santri'),                                // 0
        _getTable('kelas'),                                 // 1
        _getTable('halaqoh'),                               // 2
        _getTable('users', select: 'id,name,role_id'),     // 3
        _getTable('setoran'),                               // 4
        _getTable('perizinan'),                             // 5
        _getTable('rekam_kesehatan'),                       // 6
        _getTable('kamar'),                                 // 7
        _getTable('penghuni_kamar'),                        // 8
        _getTable('tagihan'),                               // 9
        _getTable('nilai_akademik'),                        // 10
        _getTable('mata_pelajaran'),                        // 11
        _getTable('jadwal_pelajaran'),                      // 12
        _getTable('pengumuman',
            select: 'id,judul,isi,target,is_pinned,dibuat_oleh,published_at',
            extraQuery: 'order=is_pinned.desc,id.desc'),   // 13
        _getTable('wali_santri'),                           // 14
        _getTable('hafalan_santri'),                        // 15
        _getTable('laporan_gurus'),                         // 16
        _getTable('kehadiran'),                             // 17
        _getTable('messages'),                              // 18
        _getTable('jenis_tagihan'),                         // 19
      ]);

      final rawSantri       = results[0];
      final rawKelas        = results[1];
      final rawHalaqoh      = results[2];
      final rawUsers        = results[3];
      final rawSetoran      = results[4];
      final rawPerizinan    = results[5];
      final rawKesehatan    = results[6];
      final rawKamar        = results[7];
      final rawPenghuni     = results[8];
      final rawTagihan      = results[9];
      final rawNilai        = results[10];
      final rawMapel        = results[11];
      final rawJadwal       = results[12];
      final rawPengumuman   = results[13];
      final rawWali         = results[14];
      final rawHafalan      = results[15];
      final rawJurnals      = results[16];
      final rawKehadiran    = results[17];
      final rawMessages     = results[18];
      final rawJenisTagihan = results[19];

      // ── Lookup maps ─────────────────────────────────────────
      final Map<int, String> kelasMap = {
        for (var k in rawKelas) (k['id'] as int): (k['nama'] ?? '') as String
      };
      final Map<int, String> halaqohMap = {
        for (var h in rawHalaqoh) (h['id'] as int): (h['nama'] ?? '') as String
      };
      final Map<int, int> halaqohMusyrifMap = {
        for (var h in rawHalaqoh)
          (h['id'] as int): (h['musyrif_id'] as int? ?? 0)
      };
      final Map<int, String> userNameMap = {
        for (var u in rawUsers) (u['id'] as int): (u['name'] ?? '') as String
      };
      final Map<int, int> mapelGuruMap = {
        for (var m in rawMapel)
          (m['id'] as int): (m['guru_id'] as int? ?? 0)
      };
      final Map<int, String> mapelNameMap = {
        for (var m in rawMapel) (m['id'] as int): (m['nama'] ?? '') as String
      };
      // juz per santri
      final Map<int, int> hafalanJuzMap = {
        for (var h in rawHafalan)
          (h['santri_id'] as int): (h['juz_selesai'] as int? ?? 0)
      };
      
      final Map<int, String> jenisTagihanMap = {
        for (var jt in rawJenisTagihan) (jt['id'] as int): (jt['nama'] ?? '') as String
      };
      final Map<int, String> jenisTagihanPeriodMap = {
        for (var jt in rawJenisTagihan) (jt['id'] as int): (jt['periode'] ?? '') as String
      };

      // Calculate Kehadiran per santri for the current month & 7 days trend
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;
      
      final Map<int, Map<String, int>> santriAttendanceMap = {};
      
      // For 7-days trend
      final List<double> attValues = [];
      final List<String> attLabels = [];
      final daysName = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Ahd'];
      
      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        attLabels.add(daysName[d.weekday - 1]);
        
        int hadir7 = 0;
        int total7 = 0;
        
        for (var k in rawKehadiran) {
          final dateStr = k['tanggal']?.toString() ?? '';
          if (dateStr.isNotEmpty) {
            try {
              final date = DateTime.parse(dateStr);
              // monthly per-student logic
              if (i == 6) { 
                // Only run this once per record (during the first pass or so, but let's just do it in a separate loop for clarity)
              }
              // 7-day logic
              if (date.year == d.year && date.month == d.month && date.day == d.day) {
                total7++;
                if ((k['status'] ?? '').toString().toLowerCase() == 'hadir') {
                  hadir7++;
                }
              }
            } catch (e) {
              // Ignore
            }
          }
        }
        double pct = total7 > 0 ? (hadir7 / total7) * 100 : 0.0;
        attValues.add(pct);
      }
      
      final attendance7Days = {'labels': attLabels, 'values': attValues};

      for (var k in rawKehadiran) {
        final dateStr = k['tanggal']?.toString() ?? '';
        if (dateStr.isNotEmpty) {
          try {
            final date = DateTime.parse(dateStr);
            if (date.month == currentMonth && date.year == currentYear) {
              final sId = k['santri_id'] as int;
              final status = (k['status'] ?? '').toString().toLowerCase();
              
              santriAttendanceMap.putIfAbsent(sId, () => {'hadir': 0, 'sakit': 0, 'izin': 0, 'alpha': 0});
              if (status == 'hadir') santriAttendanceMap[sId]!['hadir'] = (santriAttendanceMap[sId]!['hadir']! + 1);
              if (status == 'sakit') santriAttendanceMap[sId]!['sakit'] = (santriAttendanceMap[sId]!['sakit']! + 1);
              if (status == 'izin') santriAttendanceMap[sId]!['izin'] = (santriAttendanceMap[sId]!['izin']! + 1);
              if (status == 'alpha') santriAttendanceMap[sId]!['alpha'] = (santriAttendanceMap[sId]!['alpha']! + 1);
            }
          } catch (e) {
            // Ignore parse errors
          }
        }
      }

      // ── 1. Students ─────────────────────────────────────────
      final students = rawSantri.map((s) {
        final santriId = s['id'] as int;
        final kelasId = s['kelas_id'] as int? ?? 0;
        final halaqohId = s['halaqoh_id'] as int? ?? 0;
        final attendance = santriAttendanceMap[santriId] ?? {'hadir': 0, 'sakit': 0, 'izin': 0, 'alpha': 0};
        
        return {
          'id': santriId.toString(),
          'name': s['nama'] ?? '',
          'nis': s['nis'] ?? '',
          'class': kelasMap[kelasId] ?? 'Kelas ?',
          'halaqoh': halaqohMap[halaqohId] ?? '',
          'juz': hafalanJuzMap[santriId] ?? 0,
          'gender': s['jenis_kelamin'] ?? 'L',
          'status': s['status'] ?? 'aktif',
          'attendance': attendance,
        };
      }).toList();

      // ── 2. Halaqohs ─────────────────────────────────────────
      final Map<int, List<String>> halaqohStudentIds = {};
      for (var s in rawSantri) {
        final hId = s['halaqoh_id'] as int?;
        if (hId != null) {
          halaqohStudentIds.putIfAbsent(hId, () => []);
          halaqohStudentIds[hId]!.add((s['id'] as int).toString());
        }
      }
      final halaqohs = rawHalaqoh.map((h) {
        final hId = h['id'] as int;
        final musyrifId = h['musyrif_id'] as int? ?? 0;
        return {
          'id': hId.toString(),
          'name': h['nama'] ?? '',
          'teacher': userNameMap[musyrifId] ?? 'Musyrif',
          'studentIds': halaqohStudentIds[hId] ?? [],
        };
      }).toList();

      // ── 3. Setorans ─────────────────────────────────────────
      final Map<int, String> santriNameMap = {
        for (var s in rawSantri) (s['id'] as int): (s['nama'] ?? '') as String
      };
      final Map<int, int> santriHalaqohMap = {
        for (var s in rawSantri)
          (s['id'] as int): (s['halaqoh_id'] as int? ?? 0)
      };

      final setorans = rawSetoran.map((s) {
        final santriId = s['santri_id'] as int? ?? 0;
        final musyrifId = s['musyrif_id'] as int? ?? 0;
        final halaqohId = santriHalaqohMap[santriId] ?? 0;
        return {
          'id': (s['id'] as int).toString(),
          'santriId': santriId.toString(),
          'studentName': santriNameMap[santriId] ?? 'Santri',
          'halaqoh': halaqohMap[halaqohId] ?? '',
          'musyrif': userNameMap[musyrifId] ?? 'Musyrif',
          'type': s['jenis'] ?? '',
          'surah': s['surah']?.toString() ?? '',
          'juz': s['juz'] ?? 0,
          'ayatDari': s['ayat_dari'] ?? 0,
          'ayatSampai': s['ayat_sampai'] ?? 0,
          'kelancaran': () {
            switch (s['nilai']) {
              case 'Mumtaz': return 'Sangat Baik';
              case 'Jayyid Jiddan': return 'Baik';
              case 'Jayyid': return 'Baik';
              case 'Maqbul': return 'Cukup';
              case 'Rosib': return 'Kurang';
              default: return s['nilai'] ?? 'Baik';
            }
          }(),
          'tajwid': 'Baik',
          'makharijul': 'Baik',
          'catatan': s['catatan'] ?? '',
          'date': s['tanggal'] ?? '',
          'time': s['created_at'] != null
              ? _formatTime(s['created_at'].toString())
              : '',
        };
      }).toList();

      // ── 4. Permissions (Perizinan) ───────────────────────────
      final permissions = rawPerizinan.map((p) {
        final santriId = p['santri_id'] as int? ?? 0;
        return {
          'id': (p['id'] as int).toString(),
          'santriId': santriId.toString(),
          'studentName': santriNameMap[santriId] ?? 'Santri',
          'type': p['jenis'] ?? '',
          'reason': p['alasan'] ?? '',
          'startDate': p['tanggal_mulai'] ?? '',
          'endDate': p['tanggal_selesai'] ?? '',
          'status': p['status'] ?? 'pending',
          'date': p['created_at'] ?? '',
        };
      }).toList();

      // ── 5. Medical Records ───────────────────────────────────
      final medicalRecords = rawKesehatan.map((m) {
        final santriId = m['santri_id'] as int? ?? 0;
        return {
          'id': (m['id'] as int).toString(),
          'santriId': santriId.toString(),
          'studentName': santriNameMap[santriId] ?? 'Santri',
          'complaint': m['keluhan'] ?? '',
          'diagnosis': m['diagnosa'] ?? '',
          'treatment': m['tindakan'] ?? '',
          'referred': m['dirujuk'] == true || m['dirujuk'] == 1,
          'date': m['tanggal'] ?? m['created_at'] ?? '',
        };
      }).toList();

      // ── 6. Rooms ─────────────────────────────────────────────
      final Map<int, List<String>> kamarPenghuniMap = {};
      for (var ph in rawPenghuni) {
        final kamarId = ph['kamar_id'] as int?;
        final santriId = ph['santri_id'] as int?;
        if (kamarId != null && santriId != null) {
          kamarPenghuniMap.putIfAbsent(kamarId, () => []);
          kamarPenghuniMap[kamarId]!.add(santriId.toString());
        }
      }
      final rooms = rawKamar.map((k) {
        final kamarId = k['id'] as int;
        return {
          'id': kamarId.toString(),
          'name': k['nama'] ?? k['nomor'] ?? 'Kamar',
          'capacity': k['kapasitas'] ?? 0,
          'occupants': kamarPenghuniMap[kamarId] ?? [],
        };
      }).toList();

      // ── 7. Bills ─────────────────────────────────────────────
      final bills = rawTagihan.map((t) {
        final santriId = t['santri_id'] as int? ?? 0;
        final jenisId = t['jenis_id'] as int? ?? 0;
        return {
          'id': (t['id'] as int).toString(),
          'santriId': santriId.toString(),
          'studentName': santriNameMap[santriId] ?? 'Santri',
          'type': jenisTagihanMap[jenisId] ?? 'Tagihan',
          'period': jenisTagihanPeriodMap[jenisId] ?? '',
          'amount': (t['nominal'] ?? 0).toString(),
          'month': t['bulan']?.toString() ?? '',
          'year': t['tahun']?.toString() ?? '',
          'status': t['status'] ?? 'belum_lunas',
          'dueDate': t['tenggat_waktu'] ?? '',
        };
      }).toList();

      // ── 8. Grades ────────────────────────────────────────────
      final grades = rawNilai.map((g) {
        final santriId = g['santri_id'] as int? ?? 0;
        final mapelId = g['mapel_id'] as int? ?? 0;
        return {
          'id': (g['id'] as int).toString(),
          'studentName': santriNameMap[santriId] ?? 'Santri',
          'santriId': santriId.toString(),
          'subject': mapelNameMap[mapelId] ?? '',
          'daily': g['nilai_harian'] ?? 0,
          'uts': g['nilai_uts'] ?? 0,
          'uas': g['nilai_uas'] ?? 0,
          'final': g['nilai_akhir'] ?? 0,
        };
      }).toList();

      // ── 9. Schedules (Jadwal Pelajaran) ──────────────────────
      final schedules = rawJadwal.map((j) {
        final kelasId = j['kelas_id'] as int? ?? 0;
        final mapelId = j['mapel_id'] as int? ?? 0;
        final guruId = mapelGuruMap[mapelId] ?? 0;
        return {
          'id': (j['id'] as int).toString(),
          'class': kelasMap[kelasId] ?? '',
          'subject': mapelNameMap[mapelId] ?? '',
          'teacherId': guruId.toString(),
          'teacherName': userNameMap[guruId] ?? 'Guru',
          'day': j['hari'] ?? '',
          'timeStart': _trimTime(j['jam_mulai']?.toString() ?? '07:00'),
          'timeEnd': _trimTime(j['jam_selesai']?.toString() ?? '08:00'),
          'room': j['ruang'] ?? '',
        };
      }).toList();

      // ── 10. Announcements ────────────────────────────────────
      final announcements = rawPengumuman.map((p) {
        return {
          'id': (p['id'] as int).toString(),
          'title': p['judul'] ?? '',
          'body': p['isi'] ?? '',
          'target': p['target'] ?? 'semua',
          'isPinned': p['is_pinned'] == true || p['is_pinned'] == 1,
          'author': userNameMap[p['dibuat_oleh'] as int? ?? 0] ?? 'Admin',
          'date': p['published_at'] != null
              ? _formatDateRelative(p['published_at'].toString())
              : '',
          'rawDate': p['published_at']?.toString(),
        };
      }).toList();

      // ── 11. Wali-Santri map ──────────────────────────────────
      final waliSantriMap = rawWali.map((w) {
        final userId = w['user_id'] as int? ?? 0;
        final santriId = w['santri_id'] as int? ?? 0;
        return {
          'userId': userId.toString(),
          'santriId': santriId.toString(),
          'nama': w['nama'] ?? '',
          'hubungan': w['hubungan'] ?? '',
          'phone': w['phone'] ?? '',
        };
      }).toList();

      // ── 12. Jurnals (Laporan Guru) ───────────────────────────
      final jurnals = rawJurnals.map((j) {
        return {
          'id': (j['id'] as int).toString(),
          'teacherId': j['guru_id']?.toString() ?? '0',
          'teacher': userNameMap[j['guru_id'] as int? ?? 0] ?? 'Unknown',
          'date': j['tanggal'] ?? '',
          'class': j['kelas'] ?? '',
          'subject': j['mata_pelajaran'] ?? '',
          'topic': j['materi'] ?? '',
          'notes': j['isi_laporan'] ?? '',
        };
      }).toList();

      // ── 13. Chat (Messages) ─────────────────────────────────
      final messagesList = rawMessages.map((m) {
        return {
          'id': m['id'].toString(),
          'senderId': m['sender_id']?.toString() ?? '',
          'receiverId': m['receiver_id']?.toString() ?? '',
          'text': m['content'] ?? '',
          'isRead': m['is_read'] == 1 || m['is_read'] == true,
          'time': m['created_at'] != null ? _formatTime(m['created_at'].toString()) : '',
          'timestamp': m['created_at'] ?? '',
        };
      }).toList()
        ..sort((a, b) => (a['timestamp'] as String).compareTo(b['timestamp'] as String));

      // ── 14. App Users ───────────────────────────────────────
      final appUsers = rawUsers.map((u) {
        final roleId = u['role_id'] as int? ?? 1;
        String roleName = 'Admin';
        if (roleId == 5) roleName = 'Guru';
        if (roleId == 2) roleName = 'Musyrif';
        if (roleId == 3) roleName = 'Wali';
        if (roleId == 6) roleName = 'Mudir';

        return {
          'id': (u['id'] as int).toString(),
          'name': u['name'] ?? '',
          'role': roleName,
        };
      }).toList();

      return {
        'students': students,
        'halaqohs': halaqohs,
        'setorans': setorans,
        'permissions': permissions,
        'medicalRecords': medicalRecords,
        'rooms': rooms,
        'bills': bills,
        'grades': grades,
        'schedules': schedules,
        'announcements': announcements,
        'waliSantri': waliSantriMap,
        'jurnals': jurnals,
        'messages': messagesList,
        'appUsers': appUsers,
        'attendance7Days': attendance7Days,
        'activities': [], // activities will be built from recent setorans
      };
    } catch (e) {
      debugPrint('SupabaseService.syncAll error: $e');
      return {};
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────
  static String _trimTime(String t) {
    // '07:30:00' → '07:30'
    if (t.length >= 5) return t.substring(0, 5);
    return t;
  }

  static String _formatTime(String isoStr) {
    try {
      final dt = DateTime.parse(isoStr).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  static String _formatDateRelative(String isoStr) {
    try {
      final dt = DateTime.parse(isoStr).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 30) return '${dt.day}/${dt.month}/${dt.year}';
      if (diff.inDays > 1) return '${diff.inDays} hari lalu';
      if (diff.inDays == 1) return 'Kemarin';
      if (diff.inHours >= 1) return '${diff.inHours} jam lalu';
      if (diff.inMinutes >= 1) return '${diff.inMinutes} menit lalu';
      return 'Baru saja';
    } catch (_) {
      return '';
    }
  }
}
