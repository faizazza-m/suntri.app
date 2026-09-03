import 'package:flutter/material.dart';
import 'dart:ui';
import '../login_screen.dart';
import 'admin_dashboard.dart'; // To access globalStateInstance
import '../../widgets/suntri_header.dart';
import '../../constants/colors.dart';

class MudirDashboard extends StatefulWidget {
  const MudirDashboard({super.key});

  @override
  State<MudirDashboard> createState() => _MudirDashboardState();
}

class _MudirDashboardState extends State<MudirDashboard> {
  int _currentTabIndex = 0;
  int _laporanSubTabIndex = 0;
  String _laporanSearchQuery = '';

  @override
  Widget build(BuildContext context) {
    final user = globalStateInstance.currentUser;
    final String name = user != null ? user['name'] ?? 'Mudir' : 'Mudir';
    final String initials = name.isNotEmpty
        ? name.split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join().toUpperCase()
        : 'MD';

    return Scaffold(
      extendBodyBehindAppBar: false,
      extendBody: true,
      backgroundColor: AppColors.background,
      appBar: SUNTRIHeader(
        title: "Ma'had Tahfidz Rijaalul Quran",
        subtitle: '$name • Mudir',
        initials: initials,
        onLogout: () async {
          await globalStateInstance.logout();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        },
      ),
      body: Container(
        height: double.infinity,

        child: ListenableBuilder(
          listenable: globalStateInstance,
          builder: (context, child) {
            final students = globalStateInstance.students;
            final halaqohs = globalStateInstance.halaqohs;

            // 1. Calculations for Early Warning Alerts
            final List<Map<String, dynamic>> sickToday = [];
            final List<Map<String, dynamic>> alphaToday = [];
            final List<Map<String, dynamic>> lowAttendance = [];

            // Sick today: check if any student has UKS record today (2023-10-27) or sick leave
            for (var record in globalStateInstance.medicalRecords) {
              if (record['date'] == '2023-10-27') {
                final std = students.firstWhere((s) => s['name'] == record['studentName'], orElse: () => {});
                if (std.isNotEmpty) {
                  sickToday.add({
                    'name': record['studentName'],
                    'detail': '${record['diagnosis']} (${record['symptom']})',
                  });
                }
              }
            }

            // Alpha and Low attendance checks
            for (var s in students) {
              final att = s['attendance'] as Map?;
              if (att == null) continue;
              final hadir = (att['hadir'] as num?)?.toInt() ?? 0;
              final sakit = (att['sakit'] as num?)?.toInt() ?? 0;
              final izin  = (att['izin']  as num?)?.toInt() ?? 0;
              final alpha = (att['alpha'] as num?)?.toInt() ?? 0;
              final total = hadir + sakit + izin + alpha;
              if (total > 0) {
                final rate = (hadir / total) * 100;
                if (alpha > 0) {
                  alphaToday.add({
                    'name': s['name'],
                    'class': s['class'],
                    'count': alpha,
                  });
                }
                if (rate < 75.0) {
                  lowAttendance.add({
                    'name': s['name'],
                    'rate': rate.toStringAsFixed(1),
                  });
                }
              }
            }

            // 2. Executive statistics calculations
            final totalStudents = students.length;
            final avgJuz = totalStudents > 0 ? (students.map((s) => s['juz'] as int).fold(0, (sum, juz) => sum + juz) / totalStudents) : 0.0;
            
            // Overall attendance rate
            double totalHadir = 0;
            double totalAll = 0;
            for (var s in students) {
              final att = s['attendance'] as Map?;
              if (att == null) continue;
              totalHadir += (att['hadir'] as num?)?.toDouble() ?? 0;
              totalAll += ((att['hadir'] as num?)?.toDouble() ?? 0) +
                  ((att['sakit'] as num?)?.toDouble() ?? 0) +
                  ((att['izin'] as num?)?.toDouble() ?? 0) +
                  ((att['alpha'] as num?)?.toDouble() ?? 0);
            }
            final overallAttendance = totalAll > 0 ? (totalHadir / totalAll) * 100 : 0.0;

            // 3. Musyrif performance monitoring list (dynamically generated from database halaqohs & setorans)
            final String todayStr = DateTime.now().toIso8601String().split('T')[0];
            final List<Map<String, dynamic>> musyrifs = halaqohs.map((h) {
              final String teacherName = h['teacher'] ?? 'Musyrif';
              final List<String> studentIds = List<String>.from(h['studentIds'] ?? []);
              
              // Check if any student in this halaqoh has setoran today
              final hasHafalanToday = globalStateInstance.setorans.any((s) {
                final student = students.firstWhere((std) => std['name'] == s['studentName'], orElse: () => {});
                return student.isNotEmpty && 
                       studentIds.contains(student['id']) && 
                       s['date'] == todayStr;
              });

              // Check if any student in this halaqoh has permission today
              final hasAttendanceToday = globalStateInstance.permissions.any((p) {
                final student = students.firstWhere((std) => std['name'] == p['studentName'], orElse: () => {});
                return student.isNotEmpty && 
                       studentIds.contains(student['id']) && 
                       p['dateStart'] == todayStr;
              });

              return {
                'name': teacherName,
                'halaqoh': h['name'] ?? 'Halaqoh',
                'absensiInput': hasAttendanceToday || hasHafalanToday,
                'hafalanInput': hasHafalanToday,
              };
            }).toList();

            return IndexedStack(
              index: _currentTabIndex,
              children: [
                _buildDashboardTab(totalStudents, halaqohs.length, avgJuz, overallAttendance, sickToday, alphaToday, lowAttendance),
                _buildKinerjaTab(musyrifs),
                _buildLaporanTab(),
                _buildAnalisisTab(students, globalStateInstance.attendance7Days),
                _buildProfileTab(),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.75),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
              currentIndex: _currentTabIndex,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.outline,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              iconSize: 22,
              onTap: (index) {
                setState(() {
                  _currentTabIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard, color: AppColors.primary), label: 'Dashboard'),
                BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people, color: AppColors.primary), label: 'Kinerja'),
                BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment, color: AppColors.primary), label: 'Laporan'),
                BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics, color: AppColors.primary), label: 'Analisis'),
                BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person, color: AppColors.primary), label: 'Profil'),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardTab(
    int totalStudents,
    int halaqohsCount,
    double avgJuz,
    double overallAttendance,
    List<Map<String, dynamic>> sickToday,
    List<Map<String, dynamic>> alphaToday,
    List<Map<String, dynamic>> lowAttendance,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.dashboard, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'PANEL EKSEKUTIF MUDIR',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildGlassStatCard('Total Santri', '$totalStudents Orang', Icons.people, const Color(0xFF00E5FF)),
              _buildGlassStatCard('Halaqoh Aktif', '$halaqohsCount Halaqoh', Icons.layers, const Color(0xFFFFB300)),
              _buildGlassStatCard('Rerata Hafalan', '${avgJuz.toStringAsFixed(1)} Juz', Icons.menu_book, const Color(0xFFE040FB)),
              _buildGlassStatCard('Kehadiran Bulanan', '${overallAttendance.toStringAsFixed(1)}%', Icons.check_circle, AppColors.primary),
            ],
          ),
          const SizedBox(height: 24),

          const Text(
            'Sistem Peringatan Dini (Early Warning)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onBackground),
          ),
          const SizedBox(height: 4),
          const Text(
            'Deteksi otomatis santri berisiko tinggi / kendala hari ini',
            style: TextStyle(fontSize: 11, color: AppColors.onBackground),
          ),
          const SizedBox(height: 12),
          _buildEarlyWarningAlerts(sickToday, alphaToday, lowAttendance),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildKinerjaTab(List<Map<String, dynamic>> musyrifs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.people, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'MONITORING KINERJA MUSYRIF',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text(
            'Status Kehadiran & Setoran Musyrif',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onBackground),
          ),
          const SizedBox(height: 4),
          const Text(
            'Status input absensi & hafalan oleh musyrif hari ini',
            style: TextStyle(fontSize: 11, color: AppColors.onBackground),
          ),
          const SizedBox(height: 12),
          _buildMusyrifPerformanceCard(musyrifs),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLaporanTab() {
    var setorans = globalStateInstance.setorans.where((s) {
      if (_laporanSearchQuery.isEmpty) return true;
      return (s['studentName'] ?? '').toString().toLowerCase().contains(_laporanSearchQuery.toLowerCase()) ||
             (s['surah'] ?? '').toString().toLowerCase().contains(_laporanSearchQuery.toLowerCase());
    }).toList();

    // Urutkan dari yang terbaru (descending)
    setorans.sort((a, b) {
      final dateA = (a['date'] ?? '').toString();
      final dateB = (b['date'] ?? '').toString();
      return dateB.compareTo(dateA);
    });

    // Batasi maksimal 20 data
    if (setorans.length > 20) {
      setorans = setorans.sublist(0, 20);
    }

    final students = globalStateInstance.students.where((s) {
      if (_laporanSearchQuery.isEmpty) return true;
      return (s['name'] ?? '').toString().toLowerCase().contains(_laporanSearchQuery.toLowerCase()) ||
             (s['class'] ?? '').toString().toLowerCase().contains(_laporanSearchQuery.toLowerCase());
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.assignment, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'LAPORAN PORTAL',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Sub Tab Selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _laporanSubTabIndex = 0;
                        _laporanSearchQuery = '';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _laporanSubTabIndex == 0 ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'Setoran Tahfizh',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _laporanSubTabIndex == 0 ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _laporanSubTabIndex = 1;
                        _laporanSearchQuery = '';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _laporanSubTabIndex == 1 ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'Kehadiran Santri',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _laporanSubTabIndex == 1 ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search Box
          TextField(
            onChanged: (val) {
              setState(() {
                _laporanSearchQuery = val;
              });
            },
            style: const TextStyle(color: AppColors.onBackground, fontSize: 13),
            decoration: InputDecoration(
              hintText: _laporanSubTabIndex == 0 ? 'Cari nama santri atau surah...' : 'Cari nama santri atau kelas...',
              hintStyle: const TextStyle(color: AppColors.outline, fontSize: 12),
              prefixIcon: const Icon(Icons.search, color: AppColors.onBackground, size: 18),
              filled: true,
              fillColor: AppColors.surfaceContainer,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.onBackground.withOpacity(0.06)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Report Content
          _laporanSubTabIndex == 0
              ? _buildLaporanSetoranContent(setorans)
              : _buildLaporanKehadiranContent(students),

          const SizedBox(height: 160),
        ],
      ),
    );
  }

  Widget _buildLaporanSetoranContent(List<Map<String, dynamic>> setorans) {
    if (setorans.isEmpty) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        child: const Text('Tidak ada laporan setoran ditemukan.', style: TextStyle(color: AppColors.onBackground)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: setorans.length,
        separatorBuilder: (ctx, idx) => Divider(color: AppColors.outlineVariant, height: 1),
        itemBuilder: (ctx, idx) {
          final s = setorans[idx];
          final type = s['type'] ?? 'Ziyadah';
          final isZiyadah = type.toString().toLowerCase() == 'ziyahdah' || type.toString().toLowerCase() == 'ziyadah';

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isZiyadah ? AppColors.primary.withOpacity(0.15) : const Color(0xFF00B0FF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isZiyadah ? AppColors.primary : const Color(0xFF00B0FF),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['studentName'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.onBackground),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Surah ${s['surah']} • Ayat ${s['ayatDari']}-${s['ayatSampai']} (Juz ${s['juz']})',
                        style: const TextStyle(fontSize: 11, color: AppColors.onBackground),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kelancaran: ${s['kelancaran']} • Tajwid: ${s['tajwid']}',
                        style: const TextStyle(fontSize: 9, color: AppColors.onBackground),
                      ),
                    ],
                  ),
                ),
                Text(
                  s['date'] ?? '',
                  style: const TextStyle(fontSize: 10, color: AppColors.outline),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLaporanKehadiranContent(List<Map<String, dynamic>> students) {
    if (students.isEmpty) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        child: const Text('Tidak ada data kehadiran santri.', style: TextStyle(color: AppColors.onBackground)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 4, child: Text('SANTRI / KELAS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onBackground))),
                Expanded(flex: 5, child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('H', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onBackground)),
                    Text('S', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onBackground)),
                    Text('I', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onBackground)),
                    Text('A', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onBackground)),
                    Text('%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onBackground)),
                  ],
                )),
              ],
            ),
          ),
          // Student List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: students.length,
            separatorBuilder: (ctx, idx) => Divider(color: AppColors.outlineVariant, height: 1),
            itemBuilder: (ctx, idx) {
              final s = students[idx];
              final att = s['attendance'] ?? {'hadir': 0, 'sakit': 0, 'izin': 0, 'alpha': 0};
              final total = att['hadir'] + att['sakit'] + att['izin'] + att['alpha'];
              final rate = total > 0 ? (att['hadir'] / total * 100) : 0.0;
              final isLow = total > 0 && rate < 75.0;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.onBackground)),
                          const SizedBox(height: 2),
                          Text(s['class'] ?? '', style: const TextStyle(fontSize: 9, color: AppColors.onBackground)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${att['hadir']}', style: const TextStyle(fontSize: 11, color: AppColors.onBackground)),
                          Text('${att['sakit']}', style: const TextStyle(fontSize: 11, color: AppColors.onBackground)),
                          Text('${att['izin']}', style: const TextStyle(fontSize: 11, color: AppColors.onBackground)),
                          Text('${att['alpha']}', style: TextStyle(fontSize: 11, color: att['alpha'] > 0 ? Colors.redAccent : AppColors.onSurfaceVariant)),
                          Text(
                            '${rate.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isLow ? Colors.redAccent : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnalisisTab(List<Map<String, dynamic>> students, Map<String, dynamic> att7Days) {
    // Calculate Hafalan per class
    final Map<String, List<int>> classJuzMap = {};
    for (var s in students) {
      final cls = (s['class'] ?? 'Lainnya').toString();
      final juz = s['juz'] as int? ?? 0;
      classJuzMap.putIfAbsent(cls, () => []);
      classJuzMap[cls]!.add(juz);
    }
    List<String> barLabels = [];
    List<double> barValues = [];
    classJuzMap.forEach((cls, juzList) {
      final avg = juzList.isEmpty ? 0.0 : (juzList.reduce((a, b) => a + b) / juzList.length);
      barLabels.add(cls);
      barValues.add(avg);
    });
    // Limit to max 4 classes
    if (barLabels.length > 4) {
      barLabels = barLabels.sublist(0, 4);
      barValues = barValues.sublist(0, 4);
    } else if (barLabels.isEmpty) {
      barLabels = ['Belum ada'];
      barValues = [0.0];
    }

    List<String> lineLabels = List<String>.from(att7Days['labels'] ?? []);
    List<double> lineValues = List<double>.from(att7Days['values'] ?? []);
    if (lineLabels.isEmpty) {
       lineLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Ahd'];
       lineValues = [0,0,0,0,0,0,0];
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'ANALISIS DATA & LAPORAN GRAFIK',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildGlassChartCard(
            title: 'Tren Rerata Hafalan per Kelas',
            subtitle: 'Pengukuran dalam satuan Juz',
            chartWidget: SizedBox(
              height: 150,
              width: double.infinity,
              child: CustomPaint(
                painter: BarChartPainter(barValues, barLabels),
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildGlassChartCard(
            title: 'Tren Kehadiran Santri (7 Hari Terakhir)',
            subtitle: 'Persentase rata-rata kehadiran harian',
            chartWidget: SizedBox(
              height: 150,
              width: double.infinity,
              child: CustomPaint(
                painter: LineChartPainter(lineValues, lineLabels),
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    final currentUser = globalStateInstance.currentUser;
    final String name = currentUser?['name'] ?? 'Mudir';
    final String email = currentUser?['email'] ?? '-';
    final String phone = currentUser?['phone'] ?? '-';
    final String role = currentUser?['role'] ?? 'Mudir';
    final String initials = name.trim().isNotEmpty
        ? name.trim().split(' ').take(2).map((e) => e.isEmpty ? '' : e[0].toUpperCase()).join()
        : 'M';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'PROFIL MUDIR',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.04), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  child: Text(
                    initials,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        role,
                        style: const TextStyle(fontSize: 12, color: AppColors.onBackground),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          const Text(
            'Informasi Kontak & Kredensial',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.onBackground),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.04), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Alamat Email', style: TextStyle(fontSize: 11, color: AppColors.onBackground)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email_outlined, color: AppColors.onBackground, size: 18),
                      const SizedBox(width: 12),
                      Text(email, style: const TextStyle(color: AppColors.onBackground, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                const Text('Nomor WhatsApp', style: TextStyle(fontSize: 11, color: AppColors.onBackground)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_outlined, color: AppColors.onBackground, size: 18),
                      const SizedBox(width: 12),
                      Text(phone.isNotEmpty ? phone : '-', style: const TextStyle(color: AppColors.onBackground, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withOpacity(0.15), width: 1.2),
            ),
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text('Keluar dari Aplikasi', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // --- GLASSMORPHIC UI COMPONENTS ---
  Widget _buildGlassStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.03), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onBackground),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEarlyWarningAlerts(
    List<Map<String, dynamic>> sick,
    List<Map<String, dynamic>> alpha,
    List<Map<String, dynamic>> lowAttendance,
  ) {
    if (sick.isEmpty && alpha.isEmpty && lowAttendance.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF00C853).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF00C853).withOpacity(0.2), width: 1),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Semua data aman. Tidak ada alert kritis hari ini.', style: TextStyle(color: AppColors.onBackground, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.03), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. Sick alerts
          ...sick.map((s) => _buildAlertRow(
                title: 'Santri Sakit Hari Ini',
                desc: '${s['name']} dirujuk ke UKS: ${s['detail']}',
                icon: Icons.local_hospital,
                iconColor: const Color(0xFFEF5350),
              )),
          // 2. Alpha alerts
          ...alpha.map((a) => _buildAlertRow(
                title: 'Siswa Absen Alpha',
                desc: '${a['name']} (${a['class']}) terdeteksi Alpha sebanyak ${a['count']} kali.',
                icon: Icons.warning_amber_rounded,
                iconColor: const Color(0xFFFFB300),
              )),
          // 3. Low attendance rates
          ...lowAttendance.map((la) => _buildAlertRow(
                title: 'Kehadiran Kritis (<75%)',
                desc: 'Kehadiran ${la['name']} sangat rendah (${la['rate']}%). Butuh tindak lanjut.',
                icon: Icons.trending_down,
                iconColor: const Color(0xFFE53935),
              )),
        ],
      ),
    );
  }

  Widget _buildAlertRow({
    required String title,
    required String desc,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.onBackground.withOpacity(0.05))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: iconColor)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(color: AppColors.onBackground, fontSize: 11)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMusyrifPerformanceCard(List<Map<String, dynamic>> musyrifs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 4, child: Text('NAMA MUSYRIF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onBackground))),
                Expanded(flex: 3, child: Text('ABSEN HARI INI', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onBackground))),
                Expanded(flex: 3, child: Text('SETORAN HARI INI', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onBackground))),
              ],
            ),
          ),
          // Rows
          ...musyrifs.map((m) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.onBackground)),
                        const SizedBox(height: 2),
                        Text(m['halaqoh'], style: const TextStyle(fontSize: 9, color: AppColors.onBackground)),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: Icon(
                        m['absensiInput'] ? Icons.check_circle : Icons.cancel,
                        color: m['absensiInput'] ? AppColors.primary : const Color(0xFFEF5350),
                        size: 16,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: Icon(
                        m['hafalanInput'] ? Icons.check_circle : Icons.cancel,
                        color: m['hafalanInput'] ? AppColors.primary : const Color(0xFFEF5350),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGlassChartCard({
    required String title,
    required String subtitle,
    required Widget chartWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.onBackground)),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.onBackground)),
          const SizedBox(height: 20),
          chartWidget,
        ],
      ),
    );
  }
}

