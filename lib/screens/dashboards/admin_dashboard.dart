import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../state/app_state.dart';
import '../login_screen.dart';
import '../../widgets/suntri_header.dart';
import '../modules/log_aktivitas_screen.dart';
import '../modules/tahfizh_screen.dart';
import '../modules/akademik_screen.dart';
import '../modules/asrama_screen.dart';
import '../modules/keuangan_screen.dart';
import '../modules/perizinan_screen.dart';
import '../modules/kesehatan_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Let's create a local singleton / instance reference of AppState
  // In a real app we'd inject it via Provider. For maximum compatibility and zero external dependencies,
  // we can use a static global or simply instantiate it or pass it.
  // Let's declare a static global AppState instance in AppState so all screens share the same instance!
  // Oh, wait! Let's check how we instantiated it in main.dart or if we can make AppState a Singleton.
  // Yes! Making AppState a Singleton in its own file makes it extremely easy to access from any widget!
  // Let's check if we can do this. Yes, we can just define a global instance or add a static getter:
  // static final AppState instance = AppState();
  // Let's modify app_state.dart to add: static final AppState instance = AppState();
  // Wait, let's view app_state.dart to see if we can do that or if we should just reference a global variable.
  // Let's check how we can do it. A global variable: final appState = AppState(); is very clean and standard!
  // Let's do that! Let's look at app_state.dart first.
  
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final user = _globalState.currentUser;
    final String name = user != null ? user['name'] ?? 'Admin' : 'Admin';
    final String initials = name.isNotEmpty
        ? name.split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join().toUpperCase()
        : 'AD';
    // We will reference the global appState
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: SUNTRIHeader(
        title: "Ma'had Tahfidz Rijaalul Quran",
        subtitle: '$name • Administrator',
        initials: initials,
        onLogout: () async {
          await globalStateInstance.logout();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        },
      ),
      body: ListenableBuilder(
        listenable: _globalState,
        builder: (context, child) {
          // Calculations
          final totalStudents = _globalState.students.length;
          final pendingPerms = _globalState.permissions.where((p) => p['status'] == 'Ditinjau').length;
          final uksSakit = _globalState.medicalRecords.where((m) => m['date'] == '2023-10-27').length;
          
          double totalTagihan = 0;
          double paidTagihan = 0;
          for (var b in _globalState.bills) {
            final amt = double.tryParse(b['amount']?.toString() ?? '0') ?? 0;
            totalTagihan += amt;
            if (b['status'] == 'Lunas' || b['status'] == 'lunas') {
              paidTagihan += amt;
            }
          }

          // Compute average attendance (safely handle missing attendance field)
          double totalPresencePct = 0;
          for (var s in _globalState.students) {
            final att = s['attendance'] as Map?;
            if (att != null) {
              final hadir = (att['hadir'] as num?)?.toInt() ?? 0;
              final sakit = (att['sakit'] as num?)?.toInt() ?? 0;
              final izin = (att['izin'] as num?)?.toInt() ?? 0;
              final alpha = (att['alpha'] as num?)?.toInt() ?? 0;
              final total = hadir + sakit + izin + alpha;
              if (total > 0) totalPresencePct += (hadir / total) * 100;
            }
          }
          final avgPresence = totalStudents > 0
              ? (totalPresencePct / totalStudents).toStringAsFixed(1)
              : '0';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date indicator
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Rabu, 26 Agt 2026',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),

                // 6 KPI Bento Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.45,
                  children: [
                    _buildKpiCard(
                      title: 'TOTAL SANTRI',
                      value: '$totalStudents',
                      subtitle: 'Santri Terdaftar',
                      icon: Icons.people,
                      color: AppColors.primary,
                      bgColor: AppColors.primary.withOpacity(0.08),
                    ),
                    _buildKpiCard(
                      title: 'PRESENSI HARI INI',
                      value: '$avgPresence%',
                      subtitle: 'Kehadiran Rata-rata',
                      icon: Icons.check_circle,
                      color: Colors.green,
                      bgColor: Colors.green.withOpacity(0.08),
                      onTap: _showAttendanceDetailModal,
                    ),
                    _buildKpiCard(
                      title: 'SETORAN HAFALAN',
                      value: '${_globalState.setorans.length}',
                      subtitle: 'Total Setoran Bulan Ini',
                      icon: Icons.menu_book,
                      color: Colors.orange,
                      bgColor: Colors.orange.withOpacity(0.08),
                    ),
                    _buildKpiCard(
                      title: 'IZIN DITINJAU',
                      value: '$pendingPerms',
                      subtitle: 'Perlu Konfirmasi',
                      icon: Icons.notifications_active,
                      color: Colors.purple,
                      bgColor: Colors.purple.withOpacity(0.08),
                    ),
                    _buildKpiCard(
                      title: 'PASIEN UKS',
                      value: '$uksSakit',
                      subtitle: 'Sakit Hari Ini',
                      icon: Icons.local_hospital,
                      color: Colors.red,
                      bgColor: Colors.red.withOpacity(0.08),
                    ),
                    _buildKpiCard(
                      title: 'TOTAL TAGIHAN',
                      value: 'Rp ${(totalTagihan / 1000000).toStringAsFixed(1)}M',
                      subtitle: 'Lunas: ${totalTagihan > 0 ? (paidTagihan / totalTagihan * 100).toStringAsFixed(0) : '0'}%',
                      icon: Icons.payment,
                      color: Colors.blue,
                      bgColor: Colors.blue.withOpacity(0.08),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2 Graphics (Custom Charts)
                const Text(
                  'Analisis Data Real-time',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                ),
                const SizedBox(height: 12),
                isMobile
                    ? Column(
                        children: [
                          _buildChartContainer(
                            title: 'Tren Kehadiran (7 Hari)',
                            child: _buildAttendanceChart(),
                          ),
                          const SizedBox(height: 12),
                          _buildChartContainer(
                            title: 'Keuangan SPP (Miliar Rp)',
                            child: _buildFinanceChart(paidTagihan, totalTagihan),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _buildChartContainer(
                              title: 'Tren Kehadiran (7 Hari)',
                              child: _buildAttendanceChart(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildChartContainer(
                              title: 'Keuangan SPP (Miliar Rp)',
                              child: _buildFinanceChart(paidTagihan, totalTagihan),
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 24),

                // Menu Modul Grid
                const Text(
                  'Modul Administrasi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                ),
                const SizedBox(height: 12),
                _buildModulesMenu(),
                const SizedBox(height: 24),

                // Activity Feed & Agenda Row
                isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Log Aktivitas Terbaru',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LogAktivitasScreen()),
                                  );
                                },
                                child: const Text('Lihat Semua', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                              )
                            ],
                          ),
                          const SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _globalState.activities.take(6).length,
                            itemBuilder: (context, idx) {
                              final act = _globalState.activities[idx];
                              return _buildActivityLogItem(act);
                            },
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Agenda Terdekat',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                          ),
                          const SizedBox(height: 12),
                          _buildAgendaCard('28 Agt', 'Rapat Komite Wali Santri', 'Aula Utama, 09:00'),
                          const SizedBox(height: 8),
                          _buildAgendaCard('01 Sep', 'Ujian Tengah Semester', 'Seluruh Kelas, 07:30'),
                          const SizedBox(height: 8),
                          _buildAgendaCard('05 Sep', 'Setoran Bulanan Tasmi\'', 'Masjid Jami\', 19:30'),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Feed
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Log Aktivitas Terbaru',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const LogAktivitasScreen()),
                                        );
                                      },
                                      child: const Text('Lihat Semua', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _globalState.activities.take(6).length,
                                  itemBuilder: (context, idx) {
                                    final act = _globalState.activities[idx];
                                    return _buildActivityLogItem(act);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Agenda
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.0),
                                  child: Text(
                                    'Agenda Terdekat',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                                  ),
                                ),
                                _buildAgendaCard('28 Agt', 'Rapat Komite Wali Santri', 'Aula Utama, 09:00'),
                                const SizedBox(height: 8),
                                _buildAgendaCard('01 Sep', 'Ujian Tengah Semester', 'Seluruh Kelas, 07:30'),
                                const SizedBox(height: 8),
                                _buildAgendaCard('05 Sep', 'Setoran Bulanan Tasmi\'', 'Masjid Jami\', 19:30'),
                              ],
                            ),
                          )
                        ],
                      ),
              ],
            ),
          );
        },
      ),
    );
  }



  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.015),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.8),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildChartContainer({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          SizedBox(height: 100, child: child),
        ],
      ),
    );
  }

  Widget _buildAttendanceChart() {
    // Draw a custom styled bar chart representing weekly attendance
    final heights = [0.95, 0.92, 0.98, 0.89, 0.94, 0.96, 0.95];
    final days = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (idx) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 14,
                  height: 80 * heights[idx],
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(days[idx], style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant)),
          ],
        );
      }),
    );
  }

  Widget _buildFinanceChart(double paid, double total) {
    // Side by side bars: Target vs Realisasi
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 24,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    '${(total / 1000000).toStringAsFixed(1)}jt',
                    style: const TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text('Target', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant)),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 24,
              height: 70 * (paid / (total > 0 ? total : 1)),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    '${(paid / 1000000).toStringAsFixed(1)}jt',
                    style: const TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text('Masuk', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityLogItem(Map<String, dynamic> act) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 4,
            backgroundColor: act['color'],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(act['title'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onBackground)),
                    Text(act['time'], style: const TextStyle(fontSize: 8, color: AppColors.outline)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  act['description'],
                  style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAgendaCard(String date, String title, String venue) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.secondaryFixedDim.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              date,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.secondary),
            ),
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.onBackground)),
          const SizedBox(height: 2),
          Text(venue, style: const TextStyle(fontSize: 9, color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildModulesMenu() {
    final modules = [
      {'name': 'Log Akt.', 'icon': Icons.list_alt, 'color': AppColors.primary, 'screen': const LogAktivitasScreen()},
      {'name': 'Tahfizh', 'icon': Icons.menu_book, 'color': Colors.orange, 'screen': const TahfizhScreen()},
      {'name': 'Akademik', 'icon': Icons.school, 'color': Colors.teal, 'screen': const AkademikScreen()},
      {'name': 'Asrama', 'icon': Icons.home, 'color': Colors.cyan, 'screen': const AsramaScreen()},
      {'name': 'Keuangan', 'icon': Icons.payment, 'color': Colors.blue, 'screen': const KeuanganScreen()},
      {'name': 'Perizinan', 'icon': Icons.assignment_turned_in, 'color': Colors.purple, 'screen': const PerizinanScreen()},
      {'name': 'Kesehatan', 'icon': Icons.local_hospital, 'color': Colors.red, 'screen': const KesehatanScreen()},
    ];

    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: modules.length,
        itemBuilder: (context, idx) {
          final m = modules[idx];
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => m['screen'] as Widget));
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (m['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(m['icon'] as IconData, color: m['color'] as Color, size: 20),
                  ),
                ),
                const SizedBox(height: 4),
                Text(m['name'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAttendanceDetailModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Detail Kehadiran Santri',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onBackground),
              ),
              const SizedBox(height: 4),
              const Text('Klasifikasi absensi santri hari ini.', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 20),

              // Classification Tabs
              DefaultTabController(
                length: 4,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.outline,
                      indicatorColor: AppColors.primary,
                      tabs: const [
                        Tab(text: 'Hadir'),
                        Tab(text: 'Sakit'),
                        Tab(text: 'Izin'),
                        Tab(text: 'Alpha'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: TabBarView(
                        children: [
                          _buildStudentAttendanceList('hadir'),
                          _buildStudentAttendanceList('sakit'),
                          _buildStudentAttendanceList('izin'),
                          _buildStudentAttendanceList('alpha'),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudentAttendanceList(String type) {
    // Filter students by presence category
    // In our mock data, students have total stats. We categorize them based on higher counts.
    final list = _globalState.students.where((s) {
      final att = s['attendance'] as Map?;
      if (att == null) return false;
      if (type == 'hadir') return (att['hadir'] ?? 0) >= 20;
      if (type == 'sakit') return (att['sakit'] ?? 0) > 2;
      if (type == 'izin') return (att['izin'] ?? 0) > 2;
      if (type == 'alpha') return (att['alpha'] ?? 0) > 2;
      return false;
    }).toList();

    if (list.isEmpty) {
      return const Center(
        child: Text('Tidak ada santri di kategori ini.', style: TextStyle(fontSize: 12, color: AppColors.outline)),
      );
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final std = list[idx];
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: AppColors.surfaceContainer,
            child: Text(std['initials']),
          ),
          title: Text(std['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Kelas: ${std['class']} • NIS: ${std['nis']}'),
        );
      },
    );
  }
}

// Global AppState reference to be initialized in main.dart
final AppState _globalState = AppState();
AppState get globalStateInstance => _globalState;
