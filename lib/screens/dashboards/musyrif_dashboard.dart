import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../constants/colors.dart';
import '../login_screen.dart';
import 'admin_dashboard.dart'; // To access globalStateInstance
import '../../widgets/suntri_header.dart';
import '../../widgets/expandable_text.dart';
import '../../services/notification_service.dart';
import '../../services/supabase_service.dart';

class MusyrifDashboard extends StatefulWidget {
  const MusyrifDashboard({super.key});

  @override
  State<MusyrifDashboard> createState() => _MusyrifDashboardState();
}

class _MusyrifDashboardState extends State<MusyrifDashboard> {
  int _currentTabIndex = 0;
  final String _halaqohId = 'hq_1';
  final Map<String, String> _tempAttendance = {};
  String? _lastAbsensiTime;

  Map<String, dynamic> _getHalaqoh() {
    if (globalStateInstance.halaqohs.isEmpty) {
      return {
        'id': 'empty',
        'name': 'Belum Ada Halaqoh',
        'teacher': '-',
        'studentIds': <String>[],
      };
    }
    final currentUser = globalStateInstance.currentUser;
    if (currentUser != null) {
      final String currentUserName = currentUser['name'] ?? '';
      final h = globalStateInstance.halaqohs.firstWhere(
        (h) => (h['teacher'] ?? '').toString().toLowerCase().contains(currentUserName.toLowerCase()) ||
               currentUserName.toLowerCase().contains((h['teacher'] ?? '').toString().toLowerCase()),
        orElse: () => {},
      );
      if (h.isNotEmpty) return h;
    }
    return globalStateInstance.halaqohs.firstWhere(
      (h) => h['id'] == _halaqohId,
      orElse: () => globalStateInstance.halaqohs.first,
    );
  }

  Map<String, dynamic> _getStudent(String id) {
    return globalStateInstance.students.firstWhere(
      (s) => s['id'] == id,
      orElse: () => {
        'id': id,
        'name': 'Santri Tidak Ditemukan',
        'nis': '-',
        'class': '-',
        'parent': '-',
        'juz': 0,
        'avatar': null,
        'initials': '?',
        'attendance': {'hadir': 0, 'sakit': 0, 'izin': 0, 'alpha': 0},
      },
    );
  }