// Chart Legend Row helper
class _ChartLegendRow extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegendRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: AppColors.onBackground, fontSize: 10)),
      ],
    );
  }
}

// ==================== CUSTOM CHART PAINTERS ====================

class BarChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;

  BarChartPainter(this.values, this.labels);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final double barWidth = size.width / (values.length * 2 - 1);
    double maxVal = values.reduce((a, b) => a > b ? a : b) * 1.2;
    if (maxVal < 5.0) maxVal = 5.0;

    for (var i = 0; i < values.length; i++) {
      final double x = i * 2 * barWidth;
      final double h = (values[i] / maxVal) * size.height;
      final double y = size.height - h;

      // Draw background channel
      final paintBg = Paint()
        ..color = AppColors.surfaceContainer
        ..style = PaintingStyle.fill;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, 0, barWidth, size.height), const Radius.circular(4)),
        paintBg,
      );

      // Draw active bar (gradient blue-teal)
      final paintBar = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF0091EA), Color(0xFF00E5FF)],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ).createShader(Rect.fromLTWH(x, y, barWidth, h))
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, barWidth, h), const Radius.circular(4)),
        paintBar,
      );

      // Draw text value inside or above
      final valueTextPainter = TextPainter(
        text: TextSpan(text: '${values[i].toStringAsFixed(1)} Jz', style: const TextStyle(color: AppColors.onBackground, fontSize: 8)),
        textDirection: TextDirection.ltr,
      )..layout();
      valueTextPainter.paint(canvas, Offset(x + (barWidth - valueTextPainter.width) / 2, y - 14));
      
      // Draw bottom label (abbreviated)
      final textLabel = labels[i].length > 8 ? labels[i].substring(6) : labels[i];
      final labelTextPainter = TextPainter(
        text: TextSpan(text: textLabel, style: const TextStyle(color: AppColors.onBackground, fontSize: 8)),
        textDirection: TextDirection.ltr,
      )..layout();
      labelTextPainter.paint(canvas, Offset(x + (barWidth - labelTextPainter.width) / 2, size.height + 8));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LineChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> days;

  LineChartPainter(this.data, this.days);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final double stepX = data.length > 1 ? size.width / (data.length - 1) : size.width;
    double minVal = data.reduce((a, b) => a < b ? a : b) - 5.0;
    if (minVal < 0) minVal = 0;
    double maxVal = data.reduce((a, b) => a > b ? a : b) + 5.0;
    if (maxVal > 100) maxVal = 100.0;
    if (maxVal <= minVal) maxVal = minVal + 10;

    final path = Path();
    final areaPath = Path();

    for (var i = 0; i < data.length; i++) {
      final double x = i * stepX;
      final double y = size.height - ((data[i] - minVal) / (maxVal - minVal)) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
        areaPath.moveTo(x, size.height);
        areaPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        areaPath.lineTo(x, y);
      }
    }

    areaPath.lineTo(size.width, size.height);
    areaPath.close();

    // Draw shaded area
    final paintArea = Paint()
      ..shader = LinearGradient(
        colors: [AppColors.primary.withOpacity(0.15), Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(areaPath, paintArea);

    // Draw active stroke line
    final paintLine = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, paintLine);

    // Draw grid lines
    final paintGrid = Paint()
      ..color = AppColors.outlineVariant
      ..strokeWidth = 0.5;
    for (var i = 1; i < 4; i++) {
      final h = size.height * (i / 4);
      canvas.drawLine(Offset(0, h), Offset(size.width, h), paintGrid);
    }

    // Draw dots and text
    final paintDot = Paint()..color = AppColors.primary..style = PaintingStyle.fill;
    final paintInnerDot = Paint()..color = AppColors.background..style = PaintingStyle.fill;

    for (var i = 0; i < data.length; i++) {
      final double x = i * stepX;
      final double y = size.height - ((data[i] - minVal) / (maxVal - minVal)) * size.height;

      canvas.drawCircle(Offset(x, y), 3.5, paintDot);
      canvas.drawCircle(Offset(x, y), 1.5, paintInnerDot);

      _drawText(canvas, '${data[i].toInt()}%', Offset(x - 6, y - 12), const TextStyle(color: AppColors.onBackground, fontSize: 8));
      _drawText(canvas, days[i], Offset(x - 6, size.height + 4), const TextStyle(color: AppColors.onBackground, fontSize: 8));
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DoughnutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = size.width / 2 * 0.8;
    const double thickness = 10.0;

    final rect = Rect.fromCircle(center: Offset(centerX, centerY), radius: radius);

    final paint1 = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    final paint2 = Paint()
      ..color = const Color(0xFFFFB300)
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    final paint3 = Paint()
      ..color = const Color(0xFF00B0FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    double startAngle = -3.14 / 2;

    // Class 10 MIPA/IPS (60%)
    double sweepAngle1 = 2 * 3.14 * 0.6;
    canvas.drawArc(rect, startAngle, sweepAngle1 - 0.1, false, paint1);
    startAngle += sweepAngle1;

    // Class 11 IPS (25%)
    double sweepAngle2 = 2 * 3.14 * 0.25;
    canvas.drawArc(rect, startAngle, sweepAngle2 - 0.1, false, paint2);
    startAngle += sweepAngle2;

    // Others (15%)
    double sweepAngle3 = 2 * 3.14 * 0.15;
    canvas.drawArc(rect, startAngle, sweepAngle3 - 0.05, false, paint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
