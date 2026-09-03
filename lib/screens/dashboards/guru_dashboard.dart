import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import 'admin_dashboard.dart';
import '../login_screen.dart';
import '../modules/akademik_screen.dart';
import '../weekly_report_screen.dart';
import 'dart:ui';
import '../../widgets/expandable_text.dart';
import '../../widgets/suntri_header.dart';
import '../../services/notification_service.dart';

class GuruDashboard extends StatefulWidget {
  const GuruDashboard({super.key});

  @override
  State<GuruDashboard> createState() => _GuruDashboardState();
}

class _GuruDashboardState extends State<GuruDashboard> {
  int _currentTabIndex = 0;

  // Selected day for Schedule Tab
  String _selectedScheduleDay = 'Senin';

  String _getCurrentDayIndonesian() {
    final days = {
      DateTime.monday: 'Senin',
      DateTime.tuesday: 'Selasa',
      DateTime.wednesday: 'Rabu',
      DateTime.thursday: 'Kamis',
      DateTime.friday: 'Jumat',
      DateTime.saturday: 'Sabtu',
      DateTime.sunday: 'Minggu',
    };
    return days[DateTime.now().weekday] ?? 'Senin';
  }

  String _getFormattedDateIndonesian() {
    final now = DateTime.now();
    final days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final dayName = days[now.weekday % 7];
    final monthName = months[now.month - 1];
    return '$dayName, ${now.day} $monthName ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globalStateInstance,
      builder: (context, child) {
        final user = globalStateInstance.currentUser;
        final String name = user != null ? user['name'] ?? 'Guru' : 'Guru';
        final String initials = name.isNotEmpty
            ? name.split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join().toUpperCase()
            : 'G';

        // 1. Filter schedules for the logged in teacher
        final mySchedules = globalStateInstance.schedules
            .where((s) => s['teacherId'].toString() == user?['id']?.toString())
            .toList();

        // 2. Count distinct subjects
        final mySubjects = mySchedules.map((s) => s['subject'].toString()).toSet();
        final int mapelCount = mySubjects.length;

        // 3. Total schedules/lessons
        final int jadwalCount = mySchedules.length;

        // 4. Total students in classes taught by teacher
        final myClasses = mySchedules.map((s) => s['class'].toString()).toSet();
        final int santriCount = globalStateInstance.students
            .where((student) => myClasses.contains(student['class']))
            .length;

        // 5. Total grades entered by the teacher
        final int gradesCount = globalStateInstance.grades
            .where((g) => mySubjects.contains(g['subject']))
            .length;

        // 6. Schedule notifications (runs once per schedule change)
        final guruId = user?['id']?.toString() ?? '';
        if (mySchedules.isNotEmpty && guruId.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            NotificationService.cancelAllMusyrifReminders(); // Pastikan bersih dari role musyrif
            NotificationService.scheduleGuruReminders(mySchedules, guruId);
          });
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6FA),
          extendBody: true,
          appBar: SUNTRIHeader(
            title: "Ma'had Tahfidz Rijaalul Quran",
            subtitle: '$name • Guru Pengajar',
            initials: initials,
            onLogout: () async {
              await globalStateInstance.logout();
              if (!context.mounted) return;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
          ),
          body: _buildTabContent(name, mapelCount, jadwalCount, santriCount, gradesCount, mySchedules),
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
              BottomNavigationBarItem(
                icon: Icon(Icons.grid_view),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.star_outline),
                label: 'Nilai',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                label: 'Jadwal',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.description_outlined),
                label: 'Jurnal',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.campaign_outlined),
                label: 'Info',
              ),
            ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Tab router
  Widget _buildTabContent(
    String name,
    int mapelCount,
    int jadwalCount,
    int santriCount,
    int gradesCount,
    List<Map<String, dynamic>> mySchedules,
  ) {
    switch (_currentTabIndex) {
      case 0:
        return _buildBerandaTab(name, mapelCount, jadwalCount, santriCount, gradesCount, mySchedules);
      case 1:
        return const AkademikScreen(isTab: true);
      case 2:
        return _buildJadwalTab(mySchedules);
      case 3:
        return const WeeklyReportScreen(isTab: true);
      case 4:
        return _buildInfoTab();
      default:
        return _buildBerandaTab(name, mapelCount, jadwalCount, santriCount, gradesCount, mySchedules);
    }
  }

  // TAB 1: BERANDA
  Widget _buildBerandaTab(
    String name,
    int mapelCount,
    int jadwalCount,
    int santriCount,
    int gradesCount,
    List<Map<String, dynamic>> mySchedules,
  ) {
    final todayDay = _getCurrentDayIndonesian();
    final todaySchedules = mySchedules.where((s) => s['day'] == todayDay).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF107B5C), Color(0xFF063A29)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF107B5C).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Assalamu'alaikum,",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    const Text('👋', style: TextStyle(fontSize: 19)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      _getFormattedDateIndonesian(),
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildStatItem(mapelCount.toString(), 'MAPEL', Icons.menu_book),
                    const SizedBox(width: 10),
                    _buildStatItem(jadwalCount.toString(), 'JADWAL', Icons.calendar_month),
                    const SizedBox(width: 10),
                    _buildStatItem(santriCount.toString(), 'SANTRI', Icons.groups),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2x2 Grid of KPI Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildKPICard(
                icon: Icons.menu_book,
                iconColor: Colors.teal,
                label: 'MATA PELAJARAN',
                value: mapelCount.toString(),
              ),
              _buildKPICard(
                icon: Icons.calendar_today,
                iconColor: Colors.purple,
                label: 'JADWAL/MINGGU',
                value: jadwalCount.toString(),
              ),
              _buildKPICard(
                icon: Icons.people,
                iconColor: Colors.orange,
                label: 'TOTAL SANTRI',
                value: santriCount.toString(),
              ),
              _buildKPICard(
                icon: Icons.star,
                iconColor: Colors.red,
                label: 'NILAI BULAN INI',
                value: gradesCount.toString(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Teaching schedule header
          const Text(
            'Jadwal Mengajar Hari Ini',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onBackground),
          ),
          const SizedBox(height: 12),

          if (todaySchedules.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: const Column(
                children: [
                  Icon(Icons.event_busy, size: 40, color: AppColors.outline),
                  SizedBox(height: 8),
                  Text(
                    'Tidak ada jadwal mengajar hari ini',
                    style: TextStyle(color: AppColors.outline, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            ...todaySchedules.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _buildScheduleItem(
                    '${item['timeStart']} - ${item['timeEnd']}',
                    item['class']!,
                    item['subject']!,
                    item['room']!,
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildStatItem(String count, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(height: 8),
            Text(
              count,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: iconColor.withOpacity(0.15), width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            iconColor.withOpacity(0.04),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey.shade300, size: 14),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(color: iconColor, fontSize: 18, fontWeight: FontWeight.w900, height: 1),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(String time, String className, String subject, String room) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.timer_outlined, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(subject, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black87)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.class_outlined, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('$className • $room', style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  // TAB 3: JADWAL
  Widget _buildJadwalTab(List<Map<String, dynamic>> mySchedules) {
    final days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final filteredSchedules = mySchedules.where((s) => s['day'] == _selectedScheduleDay).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jadwal Mengajar Pekanan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onBackground),
          ),
          const SizedBox(height: 12),

          // Horizontal Day Selector
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              itemBuilder: (context, idx) {
                final day = days[idx];
                final isSelected = day == _selectedScheduleDay;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(day),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedScheduleDay = day;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Schedule List
          Expanded(
            child: Builder(
              builder: (context) {
                if (filteredSchedules.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 48, color: AppColors.outline),
                        SizedBox(height: 12),
                        Text('Tidak ada jadwal mengajar', style: TextStyle(color: AppColors.outline)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 160),
                  itemCount: filteredSchedules.length,
                  itemBuilder: (context, idx) {
                    final item = filteredSchedules[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: _buildScheduleItem(
                        '${item['timeStart']} - ${item['timeEnd']}',
                        item['class']!,
                        item['subject']!,
                        item['room']!,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // TAB 5: INFO
  Widget _buildInfoTab() {
    final now = DateTime.now();
    final listAnn = globalStateInstance.announcements.where((a) {
      // 1. Target Filter (semua or guru)
      final target = a['target']?.toString().toLowerCase() ?? '';
      bool isTargeted = target == 'semua' || target == 'guru';
      
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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi & Pengumuman',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onBackground),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: listAnn.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.campaign_outlined, size: 48, color: AppColors.outline),
                        SizedBox(height: 12),
                        Text('Belum ada pengumuman', style: TextStyle(color: AppColors.outline)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 160),
                    itemCount: listAnn.length,
                    itemBuilder: (context, idx) {
                      final ann = listAnn[idx];
                      final isPinned = ann['isPinned'] == true;
                      final target = ann['target']?.toString().toUpperCase() ?? 'SEMUA';

                      return Card(
                        color: isPinned ? AppColors.secondaryFixedDim.withOpacity(0.2) : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isPinned ? AppColors.primary.withOpacity(0.3) : Colors.grey.shade100,
                            width: 1,
                          ),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Target: $target',
                                      style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (isPinned) ...[
                                    const Icon(Icons.push_pin, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    const Text('PINNED', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                ann['title'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isPinned ? AppColors.primary : AppColors.onBackground,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ExpandableText(
                                text: ann['body'] as String,
                                maxLines: 4,
                                style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                              ),
                              if (ann['date'] != null && ann['date'].toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  ann['date'] as String,
                                  style: const TextStyle(fontSize: 10, color: AppColors.outline),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