  // Chat Contacts — generated from real santri in this musyrif's halaqoh and mapped to DB konsultasi
  List<Map<String, dynamic>> get _chatContacts {
    final hq = _getHalaqoh();
    final List<String> studentIds = List<String>.from(hq['studentIds'] ?? []);
    final musyrifId = globalStateInstance.currentUser?['id']?.toString() ?? '';

    return studentIds.map((id) {
      final s = _getStudent(id);
      final santriNama = s['name'] ?? 'Santri';
      
      // Look up wali for this student
      final wali = globalStateInstance.waliSantri.firstWhere(
        (w) => w['santriId'] == id,
        orElse: () => {},
      );
      final waliId = wali.isNotEmpty ? wali['userId']?.toString() ?? '1' : '1';
      final waliNama = wali.isNotEmpty ? wali['nama'] : 'Wali $santriNama';

      // Check if chat exists
      final chat = globalStateInstance.chats.firstWhere(
        (c) => c['targetId'] == waliId,
        orElse: () => {},
      );

      String lastMsg = 'Tap untuk mengirim pesan';
      int unread = 0;
      if (chat.isNotEmpty) {
        final messages = chat['messages'] as List;
        if (messages.isNotEmpty) {
          lastMsg = messages.last['text'];
          unread = messages.where((m) => m['senderId'] != musyrifId && m['isRead'] == false).length;
        }
      }

      return {
        'id': chat.isNotEmpty ? chat['id'] : 'new_$id', // fallback ID for new chats
        'roomId': chat.isNotEmpty ? chat['id'] : null,
        'waliId': waliId,
        'santriId': id,
        'name': waliNama,
        'child': santriNama,
        'unread': unread,
        'lastMsg': lastMsg,
        'messages': chat.isNotEmpty ? chat['messages'] : [],
      };
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    // Initialize mass attendance cache
    final hq = _getHalaqoh();
    final List<String> studentIds = List<String>.from(hq['studentIds']);
    for (var id in studentIds) {
      _tempAttendance[id] = 'Hadir';
    }
    
    // Schedule Musyrif specific notifications
    NotificationService.scheduleMusyrifReminders();
  }

  // Modals Triggers
  void _openSetoranModal(String? studentId) {
    String? selectedId = studentId;
    final TextEditingController surahCtrl = TextEditingController();
    final TextEditingController ayatDariCtrl = TextEditingController();
    final TextEditingController ayatSampaiCtrl = TextEditingController();
    final TextEditingController juzCtrl = TextEditingController();
    String type = 'Ziyadah';
    String kelancaran = 'Sangat Baik';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final hq = _getHalaqoh();
            final studentIds = List<String>.from(hq['studentIds']);

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(width: 48, height: 6, decoration: BoxDecoration(color: AppColors.outlineVariant, borderRadius: BorderRadius.circular(3))),
                      ),
                      const SizedBox(height: 16),
                      const Text('Input Setoran Hafalan Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      // Student dropdown
                      const Text('Pilih Santri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedId,
                        hint: const Text('Pilih nama santri...'),
                        items: studentIds.map((id) {
                          final std = _getStudent(id);
                          return DropdownMenuItem(value: id, child: Text(std['name']));
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            selectedId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // Setoran Type
                      Row(
                        children: ['Ziyadah', 'Murajaah'].map((t) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(t),
                              selected: type == t,
                              onSelected: (val) {
                                if (val) setModalState(() => type = t);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      // Surah & Juz
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Surah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                const SizedBox(height: 6),
                                TextField(controller: surahCtrl, decoration: const InputDecoration(hintText: 'Al-Baqarah')),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Juz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                const SizedBox(height: 6),
                                TextField(controller: juzCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '30')),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Verses range
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Dari Ayat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                const SizedBox(height: 6),
                                TextField(controller: ayatDariCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '1')),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Sampai Ayat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                const SizedBox(height: 6),
                                TextField(controller: ayatSampaiCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '10')),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Kelancaran
                      const Text('Evaluasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: kelancaran,
                        items: ['Sangat Baik', 'Baik', 'Cukup', 'Kurang'].map((k) {
                          return DropdownMenuItem(value: k, child: Text(k));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => kelancaran = val);
                        },
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (selectedId == null || surahCtrl.text.isEmpty || juzCtrl.text.isEmpty) return;
                            final std = _getStudent(selectedId!);
                            
                            // Auto Juz increment calculation
                            final int newJuz = int.tryParse(juzCtrl.text) ?? std['juz'];
                            if (newJuz > std['juz']) {
                              globalStateInstance.updateStudentJuz(std['id'], newJuz);
                            }

                            globalStateInstance.addSetoran({
                              'id': 'set_${DateTime.now().millisecondsSinceEpoch}',
                              'studentName': std['name'],
                              'type': type,
                              'surah': surahCtrl.text,
                              'ayatDari': ayatDariCtrl.text,
                              'ayatSampai': ayatSampaiCtrl.text,
                              'juz': juzCtrl.text,
                              'kelancaran': kelancaran,
                              'date': DateTime.now().toString().split(' ')[0],
                            });

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Setoran baru berhasil disimpan!'), backgroundColor: AppColors.primary),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Simpan Setoran', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openLaporSakitModal() {
    String? selectedId;
    final TextEditingController symptomCtrl = TextEditingController();
    final TextEditingController diagnosisCtrl = TextEditingController();
    final TextEditingController medicineCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final hq = _getHalaqoh();
            final studentIds = List<String>.from(hq['studentIds']);

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(width: 48, height: 6, decoration: BoxDecoration(color: AppColors.outlineVariant, borderRadius: BorderRadius.circular(3))),
                      ),
                      const SizedBox(height: 16),
                      const Text('Laporkan Santri Sakit (UKS)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      const Text('Nama Santri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedId,
                        hint: const Text('Pilih santri sakit...'),
                        items: studentIds.map((id) {
                          final std = _getStudent(id);
                          return DropdownMenuItem(value: id, child: Text(std['name']));
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            selectedId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      const Text('Gejala', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      const SizedBox(height: 6),
                      TextField(controller: symptomCtrl, decoration: const InputDecoration(hintText: 'Demam, pusing, batuk...')),
                      const SizedBox(height: 12),

                      const Text('Diagnosis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      const SizedBox(height: 6),
                      TextField(controller: diagnosisCtrl, decoration: const InputDecoration(hintText: 'Flu ringan / Masuk angin')),
                      const SizedBox(height: 12),

                      const Text('Obat / Tindakan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      const SizedBox(height: 6),
                      TextField(controller: medicineCtrl, decoration: const InputDecoration(hintText: 'Istirahat di UKS & Paracetamol 500mg')),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (selectedId == null || symptomCtrl.text.isEmpty) return;
                            final std = _getStudent(selectedId!);

                            // Add UKS medical record
                            globalStateInstance.addMedicalRecord({
                              'id': 'med_${DateTime.now().millisecondsSinceEpoch}',
                              'studentName': std['name'],
                              'date': DateTime.now().toString().split(' ')[0],
                              'symptom': symptomCtrl.text,
                              'diagnosis': diagnosisCtrl.text,
                              'medicine': medicineCtrl.text,
                              'isReferredToLeave': true,
                            });

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Laporan sakit terkirim & Izin sakit terbuat otomatis!'), backgroundColor: AppColors.primary),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Kirim Laporan Sakit', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openAbsensiMassalModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final hq = _getHalaqoh();
            final studentIds = List<String>.from(hq['studentIds']);

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Center(
                    child: Container(width: 48, height: 6, decoration: BoxDecoration(color: AppColors.outlineVariant, borderRadius: BorderRadius.circular(3))),
                  ),
                  const SizedBox(height: 16),
                  const Text('Absensi Massal Halaqoh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (_lastAbsensiTime != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Absensi hari ini sudah diisi pada $_lastAbsensiTime',
                              style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: studentIds.length,
                      itemBuilder: (context, idx) {
                        final id = studentIds[idx];
                        final std = _getStudent(id);
                        final cur = _tempAttendance[id] ?? 'Hadir';

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(std['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text('NIS: ${std['nis']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: ['H', 'S', 'I', 'A'].map((k) {
                              String full = 'Hadir';
                              Color c = Colors.green;
                              if (k == 'S') { full = 'Sakit'; c = Colors.orange; }
                              if (k == 'I') { full = 'Izin'; c = Colors.purple; }
                              if (k == 'A') { full = 'Alpha'; c = Colors.red; }

                              final sel = cur == full;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                child: ChoiceChip(
                                  label: Text(k, style: TextStyle(color: sel ? Colors.white : AppColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold)),
                                  selected: sel,
                                  selectedColor: c,
                                  onSelected: (val) {
                                    if (val) {
                                      setModalState(() {
                                        _tempAttendance[id] = full;
                                      });
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        showDialog(
                          context: context, 
                          barrierDismissible: false,
                          builder: (_) => const Center(child: CircularProgressIndicator()),
                        );
                        
                        final now = DateTime.now();
                        final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                        
                        final List<Future> tasks = [];

                        // Prepare Supabase insertion tasks
                        _tempAttendance.forEach((id, status) {
                          // Push to database
                          final santriId = int.tryParse(id.toString());
                          if (santriId != null) {
                            tasks.add(SupabaseService.postTable('kehadiran', {
                              'santri_id': santriId,
                              'status': status.toString().toLowerCase(),
                              'tanggal': dateStr,
                            }, upsert: true));
                          }
                        });
                        
                        await Future.wait(tasks);

                        // Ambil data terbaru langsung dari database (jangan arahin ke lokal)
                        await globalStateInstance.syncFromDatabase();

                        if (mounted) {
                          setState(() {
                            _lastAbsensiTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB';
                          });
                          Navigator.pop(context); // close loading
                          Navigator.pop(context); // close modal
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Absensi massal berhasil disimpan!'), backgroundColor: AppColors.primary),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Simpan Kehadiran', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = globalStateInstance.currentUser;
    final String teacherName = user != null ? user['name'] ?? 'Musyrif' : 'Musyrif';
    final String initials = teacherName.isNotEmpty
        ? teacherName.split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join().toUpperCase()
        : 'M';

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      appBar: SUNTRIHeader(
        title: "Ma'had Tahfidz Rijaalul Quran",
        subtitle: '$teacherName • Musyrif',
        initials: initials,
        onLogout: () async {
          await globalStateInstance.logout();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        },
      ),
      body: ListenableBuilder(
        listenable: globalStateInstance,
        builder: (context, child) {
          return IndexedStack(
            index: _currentTabIndex,
            children: [
              _buildDashboardTab(),
              _buildTahfizhTab(),
              _buildRekapTab(),
              _buildChatTab(),
              _buildPengumumanTab(),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: Colors.white.withOpacity(0.4),
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: true,
                child: BottomNavigationBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedFontSize: 11,
                  unselectedFontSize: 11,
                  iconSize: 22,
                  currentIndex: _currentTabIndex,
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: AppColors.primary,
                  unselectedItemColor: AppColors.outline,
                  onTap: (index) {
                    setState(() {
                      _currentTabIndex = index;
                    });
                  },
                  items: const [
                    BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
                    BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Tahfizh'),
                    BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Rekap'),
                    BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
                    BottomNavigationBarItem(icon: Icon(Icons.campaign_outlined), label: 'Pengumuman'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // TAB 1: DASHBOARD
  Widget _buildDashboardTab() {
    final hq = _getHalaqoh();
    final studentIds = List<String>.from(hq['studentIds'] ?? []);
    final totalSantri = studentIds.length;
    
    // Get formatted date in Indonesian (e.g. "Senin, 24 Agustus 2026")
    final now = DateTime.now();
    final days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final String formattedDate = '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]} ${now.year}';
    final String todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    // Auto query sick alerts (filtered by today)
    final sickStudents = globalStateInstance.medicalRecords
        .where((med) => med['date'] == todayStr && studentIds.any((id) {
          final std = _getStudent(id);
          return std['name'] == med['studentName'];
        }))
        .toList();

    // Get dynamic current user name
    final user = globalStateInstance.currentUser;
    final String teacherName = user != null ? user['name'] ?? 'Musyrif' : 'Musyrif';

    // Calculate today's setorans count for this halaqoh
    final todayHalaqohSetorans = globalStateInstance.setorans.where((s) {
      final student = globalStateInstance.students.firstWhere(
        (std) => std['name'] == s['studentName'],
        orElse: () => {},
      );
      return student.isNotEmpty && studentIds.contains(student['id']) && s['date'] == todayStr;
    }).toList();

    // Calculate average Juz of this halaqoh
    double avgJuzVal = 0;
    int countWithJuz = 0;
    for (var id in studentIds) {
      final std = _getStudent(id);
      if (std.isNotEmpty && std['juz'] != null) {
        avgJuzVal += (std['juz'] as num).toDouble();
        countWithJuz++;
      }
    }
    final String avgJuz = countWithJuz > 0
        ? 'Juz ${(avgJuzVal / countWithJuz).toStringAsFixed(0)}'
        : 'Juz 0';

    // Calculate 7-day setoran trend (Ziyadah vs Murajaah)
    final List<int> trendZiyadah = List.filled(7, 0);
    final List<int> trendMurajaah = List.filled(7, 0);
    final List<String> trendLabels = List.filled(7, '');
    int maxSetoran = 1;

    for (int i = 0; i < 7; i++) {
      final d = now.subtract(Duration(days: 6 - i));
      trendLabels[i] = days[d.weekday % 7].substring(0, 3);
      final dateStr = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      
      int ziyadahCount = 0;
      int murajaahCount = 0;
      
      for (var s in globalStateInstance.setorans) {
        if (s['date'] == dateStr) {
          final setoranMusyrif = (s['musyrif'] ?? '').toString().toLowerCase();
          final isMySetoran = teacherName.isNotEmpty && setoranMusyrif.contains(teacherName.toLowerCase());

          // Alternatif fallback: cek apakah santri id ada di studentIds halaqoh ini, jika musyrif kosong
          bool fallbackHalaqoh = false;
          if (!isMySetoran) {
            final student = globalStateInstance.students.firstWhere(
              (std) => std['name'] == s['studentName'],
              orElse: () => {},
            );
            fallbackHalaqoh = student.isNotEmpty && studentIds.contains(student['id']);
          }

          if (isMySetoran || fallbackHalaqoh) {
            final jenis = (s['jenis'] ?? s['type'] ?? '').toString();
            
            final dari = int.tryParse(s['ayatDari']?.toString() ?? s['ayatFrom']?.toString() ?? '1') ?? 1;
            final sampai = int.tryParse(s['ayatSampai']?.toString() ?? s['ayatTo']?.toString() ?? '15') ?? 15;
            
            int pages = 1;
            if (sampai >= dari) {
              pages = ((sampai - dari + 1) / 15).ceil();
              if (pages < 1) pages = 1;
            }

            if (jenis == 'hafalan_baru') {
              ziyadahCount += pages;
            } else if (jenis == 'murajaah' || jenis.contains('muraja')) {
              murajaahCount += pages;
            }
          }
        }
      }
      trendZiyadah[i] = ziyadahCount;
      trendMurajaah[i] = murajaahCount;
      if (ziyadahCount + murajaahCount > maxSetoran) {
        maxSetoran = ziyadahCount + murajaahCount;
      }
    }
    
    // Calculate filtered setorans for feed (last 7 days only)
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final feedSetorans = globalStateInstance.setorans.where((s) {
      final dateStr = s['date']?.toString() ?? '';
      bool isRecent = false;
      if (dateStr.isNotEmpty) {
        try {
          final dt = DateTime.parse(dateStr);
          if (dt.isAfter(sevenDaysAgo) || (dt.year == sevenDaysAgo.year && dt.month == sevenDaysAgo.month && dt.day == sevenDaysAgo.day)) {
            isRecent = true;
          }
        } catch (_) {}
      }
      if (!isRecent) return false;

      final student = globalStateInstance.students.firstWhere(
        (std) => std['name'] == s['studentName'],
        orElse: () => {},
      );
      return student.isNotEmpty && studentIds.contains(student['id']);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Green Card (Greetings Banner with bubble effects)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF005C43), Color(0xFF003D2E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF003D2E).withOpacity(0.25),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  top: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04),
                    ),
                  ),
                ),
                Positioned(
                  right: 40,
                  bottom: -35,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.03),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Assalamu'alaikum,",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          teacherName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          '👋',
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, color: Colors.white60, size: 12),
                        const SizedBox(width: 6),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // 3 indicator chips inside card
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: const Column(
                              children: [
                                Text(
                                  '1',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'HALAQOH',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${todayHalaqohSetorans.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'SETORAN',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$totalSantri',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'SANTRI',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Sick alert banner (if exists)
          if (sickStudents.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pemberitahuan UKS: ${sickStudents.length} santri sedang sakit/dirujuk.',
                      style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 4 Grid Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildKpiCard(
                label: 'HALAQOH TAHFIZH',
                value: hq['name'] ?? 'Halaqoh',
                icon: Icons.menu_book,
                iconColor: const Color(0xFF2E7D32),
                iconBgColor: const Color(0xFFE8F5E9),
              ),
              _buildKpiCard(
                label: 'SETORAN HARI INI',
                value: '${todayHalaqohSetorans.length}',
                icon: Icons.fact_check_outlined,
                iconColor: const Color(0xFF512DA8),
                iconBgColor: const Color(0xFFEDE7F6),
              ),
              _buildKpiCard(
                label: 'TOTAL SANTRI',
                value: '$totalSantri',
                icon: Icons.group_rounded,
                iconColor: const Color(0xFFE65100),
                iconBgColor: const Color(0xFFFFF3E0),
              ),
              _buildKpiCard(
                label: 'RATA-RATA JUZ',
                value: avgJuz,
                icon: Icons.star_rounded,
                iconColor: const Color(0xFFC2185B),
                iconBgColor: const Color(0xFFFCE4EC),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Custom Stacked Bar Chart
          const Text('Tren Kemajuan Hafalan (Halaman)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildLegendItem('Ziyadah', AppColors.primary),
                    const SizedBox(width: 12),
                    _buildLegendItem('Muraja\'ah', Colors.orange),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (i) {
                      final z = trendZiyadah[i];
                      final m = trendMurajaah[i];
                      final total = z + m;
                      double zPct = total == 0 ? 0 : (z / maxSetoran);
                      double mPct = total == 0 ? 0 : (m / maxSetoran);

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (total > 0)
                            Text('$total', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black54)),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                Container(
                                  width: 16,
                                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                                ),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final maxHeight = constraints.maxHeight;
                                    final zHeight = zPct * maxHeight;
                                    final mHeight = mPct * maxHeight;
                                    return Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (mHeight > 0)
                                          Container(
                                            height: mHeight,
                                            width: 16,
                                            decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.vertical(top: Radius.circular(zHeight == 0 ? 4 : 0))),
                                          ),
                                        if (zHeight > 0)
                                          Container(
                                            height: zHeight,
                                            width: 16,
                                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.vertical(bottom: const Radius.circular(4), top: Radius.circular(mHeight == 0 ? 4 : 0))),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(trendLabels[i], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45)),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick Action Modal Buttons
          const Text('Tindakan Cepat', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildActionBtn('Setoran', Icons.add_chart, Colors.orange, () => _openSetoranModal(null))),
              const SizedBox(width: 8),
              Expanded(child: _buildActionBtn('Lapor Sakit', Icons.local_hospital, Colors.red, _openLaporSakitModal)),
              const SizedBox(width: 8),
              Expanded(child: _buildActionBtn('Absen Massal', Icons.rule, AppColors.primary, _openAbsensiMassalModal)),
            ],
          ),
          const SizedBox(height: 20),

          // Feed setoran terbaru grouped by Date
          const Text('Riwayat Setoran (Per Hari)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (feedSetorans.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('Belum ada setoran terbaru', style: TextStyle(color: Colors.grey))),
            )
          else
            Builder(
              builder: (context) {
                // Group by date
                Map<String, List<Map<String, dynamic>>> groupedFeed = {};
                for (var s in feedSetorans) {
                  final dateStr = s['date']?.toString() ?? 'Tidak Diketahui';
                  if (!groupedFeed.containsKey(dateStr)) {
                    groupedFeed[dateStr] = [];
                  }
                  groupedFeed[dateStr]!.add(s);
                }
                
                final sortedDates = groupedFeed.keys.toList()..sort((a, b) => b.compareTo(a));
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sortedDates.map((date) { // Show all dates in the past 7 days
                    String displayDate = date;
                    if (date != 'Tidak Diketahui') {
                      try {
                        final dt = DateTime.parse(date);
                        final diff = DateTime.now().difference(dt).inDays;
                        if (diff == 0 && DateTime.now().day == dt.day) {
                          displayDate = 'Hari Ini';
                        } else if (diff == 1 || (diff == 0 && DateTime.now().day != dt.day)) {
                          displayDate = 'Kemarin';
                        } else {
                          displayDate = '${dt.day} ${_getMonthName(dt.month)} ${dt.year}';
                        }
                      } catch (_) {}
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 8, left: 4),
                          child: Text(
                            displayDate,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                          ),
                        ),
                        ...groupedFeed[date]!.map((s) {
                          final jenisRaw = (s['jenis'] ?? s['type'] ?? '').toString();
                          String jenisLabel;
                          if (jenisRaw == 'hafalan_baru') jenisLabel = 'Ziyadah';
                          else if (jenisRaw == 'murajaah' || jenisRaw.contains('muraja')) jenisLabel = "Muraja'ah";
                          else if (jenisRaw == 'tasmi') jenisLabel = "Tasmi'";
                          else jenisLabel = jenisRaw;
                          
                          final gradeRaw = (s['grade'] ?? s['kelancaran'] ?? '').toString();

                          return Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              dense: true,
                              title: Text(s['studentName'] ?? 'Santri', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('$jenisLabel • Surah ${s['surah'] ?? '-'} • $gradeRaw'),
                              trailing: Text('Juz ${s['juz'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.04), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black38,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EAF6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3F51B5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black54)),
      ],
    );
  }

  Widget _buildActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 2: TAHFIZH
  Widget _buildTahfizhTab() {
    final hq = _getHalaqoh();
    final studentIds = List<String>.from(hq['studentIds']);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Daftar Anggota Halaqoh', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
        ),
        
        // Student List + Juz Badge
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 160),
            itemCount: studentIds.length,
            itemBuilder: (context, idx) {
              final std = _getStudent(studentIds[idx]);
              final String studentName = std['name'] ?? 'Santri';
              final String initials = studentName.isNotEmpty
                  ? studentName.split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join().toUpperCase()
                  : 'S';

              return Card(
                color: Colors.white,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200, width: 1.5),
                ),
                child: ListTile(
                  title: Text(studentName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans')),
                  subtitle: Text('NIS: ${std['nis']}', style: const TextStyle(fontSize: 12, color: AppColors.outline, fontFamily: 'Plus Jakarta Sans')),
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(initials, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.secondaryFixedDim, borderRadius: BorderRadius.circular(12)),
                        child: Text('Juz ${std['juz']}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: AppColors.primary),
                        onPressed: () => _openSetoranModal(std['id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),


      ],
    );
  }

  // TAB 3: REKAP
  String _rekapFilter = 'Minggu Ini';
  Widget _buildRekapTab() {
    final hq = _getHalaqoh();
    final studentIds = List<String>.from(hq['studentIds']);

    // Helper to calculate total hal for a student
    int getHal(String studentName, String filter, String jenisType) {
      int totalAyat = 0;
      final now = DateTime.now();
      for (var s in globalStateInstance.setorans) {
        if (s['studentName'] == studentName) {
          final j = (s['jenis'] ?? s['type'] ?? '').toString().toLowerCase();
          final bool isMatch = (jenisType == 'ziyadah' && (j == 'hafalan_baru' || j == 'ziyadah')) ||
                               (jenisType == 'murajaah' && (j == 'murajaah' || j.contains('muraja')));
          if (isMatch) {
            final dateStr = s['date']?.toString() ?? '';
            if (dateStr.isNotEmpty) {
              try {
                final d = DateTime.parse(dateStr);
                bool include = false;
                if (filter == 'Minggu Ini') {
                  final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
                  if (d.isAfter(startOfWeek.subtract(const Duration(days: 1)))) {
                    include = true;
                  }
                } else if (filter == 'Bulan Ini') {
                  if (d.month == now.month && d.year == now.year) include = true;
                }
                
                if (include) {
                  final dari = int.tryParse(s['ayatDari']?.toString() ?? s['ayatFrom']?.toString() ?? '1') ?? 1;
                  final sampai = int.tryParse(s['ayatSampai']?.toString() ?? s['ayatTo']?.toString() ?? '15') ?? 15;
                  if (sampai >= dari) {
                    totalAyat += (sampai - dari + 1);
                  }
                }
              } catch (_) {}
            }
          }
        }
      }
      return (totalAyat / 15).ceil();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Rekapitulasi Ziyadah & Murajaah', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () async {
                  showDialog(
                    context: context, 
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );
                  
                  try {
                    final pdf = pw.Document();
                    
                    // Load Logo
                    final ByteData logoBytes = await rootBundle.load('assets/images/logo.jpg');
                    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

                    // Create table data
                    final List<List<String>> tableData = [
                      ['Santri', 'Ziyadah (Hal)', 'Murajaah (Hal)'],
                    ];
                    for (var id in studentIds) {
                      final std = _getStudent(id);
                      final name = std['name'];
                      final ziyadah = getHal(name, _rekapFilter, 'ziyadah');
                      final murajaah = getHal(name, _rekapFilter, 'murajaah');
                      tableData.add([name, '$ziyadah', '$murajaah']);
                    }

                    pdf.addPage(
                      pw.Page(
                        pageFormat: PdfPageFormat.a4,
                        build: (pw.Context context) {
                          return pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.center,
                                children: [
                                  pw.Image(logoImage, width: 60, height: 60),
                                  pw.SizedBox(width: 16),
                                  pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text("Ma'had Tahfidz Rijaalul Quran", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                                      pw.Text('Rekapitulasi Setoran Halaqoh', style: const pw.TextStyle(fontSize: 14)),
                                      pw.Text('Periode: $_rekapFilter', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                                    ],
                                  ),
                                ],
                              ),
                              pw.SizedBox(height: 24),
                              pw.TableHelper.fromTextArray(
                                context: context,
                                data: tableData,
                                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
                                cellAlignment: pw.Alignment.centerLeft,
                                cellAlignments: {
                                  1: pw.Alignment.center,
                                  2: pw.Alignment.center,
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    );

                    final bytes = await pdf.save();
                    if (mounted) Navigator.pop(context); // close dialog

                    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
                      final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
                      final file = File('${dir.path}/rekap_halaqoh_${DateTime.now().millisecondsSinceEpoch}.pdf');
                      await file.writeAsBytes(bytes);
                      if (mounted) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Export PDF Sukses'),
                            content: Text('File berhasil disimpan di:\n${file.path}'),
                            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                          ),
                        );
                      }
                    } else {
                      final dir = await getTemporaryDirectory();
                      final file = File('${dir.path}/rekap_halaqoh.pdf');
                      await file.writeAsBytes(bytes);
                      
                      if (mounted) {
                        await Share.shareXFiles(
                          [XFile(file.path)],
                          text: 'Rekapitulasi Setoran Halaqoh ($_rekapFilter)',
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) Navigator.pop(context); // close dialog
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Error'),
                          content: Text('Gagal membuat atau membagikan PDF:\n$e'),
                          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.picture_as_pdf, size: 14),
                label: const Text('PDF', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              )
            ],
          ),
          const SizedBox(height: 12),

          // Filters
          Row(
            children: ['Minggu Ini', 'Bulan Ini'].map((filter) {
              final sel = _rekapFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: sel,
                  onSelected: (val) {
                    if (val) setState(() => _rekapFilter = filter);
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Rekap Table
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 160),
              scrollDirection: Axis.vertical,
              child: Table(
                border: TableBorder.all(color: AppColors.outlineVariant.withOpacity(0.5)),
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                },
                children: [
                  const TableRow(
                    decoration: BoxDecoration(color: AppColors.surfaceContainer),
                    children: [
                      Padding(padding: EdgeInsets.all(8), child: Text('Santri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Padding(padding: EdgeInsets.all(8), child: Text('Ziyadah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
                      Padding(padding: EdgeInsets.all(8), child: Text('Murajaah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
                    ],
                  ),
                  ...studentIds.map((id) {
                    final std = _getStudent(id);
                    final name = std['name'];
                    final ziyadah = getHal(name, _rekapFilter, 'ziyadah');
                    final murajaah = getHal(name, _rekapFilter, 'murajaah');
                    
                    return TableRow(
                      children: [
                        Padding(padding: const EdgeInsets.all(8), child: Text(name, style: const TextStyle(fontSize: 11))),
                        Padding(padding: const EdgeInsets.all(8), child: Text('$ziyadah hal', style: const TextStyle(fontSize: 11), textAlign: TextAlign.center)),
                        Padding(padding: const EdgeInsets.all(8), child: Text('$murajaah hal', style: const TextStyle(fontSize: 11), textAlign: TextAlign.center)),
                      ],
                    );
                  }),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // TAB 4: CHAT
  Widget _buildChatTab() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 160),
      itemCount: _chatContacts.length,
      itemBuilder: (context, idx) {
        final c = _chatContacts[idx];
        return Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.08),
              child: const Icon(Icons.person, color: AppColors.primary),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    c['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (c['unread'] > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                    child: Text('${c['unread']}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            subtitle: Text(
              '${c['child']} • ${c['lastMsg']}',
              style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () async {
              setState(() {
                c['unread'] = 0; // Clear unread on tap locally
              });
              
              Map<String, dynamic> chatData = Map.from(c);
              
              // Ensure chat room exists
              if (c['roomId'] == null) {
                showDialog(
                  context: context, 
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );
                
                final newRoom = await globalStateInstance.getOrCreateChatRoom(c['santriId'], c['waliId']);
                
                if (mounted) Navigator.pop(context); // close dialog
                
                if (newRoom.isNotEmpty) {
                  chatData['roomId'] = newRoom['id'];
                  chatData['messages'] = newRoom['messages'];
                }
              }

              if (mounted && chatData['roomId'] != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MusyrifChatRoomScreen(contact: chatData)),
                );
              }
            },
          ),
        );
      },
    );
  }

  // TAB 5: PENGUMUMAN
  Widget _buildPengumumanTab() {
    final now = DateTime.now();
    final listAnn = globalStateInstance.announcements.where((a) {
      // 1. Target Filter (semua or musyrif)
      final target = a['target']?.toString().toLowerCase() ?? '';
      bool isTargeted = target == 'semua' || target == 'musyrif';
      
      // 2. Date Filter (<= 30 days)
      bool isRecent = true;
      if (a['rawDate'] != null) {
        try {
          final dt = DateTime.parse(a['rawDate'].toString());
          if (now.difference(dt).inDays > 30) {
            isRecent = false;
          }
        } catch (_) {}
      }
      
      return isTargeted && isRecent;
    }).toList();

    if (listAnn.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
        children: [
          const SizedBox(height: 48),
          const Center(
            child: Column(
              children: [
                Icon(Icons.campaign_outlined, size: 48, color: AppColors.outline),
                SizedBox(height: 12),
                Text('Belum ada pengumuman', style: TextStyle(color: AppColors.outline)),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
      itemCount: listAnn.length,
      itemBuilder: (context, idx) {
        final ann = listAnn[idx];
        final isPinned = ann['isPinned'] == true;
        final target = ann['target']?.toString().toUpperCase() ?? 'SEMUA';

        return Card(
          color: isPinned ? AppColors.secondaryFixedDim.withOpacity(0.2) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isPinned ? const BorderSide(color: AppColors.secondaryFixed, width: 1.5) : BorderSide.none,
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text('Target: $target', style: const TextStyle(fontSize: 8, color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                    if (isPinned)
                      const Row(
                        children: [
                          Icon(Icons.push_pin, size: 12, color: AppColors.secondary),
                          SizedBox(width: 4),
                          Text('PINNED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(ann['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                ExpandableText(
                  text: ann['body'] as String,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant, height: 1.3),
                ),
                if (ann['date'] != null && ann['date'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(ann['date'] as String, style: const TextStyle(fontSize: 10, color: AppColors.outline)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// 7-day Line Chart Painter
class LineChartPainter extends CustomPainter {
  final List<int> data;
  final List<String> labels;

  LineChartPainter(this.data, this.labels);

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final paintDot = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.fill;

    final paintDotBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    int maxVal = 5; // Default max for scale
    for (var val in data) {
      if (val > maxVal) maxVal = val;
    }

    // Generate points dynamically
    final points = <Offset>[];
    for (int i = 0; i < 7; i++) {
      double val = 0;
      if (i < data.length) val = data[i].toDouble();
      
      final double x = size.width * (0.05 + (i * 0.15)); // 0.05, 0.20, 0.35, 0.50, 0.65, 0.80, 0.95
      // Y-axis inversion (0 at the top, max at bottom -> but we want max at top)
      final double y = size.height * 0.8 - ((val / maxVal) * (size.height * 0.7));
      points.add(Offset(x, y));
    }

    // Draw path
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paintLine);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Draw dots and labels
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      canvas.drawCircle(p, 6, paintDotBorder);
      canvas.drawCircle(p, 4, paintDot);

      // Value label
      textPainter.text = TextSpan(
        text: '${data[i]}',
        style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(p.dx - textPainter.width / 2, p.dy - 16));

      // Day label
      if (i < labels.length) {
        textPainter.text = TextSpan(
          text: labels[i],
          style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(p.dx - textPainter.width / 2, size.height * 0.88));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Interactive Mock Chat Screen
class MusyrifChatRoomScreen extends StatefulWidget {
  final Map<String, dynamic> contact;
  const MusyrifChatRoomScreen({super.key, required this.contact});

  @override
  State<MusyrifChatRoomScreen> createState() => _MusyrifChatRoomScreenState();
}

class _MusyrifChatRoomScreenState extends State<MusyrifChatRoomScreen> {
  final TextEditingController _sendCtrl = TextEditingController();

  List<Map<String, dynamic>> get _messages {
    final roomId = widget.contact['roomId'];
    if (roomId == null) return [];
    
    // Find the latest messages from global state
    final chat = globalStateInstance.chats.firstWhere(
      (c) => c['id'] == roomId,
      orElse: () => {},
    );
    if (chat.isNotEmpty) {
      return List<Map<String, dynamic>>.from(chat['messages'] ?? []);
    }
    return [];
  }

  void _sendMessage() {
    if (_sendCtrl.text.isEmpty) return;
    final txt = _sendCtrl.text;
    final roomId = widget.contact['roomId'];
    
    if (roomId != null) {
      globalStateInstance.sendChatMessage(roomId, txt);
    }
    _sendCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder to rebuild when global state updates (e.g. new message added)
    return ListenableBuilder(
      listenable: globalStateInstance,
      builder: (context, _) {
        final messages = _messages;
        final myId = globalStateInstance.currentUser?['id']?.toString() ?? '';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Navigator.pop(context)),
            title: Text(widget.contact['name'], style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
            elevation: 0.5,
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, idx) {
                    final m = messages[idx];
                    final isMe = m['senderId'] == myId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                          ),
                          border: isMe ? null : Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(m['text'], style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(m['time'], style: TextStyle(color: isMe ? Colors.white60 : Colors.black45, fontSize: 8)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Send Bar
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _sendCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Tulis pesan...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: AppColors.primary),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      }
    );
  }
}

String _getMonthName(int m) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  if (m >= 1 && m <= 12) return months[m - 1];
  return '';
}
