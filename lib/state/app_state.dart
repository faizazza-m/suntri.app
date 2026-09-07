import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';

class AppState extends ChangeNotifier {
  // Supabase base URL (used by write methods until fully migrated)
  static const String baseUrl = 'https://ncwafymkpxogbjzcpoya.supabase.co';
  static const Map<String, String> _sbHeaders = {
    'apikey':
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5jd2FmeW1rcHhvZ2JqemNwb3lhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYzMzQ1MTgsImV4cCI6MjEwMTkxMDUxOH0.lPZkCRmrAXV5FuRw0b-j_uJLw-2Hx6mLSFOGZ4oq4SI',
    'Authorization':
        'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5jd2FmeW1rcHhvZ2JqemNwb3lhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYzMzQ1MTgsImV4cCI6MjEwMTkxMDUxOH0.lPZkCRmrAXV5FuRw0b-j_uJLw-2Hx6mLSFOGZ4oq4SI',
    'Content-Type': 'application/json',
  };

  // Current active role for session control
  String _activeRole = 'Admin';
  String get activeRole => _activeRole;

  Map<String, dynamic>? _currentUser;
  Map<String, dynamic>? get currentUser => _currentUser;

  void setActiveRole(String role) {
    _activeRole = role;
    notifyListeners();
  }

  // Active notification feed
  final List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> get activities => _activities;

  // Master Schedules (Jadwal Pelajaran) Data
  final List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> get schedules => _schedules;

  // Announcements (Pengumuman)
  final List<Map<String, dynamic>> _announcements = [];
  List<Map<String, dynamic>> get announcements => _announcements;

  // Jurnals (Laporan Guru)
  final List<Map<String, dynamic>> _jurnals = [];
  List<Map<String, dynamic>> get jurnals => _jurnals;

  // Chats (Konsultasi)
  final List<Map<String, dynamic>> _chats = [];
  List<Map<String, dynamic>> get chats => _chats;

  // Wali Santri
  final List<Map<String, dynamic>> _waliSantri = [];
  List<Map<String, dynamic>> get waliSantri => _waliSantri;

  // App Users
  final List<Map<String, dynamic>> _appUsers = [];
  List<Map<String, dynamic>> get appUsers => _appUsers;

  void addActivity(String title, String description, String type, Color color, String tag) {
    _activities.insert(0, {
      'id': 'act_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'description': description,
      'time': 'Baru saja',
      'type': type,
      'tag': tag,
      'color': color,
    });
    notifyListeners();
  }

  // Master Santri Data
  final List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> get students => _students;

  Future<void> addStudent(Map<String, dynamic> student) async {
    // Eager local insert
    _students.add(student);
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/mobile/student'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nis': student['nis'],
          'name': student['name'],
          'gender': student['gender'] ?? 'L',
          'class': student['class'],
        }),
      );
      if (response.statusCode == 200) {
        await syncFromDatabase();
      }
    } catch (e) {
      debugPrint('Error adding student: $e');
    }
  }

  void updateStudentJuz(String studentId, int juz) {
    final idx = _students.indexWhere((s) => s['id'] == studentId);
    if (idx != -1) {
      _students[idx]['juz'] = juz;
      notifyListeners();
    }
  }

  // Master Halaqoh Data
  final List<Map<String, dynamic>> _halaqohs = [];
  List<Map<String, dynamic>> get halaqohs => _halaqohs;

  Future<void> addHalaqoh(String name, String teacher, List<String> studentIds) async {
    // Eager local insert
    _halaqohs.add({
      'id': 'hq_${DateTime.now().millisecondsSinceEpoch}',
      'name': name,
      'teacher': teacher,
      'studentIds': studentIds,
    });
    addActivity('Halaqoh Dibuat', 'Halaqoh "$name" telah dibuat oleh Admin.', 'Tahfizh', Colors.orange, 'TAHFIZH');
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/mobile/halaqoh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'teacher': teacher,
        }),
      );
      if (response.statusCode == 200) {
        await syncFromDatabase();
      }
    } catch (e) {
      debugPrint('Error adding halaqoh: $e');
    }
  }

  Future<void> updateHalaqoh(String id, String name, String teacher, List<String> studentIds) async {
    final idx = _halaqohs.indexWhere((h) => h['id'] == id);
    if (idx != -1) {
      _halaqohs[idx] = {
        'id': id,
        'name': name,
        'teacher': teacher,
        'studentIds': studentIds,
      };
      notifyListeners();
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/mobile/halaqoh/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'teacher': teacher,
        }),
      );
      if (response.statusCode == 200) {
        await syncFromDatabase();
      }
    } catch (e) {
      debugPrint('Error updating halaqoh: $e');
    }
  }

  Future<void> deleteHalaqoh(String id) async {
    _halaqohs.removeWhere((h) => h['id'] == id);
    notifyListeners();

    try {
      final response = await http.delete(Uri.parse('$baseUrl/api/mobile/halaqoh/$id'));
      if (response.statusCode == 200) {
        await syncFromDatabase();
      }
    } catch (e) {
      debugPrint('Error deleting halaqoh: $e');
    }
  }

  // Tahfizh Setoran Records
  final List<Map<String, dynamic>> _setorans = [];
  List<Map<String, dynamic>> get setorans => _setorans;

  Future<void> addSetoran(Map<String, dynamic> setoran) async {
    // Eager local insert
    _setorans.insert(0, setoran);

    // Auto-update student juz based on custom target logic
    final studentIndex = _students.indexWhere((s) => s['name'] == setoran['studentName']);
    if (studentIndex != -1) {
      int parsedJuz = int.tryParse(setoran['juz']?.toString() ?? '') ?? 1;
      if (parsedJuz > (_students[studentIndex]['juz'] as int? ?? 0)) {
        _students[studentIndex]['juz'] = parsedJuz;
        addActivity('Pencapaian Juz Baru', '${setoran['studentName']} naik ke Juz $parsedJuz!', 'Tahfizh', Colors.orange, 'TAHFIZH');
      }
    }

    addActivity(
      'Setoran Hafalan',
      '${setoran['studentName']} menyetor ${setoran['type']} surah ${setoran['surah']} juz ${setoran['juz']}.',
      'Tahfizh',
      Colors.orange,
      'TAHFIZH',
    );
    notifyListeners();

    try {
      // Resolve santri_id from local students list
      final studentObj = _students.firstWhere(
        (s) => s['name'] == setoran['studentName'],
        orElse: () => {},
      );
      final santriId = studentObj.isNotEmpty ? int.tryParse(studentObj['id'] ?? '') : null;
      if (santriId == null) {
        debugPrint('addSetoran: santri_id not found for ${setoran['studentName']}');
        return;
      }

      // Resolve musyrif_id from currentUser
      final musyrifId = int.tryParse(_currentUser?['id'] ?? '');

      // Map type label → DB enum value
      final typeInput = (setoran['type'] ?? '').toString().toLowerCase();
      String jenis;
      if (typeInput.contains('ziyadah') || typeInput.contains('hafalan')) {
        jenis = 'hafalan_baru';
      } else if (typeInput.contains('murajaah') || typeInput.contains('muraja')) {
        jenis = 'murajaah';
      } else {
        jenis = 'tasmi';
      }

      // Map kelancaran label → DB enum nilai
      final kelancaranInput = (setoran['kelancaran'] ?? '').toString().toLowerCase();
      String? nilaiDb;
      if (kelancaranInput.contains('sangat baik') || kelancaranInput.contains('mumtaz')) {
        nilaiDb = 'Mumtaz';
      } else if (kelancaranInput.contains('baik') || kelancaranInput.contains('jayyid jiddan')) {
        nilaiDb = 'Jayyid Jiddan';
      } else if (kelancaranInput.contains('cukup') || kelancaranInput.contains('jayyid')) {
        nilaiDb = 'Jayyid';
      } else if (kelancaranInput.contains('kurang') || kelancaranInput.contains('maqbul')) {
        nilaiDb = 'Maqbul';
      } else {
        nilaiDb = 'Maqbul';
      }

      final tanggal = setoran['date']?.toString() ?? DateTime.now().toIso8601String().split('T')[0];

      final response = await http.post(
        Uri.parse('$baseUrl/rest/v1/setoran'),
        headers: {..._sbHeaders, 'Prefer': 'return=minimal'},
        body: jsonEncode({
          'santri_id': santriId,
          if (musyrifId != null) 'musyrif_id': musyrifId,
          'tanggal': tanggal,
          'jenis': jenis,
          'surah': setoran['surah']?.toString(),
          'juz': int.tryParse(setoran['juz']?.toString() ?? ''),
          'ayat_dari': int.tryParse(setoran['ayatDari']?.toString() ?? ''),
          'ayat_sampai': int.tryParse(setoran['ayatSampai']?.toString() ?? ''),
          'nilai': nilaiDb,
          'catatan': setoran['notes']?.toString() ?? setoran['catatan']?.toString() ?? '',
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('addSetoran: berhasil disimpan ke DB');
        await syncFromDatabase();
      } else {
        debugPrint('addSetoran error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Error adding setoran: $e');
    }
  }

  Future<void> deleteSetoran(String id) async {
    _setorans.removeWhere((s) => s['id'] == id);
    notifyListeners();

    try {
      final response = await http.delete(Uri.parse('$baseUrl/api/mobile/setoran/$id'));
      if (response.statusCode == 200) {
        await syncFromDatabase();
      }
    } catch (e) {
      debugPrint('Error deleting setoran: $e');
    }
  }

  // Perizinan Requests (4 types: Sakit, Pulang, Keluar, Liburan)
  final List<Map<String, dynamic>> _permissions = [];
  List<Map<String, dynamic>> get permissions => _permissions;

  Future<void> addPermission(Map<String, dynamic> perm) async {
    _permissions.insert(0, perm);
    addActivity(
      'Pengajuan Izin',
      'Santri ${perm['studentName']} mengajukan izin ${perm['type']}.',
      'Perizinan',
      Colors.purple,
      'PERIZINAN',
    );
    notifyListeners();

    try {
      final studentObj = _students.firstWhere(
        (s) => s['name'] == perm['studentName'],
        orElse: () => {},
      );
      final santriId = studentObj.isNotEmpty ? int.tryParse(studentObj['id'] ?? '') : null;
      if (santriId == null) return;

      final typeMap = {
        'Pulang': 'pulang',
        'Sakit': 'sakit',
        'Kegiatan Luar': 'kegiatan_luar',
      };
      final jenis = typeMap[perm['type']] ?? 'lainnya';

      await SupabaseService.postTable('perizinan', {
        'santri_id': santriId,
        'jenis': jenis,
        'tanggal_mulai': perm['dateStart'] ?? perm['startDate'],
        'tanggal_selesai': perm['dateEnd'] ?? perm['endDate'],
        'alasan': perm['reason'],
        'status': 'pending',
      });
      await syncFromDatabase();
    } catch (e) {
      debugPrint('Error adding permission: $e');
    }
  }

  Future<void> approvePermission(String id) async {
    final idx = _permissions.indexWhere((p) => p['id'] == id);
    if (idx != -1) {
      _permissions[idx]['status'] = 'Disetujui';
      addActivity(
        'Izin Disetujui',
        'Izin ${_permissions[idx]['type']} untuk ${_permissions[idx]['studentName']} telah disetujui.',
        'Perizinan',
        Colors.purple,
        'PERIZINAN',
      );
      notifyListeners();
    }

    try {
      final response = await http.post(Uri.parse('$baseUrl/api/mobile/permission/$id/approve'));
      if (response.statusCode == 200) {
        await syncFromDatabase();
      }
    } catch (e) {
      debugPrint('Error approving permission: $e');
    }
  }

  Future<void> rejectPermission(String id) async {
    final idx = _permissions.indexWhere((p) => p['id'] == id);
    if (idx != -1) {
      _permissions[idx]['status'] = 'Ditolak';
      addActivity(
        'Izin Ditolak',
        'Izin ${_permissions[idx]['type']} untuk ${_permissions[idx]['studentName']} ditolak oleh Admin.',
        'Perizinan',
        Colors.purple,
        'PERIZINAN',
      );
      notifyListeners();
    }

    try {
      final response = await http.post(Uri.parse('$baseUrl/api/mobile/permission/$id/reject'));
      if (response.statusCode == 200) {
        await syncFromDatabase();
      }
    } catch (e) {
      debugPrint('Error rejecting permission: $e');
    }
  }

  // UKS Medical Records (Kesehatan)
  final List<Map<String, dynamic>> _medicalRecords = [];
  List<Map<String, dynamic>> get medicalRecords => _medicalRecords;

  Future<void> addMedicalRecord(Map<String, dynamic> record) async {
    _medicalRecords.insert(0, record);
    addActivity(
      'Pencatatan UKS',
      'Kesehatan ${record['studentName']} dicatat di UKS: ${record['diagnosis']}.',
      'UKS',
      Colors.red,
      'KESEHATAN',
    );
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/mobile/medical-record'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'studentName': record['studentName'],
          'symptom': record['symptom'],
          'diagnosis': record['diagnosis'],
          'action': record['action'],
          'isReferredToLeave': record['isReferredToLeave'],
        }),
      );
      if (response.statusCode == 200) {
        await syncFromDatabase();
      }
    } catch (e) {
      debugPrint('Error adding medical record: $e');
    }
  }

  // Asrama (Kamar) Data
  final List<Map<String, dynamic>> _rooms = [];
  List<Map<String, dynamic>> get rooms => _rooms;

  void assignOccupant(String roomId, String studentName) {
    final idx = _rooms.indexWhere((r) => r['id'] == roomId);
    if (idx != -1) {
      if (!_rooms[idx]['occupants'].contains(studentName)) {
        _rooms[idx]['occupants'].add(studentName);
        addActivity(
          'Penghuni Asrama',
          '$studentName dipindahkan ke ${_rooms[idx]['name']}.',
          'Asrama',
          Colors.cyan,
          'ASRAMA',
        );
        notifyListeners();
      }
    }
  }

  void removeOccupant(String roomId, String studentName) {
    final idx = _rooms.indexWhere((r) => r['id'] == roomId);
    if (idx != -1) {
      _rooms[idx]['occupants'].remove(studentName);
      addActivity(
        'Penghuni Asrama',
        '$studentName dikeluarkan dari ${_rooms[idx]['name']}.',
        'Asrama',
        Colors.cyan,
        'ASRAMA',
      );
      notifyListeners();
    }
  }

  // Keuangan (Billing) Data
  final List<Map<String, dynamic>> _bills = [];
  List<Map<String, dynamic>> get bills => _bills;

  Future<void> generateBill({required String type, required String period, required double amount, String? targetClass, String? targetStudent}) async {
    List<String> affectedStudents = [];
    if (targetStudent != null) {
      affectedStudents.add(targetStudent);
    } else if (targetClass != null) {
      affectedStudents = _students.where((s) => s['class'] == targetClass).map((s) => s['name'] as String).toList();
    } else {
      affectedStudents = _students.map((s) => s['name'] as String).toList();
    }

    for (var name in affectedStudents) {
      _bills.insert(0, {
        'id': 'bill_${DateTime.now().millisecondsSinceEpoch}_${name.replaceAll(' ', '_')}',
        'studentName': name,
        'type': type,
        'period': period,
        'amount': amount,
        'status': 'Belum Bayar',
        'datePaid': null,
        'method': null,
        'notes': null,
      });
    }

    addActivity(
      'Tagihan Dibuat',
      'Generate tagihan $type periode $period untuk ${affectedStudents.length} santri.',
      'Keuangan',
      Colors.blue,
      'KEUANGAN',
    );
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/mobile/generate-bill'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': type,
          'period': period,
          'amount': amount,
          'targetClass': targetClass,
          'targetStudent': targetStudent,
        }),
      );
      if (response.statusCode == 200) {
        await syncFromDatabase();
      }
    } catch (e) {
      debugPrint('Error generating bill: $e');
    }
  }

  Future<void> payBill({required String billId, required double nominal, required String method, String? notes, required String date}) async {
    final idx = _bills.indexWhere((b) => b['id'] == billId);
    if (idx != -1) {
      if (_bills[idx]['status'] == 'Lunas') return;

      _bills[idx]['status'] = 'Lunas';
      _bills[idx]['datePaid'] = date;
      _bills[idx]['method'] = method;
      _bills[idx]['notes'] = notes;
      _bills[idx]['amount'] = nominal;

      addActivity(
        'Pembayaran Diterima',
        'Pembayaran ${bills[idx]['type']} dari ${_bills[idx]['studentName']} sukses dicatat via $method.',
        'Keuangan',
        Colors.blue,
        'KEUANGAN',
      );
      notifyListeners();
    }

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/rest/v1/tagihan?id=eq.$billId'),
        headers: _sbHeaders,
        body: jsonEncode({
          'status': 'lunas',
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        await syncFromDatabase();
      } else {
        debugPrint('Error paying bill to Supabase: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error paying bill: $e');
    }
  }

  // Academic Grade Database
  final List<Map<String, dynamic>> _grades = [];
  List<Map<String, dynamic>> get grades => _grades;

  Future<void> saveGrade({
    required String studentName,
    required String className,
    required String subject,
    required double tugas,
    required double uh,
    required double uts,
    required double uas,
  }) async {
    final score = (tugas * 0.2) + (uas * 0.8);
    final idx = _grades.indexWhere((g) => g['studentName'] == studentName && g['subject'] == subject);
    if (idx != -1) {
      _grades[idx] = {
        'id': _grades[idx]['id'],
        'studentName': studentName,
        'class': className,
        'subject': subject,
        'tugas': tugas,
        'uh': uh,
        'uts': uts,
        'uas': uas,
        'finalScore': double.parse(score.toStringAsFixed(1)),
      };
    } else {
      _grades.add({
        'id': 'gr_${DateTime.now().millisecondsSinceEpoch}',
        'studentName': studentName,
        'class': className,
        'subject': subject,
        'tugas': tugas,
        'uh': uh,
        'uts': uts,
        'uas': uas,
        'finalScore': double.parse(score.toStringAsFixed(1)),
      });
    }
    
    addActivity(
      'Nilai Diperbarui',
      'Nilai $subject untuk $studentName telah disimpan (Rata-rata: ${score.toStringAsFixed(1)}).',
      'Akademik',
      Colors.teal,
      'AKADEMIK',
    );
    notifyListeners();

    try {
      // Resolve santri_id from local students list
      final studentObj = _students.firstWhere(
        (s) => s['name'] == studentName,
        orElse: () => {},
      );
      final santriId = studentObj.isNotEmpty ? int.tryParse(studentObj['id'] ?? '') : null;
      if (santriId == null) {
        debugPrint('saveGrade: santri_id not found for $studentName');
        return;
      }

      // Resolve mapel_id from schedules list
      int? mapelId;
      for (final s in _schedules) {
        if (s['subject'] == subject) {
          // fetch mapel_id by querying schedules that match subject name
          break;
        }
      }

      // Fallback: fetch mapel_id directly from Supabase
      final mapelRes = await http.get(
        Uri.parse('$baseUrl/rest/v1/mata_pelajaran?nama=eq.${Uri.encodeComponent(subject)}&select=id&limit=1'),
        headers: _sbHeaders,
      );
      if (mapelRes.statusCode == 200) {
        final mapelData = jsonDecode(mapelRes.body) as List;
        if (mapelData.isNotEmpty) {
          mapelId = mapelData.first['id'] as int;
        }
      }

      if (mapelId == null) {
        debugPrint('saveGrade: mapel_id not found for subject: $subject');
        return;
      }

      final nilaiAkhir = score;
      
      // Determine current semester & tahun_ajaran automatically
      final now2 = DateTime.now();
      final month = now2.month;
      final semester = (month >= 7) ? 1 : 2;
      // Tahun ajaran: July-Dec = "year/year+1", Jan-Jun = "year-1/year"
      final startYear = (month >= 7) ? now2.year : now2.year - 1;
      final tahunAjaran = '$startYear/${startYear + 1}';

      // Check if record already exists (santri_id + mapel_id + semester + tahun_ajaran)
      final existRes = await http.get(
        Uri.parse(
          '$baseUrl/rest/v1/nilai_akademik?santri_id=eq.$santriId&mapel_id=eq.$mapelId&semester=eq.$semester&tahun_ajaran=eq.${Uri.encodeComponent(tahunAjaran)}&select=id&limit=1',
        ),
        headers: _sbHeaders,
      );

      final body = jsonEncode({
        'santri_id': santriId,
        'mapel_id': mapelId,
        'semester': semester,
        'tahun_ajaran': tahunAjaran,
        'nilai_harian': tugas,
        'nilai_uas': uas,
        'nilai_akhir': nilaiAkhir,
      });

      http.Response response;
      if (existRes.statusCode == 200) {
        final existData = jsonDecode(existRes.body) as List;
        if (existData.isNotEmpty) {
          // UPDATE existing record
          final existingId = existData.first['id'];
          response = await http.patch(
            Uri.parse('$baseUrl/rest/v1/nilai_akademik?id=eq.$existingId'),
            headers: {..._sbHeaders, 'Prefer': 'return=minimal'},
            body: body,
          );
        } else {
          // INSERT new record
          response = await http.post(
            Uri.parse('$baseUrl/rest/v1/nilai_akademik'),
            headers: {..._sbHeaders, 'Prefer': 'return=minimal'},
            body: body,
          );
        }
      } else {
        // Fallback: INSERT
        response = await http.post(
          Uri.parse('$baseUrl/rest/v1/nilai_akademik'),
          headers: {..._sbHeaders, 'Prefer': 'return=minimal'},
          body: body,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('saveGrade: berhasil disimpan ke DB');
        await syncFromDatabase();
      } else {
        debugPrint('saveGrade error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Error saving grade: $e');
    }
  }

  Future<void> addJurnal(Map<String, dynamic> jurnal) async {
    final newJurnal = {
      'id': 'jn_${DateTime.now().millisecondsSinceEpoch}',
      ...jurnal,
    };
    _jurnals.insert(0, newJurnal);
    notifyListeners();

    try {
      final user = _currentUser;
      final guruId = user?['id'];
      
      final response = await http.post(
        Uri.parse('$baseUrl/rest/v1/laporan_gurus'),
        headers: {
          ..._sbHeaders,
          'Prefer': 'return=minimal'
        },
        body: jsonEncode({
          'guru_id': guruId,
          'tanggal': jurnal['date'],
          'kelas': jurnal['class'],
          'mata_pelajaran': jurnal['subject'],
          'materi': jurnal['topic'],
          'isi_laporan': jurnal['notes'],
        }),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await syncFromDatabase();
      } else {
        debugPrint('Error adding jurnal to DB: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error adding jurnal: $e');
    }
  }

  // 10. Authenticate via Supabase
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    final result = await SupabaseService.login(identifier, password);
    if (result['status'] == 'success') {
      _activeRole = result['user']['role'];
      _currentUser = Map<String, dynamic>.from(result['user']);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUser', jsonEncode(_currentUser));
      await prefs.setString('activeRole', _activeRole);

      notifyListeners();
      await syncFromDatabase();
    }
    return result;
  }

  Future<bool> checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('currentUser');
      final role = prefs.getString('activeRole');
      
      if (userStr != null && role != null) {
        _currentUser = Map<String, dynamic>.from(jsonDecode(userStr));
        _activeRole = role;
        notifyListeners();
        // Fire and forget sync, no need to block splash screen completely
        syncFromDatabase();
        return true;
      }
    } catch (e) {
      debugPrint('Error checking login status: $e');
    }
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    _activeRole = 'Admin';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUser');
    await prefs.remove('activeRole');
    
    // Batalkan semua jadwal notifikasi agar tidak nyasar ke akun/role lain
    await NotificationService.cancelAllGuruReminders();
    await NotificationService.cancelAllMusyrifReminders();
    
    notifyListeners();
  }

  // Update Profile
  Future<bool> updateProfile(String id, String email, String phone, {String? newPassword}) async {
    final result = await SupabaseService.updateProfile(id: id, email: email, phone: phone, newPassword: newPassword);
    if (result['status'] == 'success') {
      if (_currentUser != null) {
        _currentUser!['email'] = email;
        _currentUser!['phone'] = phone;
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  // 11. Sync Data from Supabase
  Map<String, dynamic> _attendance7Days = {'labels': [], 'values': []};
  Map<String, dynamic> get attendance7Days => _attendance7Days;

  Future<bool> syncFromDatabase() async {
    final data = await SupabaseService.syncAll();
    if (data.isEmpty) return false;

    _students.clear();
    _halaqohs.clear();
    _setorans.clear();
    _permissions.clear();
    _medicalRecords.clear();
    _rooms.clear();
    _bills.clear();
    _grades.clear();
    _schedules.clear();
    _announcements.clear();
    _jurnals.clear();
    _chats.clear();
    _waliSantri.clear();
    _appUsers.clear();

    if (data['appUsers'] != null) {
      for (var u in data['appUsers']) {
        _appUsers.add(Map<String, dynamic>.from(u));
      }
    }

    if (data['students'] != null) {
      for (var s in data['students']) {
        _students.add(Map<String, dynamic>.from(s));
      }
    }
    if (data['halaqohs'] != null) {
      for (var h in data['halaqohs']) {
        _halaqohs.add(Map<String, dynamic>.from(h));
      }
    }
    if (data['setorans'] != null) {
      for (var s in data['setorans']) {
        _setorans.add(Map<String, dynamic>.from(s));
      }
    }
    if (data['permissions'] != null) {
      for (var p in data['permissions']) {
        _permissions.add(Map<String, dynamic>.from(p));
      }
    }
    if (data['medicalRecords'] != null) {
      for (var m in data['medicalRecords']) {
        _medicalRecords.add(Map<String, dynamic>.from(m));
      }
    }
    if (data['rooms'] != null) {
      for (var r in data['rooms']) {
        _rooms.add(Map<String, dynamic>.from(r));
      }
    }
    if (data['bills'] != null) {
      for (var b in data['bills']) {
        _bills.add(Map<String, dynamic>.from(b));
      }
    }
    if (data['grades'] != null) {
      for (var g in data['grades']) {
        _grades.add(Map<String, dynamic>.from(g));
      }
    }
    if (data['schedules'] != null) {
      for (var s in data['schedules']) {
        _schedules.add(Map<String, dynamic>.from(s));
      }
    }
    if (data['announcements'] != null) {
      for (var a in data['announcements']) {
        _announcements.add(Map<String, dynamic>.from(a));
      }
    }
    if (data['jurnals'] != null) {
      for (var j in data['jurnals']) {
        _jurnals.add(Map<String, dynamic>.from(j));
      }
    }
    if (data['messages'] != null) {
      final myId = _currentUser?['id']?.toString() ?? '';
      final rawMessages = data['messages'] as List;
      
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (var msg in rawMessages) {
        final senderId = msg['senderId'];
        final receiverId = msg['receiverId'];
        if (senderId == myId) {
          grouped.putIfAbsent(receiverId, () => []).add(Map<String, dynamic>.from(msg));
        } else if (receiverId == myId) {
          grouped.putIfAbsent(senderId, () => []).add(Map<String, dynamic>.from(msg));
        }
      }

      for (var targetId in grouped.keys) {
        _chats.add({
          'id': targetId,
          'targetId': targetId,
          'messages': grouped[targetId],
        });
      }
    }
    if (data['waliSantri'] != null) {
      for (var w in data['waliSantri']) {
        _waliSantri.add(Map<String, dynamic>.from(w));
      }
    }
    if (data['attendance7Days'] != null) {
      _attendance7Days = Map<String, dynamic>.from(data['attendance7Days']);
    }

    notifyListeners();
    return true;
  }

  // ── Chat (Konsultasi) Actions ──────────────────────────────────────────

  Future<Map<String, dynamic>> getOrCreateChatRoom(String santriId, String targetId) async {
    final existing = _chats.firstWhere(
      (c) => c['targetId'] == targetId,
      orElse: () => {},
    );
    if (existing.isNotEmpty) return existing;

    final newRoom = {
      'id': targetId,
      'targetId': targetId,
      'santriId': santriId,
      'messages': [],
    };
    _chats.insert(0, newRoom);
    notifyListeners();
    return newRoom;
  }

  Future<void> sendChatMessage(String targetId, String text) async {
    final senderId = _currentUser?['id']?.toString() ?? '';
    if (senderId.isEmpty) return;

    final newMessage = {
      'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'senderId': senderId,
      'text': text,
      'isRead': false,
      'time': '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      'timestamp': DateTime.now().toIso8601String(),
    };

    final chatIndex = _chats.indexWhere((c) => c['targetId'] == targetId);
    if (chatIndex != -1) {
      (_chats[chatIndex]['messages'] as List).add(newMessage);
      notifyListeners();
    }

    try {
      await SupabaseService.postTable('messages', {
        'sender_id': int.parse(senderId),
        'receiver_id': int.parse(targetId),
        'content': text,
        'is_read': false,
      });
    } catch (e) {
      debugPrint('Error sending chat message: $e');
    }
  }
}
