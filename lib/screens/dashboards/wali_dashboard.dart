import 'dart:ui';
import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../login_screen.dart';
import 'admin_dashboard.dart';
import '../../widgets/suntri_header.dart';
import '../../services/update_checker.dart';

class WaliDashboard extends StatefulWidget {
  const WaliDashboard({super.key});

  @override
  State<WaliDashboard> createState() => _WaliDashboardState();
}

class _WaliDashboardState extends State<WaliDashboard> {
  int _currentIndex = 0;
  String? _selectedChildId;

  // Perizinan form state
  final _permFormKey = GlobalKey<FormState>();
  String _permType = 'Sakit';
  final _permStartController = TextEditingController();
  final _permEndController = TextEditingController();
  final _permReasonController = TextEditingController();
  final _permContactController = TextEditingController();

  // Chat tab state
  String? _activeChatContact; // 'musyrif', 'walikelas', 'admin'
  final _chatTextController = TextEditingController();
  final _chatScrollController = ScrollController();
  final List<Map<String, dynamic>> _chatSessions = [
    {
      'id': 'musyrif',
      'name': 'Ust. Ahmad Fauzi',
      'role': 'Musyrif Halaqoh',
      'avatar': 'AF',
      'lastMsg': 'Wa\'alaikumsalam, perkembangan hafalan ananda sangat baik...',
      'unread': 1,
      'messages': [
        {'sender': 'other', 'text': 'Assalamualaikum Ayah/Bunda.', 'time': '08:30'},
        {'sender': 'wali', 'text': 'Wa\'alaikumsalam Ustadz, bagaimana hafalan anak saya hari ini?', 'time': '09:00'},
        {'sender': 'other', 'text': 'Wa\'alaikumsalam, perkembangan hafalan ananda sangat baik.', 'time': '09:05'},
      ]
    },
    {
      'id': 'admin',
      'name': 'Layanan Admin Suntri',
      'role': 'Admin Keuangan & Umum',
      'avatar': 'AD',
      'lastMsg': 'Baik bunda, pembayaran SPP sudah kami verifikasi.',
      'unread': 0,
      'messages': [
        {'sender': 'wali', 'text': 'Saya sudah transfer untuk tagihan SPP.', 'time': '2 hari lalu'},
        {'sender': 'other', 'text': 'Baik bunda, pembayaran SPP sudah kami verifikasi. Terima kasih.', 'time': '2 hari lalu'},
      ]
    }
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateChecker.checkForUpdate(context);
    });
  }

  @override
  void dispose() {
    _permStartController.dispose();
    _permEndController.dispose();
    _permReasonController.dispose();
    _permContactController.dispose();
    _chatTextController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globalStateInstance,
      builder: (context, child) {
        // 1. Identify current user (Wali)
        final currentUser = globalStateInstance.currentUser;
        final waliName = currentUser != null ? currentUser['name'] ?? 'Wali Santri' : 'Wali Santri';
        final initials = waliName.isNotEmpty ? waliName.trim().split(' ').take(2).map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').join() : 'WS';

        // 2. Identify associated Santri List
        List<Map<String, dynamic>> wsLink = [];
        if (currentUser != null) {
          wsLink = globalStateInstance.waliSantri.where((w) => w['userId'] == currentUser['id'].toString()).toList();
        }

        if (wsLink.isNotEmpty && _selectedChildId == null) {
          // Initialize with first child
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedChildId = wsLink.first['santriId'];
              });
            }
          });
        }
        
        final String? santriId = _selectedChildId ?? (wsLink.isNotEmpty ? wsLink.first['santriId'] : null);

        final std = globalStateInstance.students.firstWhere(
          (s) => s['id'] == santriId,
          orElse: () => globalStateInstance.students.isNotEmpty
              ? globalStateInstance.students.first
              : {
                  'id': 'empty',
                  'name': 'Belum Ada Santri',
                  'nis': '-',
                  'class': '-',
                  'parent': '-',
                  'juz': 0,
                  'avatar': null,
                  'initials': '?',
                  'attendance': {'hadir': 0, 'sakit': 0, 'izin': 0, 'alpha': 0},
                },
        );

        final listBills = globalStateInstance.bills.where((b) => b['santriId'] == std['id']).toList();
        final listPerms = globalStateInstance.permissions.where((p) => p['santriId'] == std['id']).toList();

        return Scaffold(
          extendBody: true, // Required for the body to flow under the transparent navbar
          backgroundColor: AppColors.background,
          appBar: SUNTRIHeader(
            title: "Ma'had Tahfidz Rijaalul Quran",
            subtitle: 'Bapak/Ibu $waliName • Wali Santri',
            initials: initials,
            onLogout: () async {
              await globalStateInstance.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
          body: Column(
            children: [
              // CHILD SWITCHER (Multi-Santri)
              if (wsLink.length > 1)
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: wsLink.map((w) {
                        final sId = w['santriId'];
                        final sObj = globalStateInstance.students.firstWhere((s) => s['id'] == sId, orElse: () => {'name': 'Unknown'});
                        final isSelected = sId == santriId;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(sObj['name'].toString().split(' ').take(2).join(' ')),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              if (selected) {
                                setState(() {
                                  _selectedChildId = sId;
                                });
                              }
                            },
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            backgroundColor: Colors.grey.shade100,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await globalStateInstance.syncFromDatabase();
                    setState(() {});
                  },
                  color: AppColors.primary,
                  child: IndexedStack(
                    index: _currentIndex,
                    children: [
                      _buildDashboardTab(std, listBills, listPerms),
                      _buildProgresTab(std),
                      _buildKeuanganTab(std, listBills),
                      _buildPerizinanTab(std, listPerms),
                      _buildChatTab(std),
                    ],
                  ),
                ),
              ),
            ],
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
                      currentIndex: _currentIndex,
                      onTap: (index) {
                        setState(() {
                          _currentIndex = index;
                          // Clear chat contact selection when switching tabs
                          if (index != 4) {
                            _activeChatContact = null;
                          }
                        });
                      },
                      type: BottomNavigationBarType.fixed,
                      backgroundColor: Colors.transparent, // Transparent to show glass effect
                      elevation: 0, // Remove shadow
                      selectedFontSize: 11,
                      unselectedFontSize: 11,
                      iconSize: 22,
                      selectedItemColor: AppColors.primary,
                      unselectedItemColor: Colors.grey.shade400,
                      items: const [
                        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Beranda'),
                        BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Progres'),
                        BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Keuangan'),
                        BottomNavigationBarItem(icon: Icon(Icons.assignment_turned_in_outlined), activeIcon: Icon(Icons.assignment_turned_in), label: 'Izin'),
                        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Chat'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== TAB 0: DASHBOARD TAB ====================
  Widget _buildDashboardTab(Map<String, dynamic> std, List<Map<String, dynamic>> bills, List<Map<String, dynamic>> perms) {
    // Filter unpaid bills
    final unpaidBills = bills.where((b) => b['status'].toString().toLowerCase() != 'lunas').toList();
    final totalUnpaid = unpaidBills.fold<double>(0.0, (sum, b) {
      final rawAmount = b['amount'].toString();
      final parsed = double.tryParse(rawAmount) ?? 0.0;
      return sum + parsed;
    });

    // Filter notifications related to this child
    final studentActivities = globalStateInstance.activities
        .where((act) => act['description'].toString().toLowerCase().contains(std['name'].toLowerCase()))
        .toList();

    // Determine current day for Schedule
    final days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final currentDay = days[DateTime.now().weekday % 7];
    
    // Filter Schedules by Day and Class
    final todaySchedules = globalStateInstance.schedules
        .where((s) => s['day'] == currentDay && s['class'] == std['class'])
        .toList()
      ..sort((a, b) => (a['timeStart'] as String).compareTo(b['timeStart'] as String));

    // Determine today's attendance status (Mock logic based on Permissions, could be derived from Kehadiran table)
    // If there is an active permission spanning today, use that. Otherwise 'Hadir'.
    String todayAttendance = 'Hadir di Pesantren';
    Color attColor = Colors.green;
    IconData attIcon = Icons.check_circle;
    
    final now = DateTime.now();
    for (var p in perms) {
      if (p['status'] == 'approved') {
        try {
          final start = DateTime.parse(p['startDate']);
          final end = DateTime.parse(p['endDate']).add(const Duration(days: 1)); // inclusive end
          if (now.isAfter(start) && now.isBefore(end)) {
            todayAttendance = p['type'] == 'Sakit' ? 'Izin Sakit' : 'Sedang Izin';
            attColor = p['type'] == 'Sakit' ? Colors.orange : Colors.blue;
            attIcon = p['type'] == 'Sakit' ? Icons.sick : Icons.card_travel;
            break;
          }
        } catch (_) {}
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SANTRI PROFILE CARD (PREMIUM)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.05),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                )
              ],
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      std['name'].toString().substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        std['name'],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Kelas ${std['class']}',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: attColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(attIcon, size: 12, color: attColor),
                                const SizedBox(width: 4),
                                Text(
                                  todayAttendance,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: attColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // TAHFIZH & KEUANGAN SUMMARY (SIDE BY SIDE)
          Row(
            children: [
              // Tahfizh Card
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = 1),
                  child: Container(
                    height: 130,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF004D40), Color(0xFF00796B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF004D40).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.menu_book, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(child: Text('TAHFIZH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF81C784), letterSpacing: 1.0))),
                          ],
                        ),
                        const Spacer(),
                        Text('Juz ${std['juz']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 2),
                        const Text('Cek progres', style: TextStyle(fontSize: 10, color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Keuangan Card
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = 2),
                  child: Container(
                    height: 130,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: totalUnpaid > 0
                          ? const LinearGradient(colors: [Color(0xFFD32F2F), Color(0xFFE53935)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                          : const LinearGradient(colors: [Color(0xFF388E3C), Color(0xFF4CAF50)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (totalUnpaid > 0 ? const Color(0xFFD32F2F) : const Color(0xFF388E3C)).withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                              child: Icon(totalUnpaid > 0 ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text('KEUANGAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9), letterSpacing: 1.0))),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          totalUnpaid > 0 ? 'Rp ${totalUnpaid.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}' : 'Lunas',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(totalUnpaid > 0 ? 'Tunggakan' : 'Tagihan selesai', style: const TextStyle(fontSize: 10, color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // JADWAL HARI INI
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Jadwal Hari Ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onBackground)),
              TextButton(
                onPressed: () => _showWeeklySchedule(context, std),
                child: const Text('Jadwal Lengkap', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          todaySchedules.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
                  child: Column(
                    children: [
                      Icon(Icons.event_busy, color: Colors.grey.shade300, size: 40),
                      const SizedBox(height: 12),
                      Text('Tidak ada jadwal akademik hari ini ($currentDay)', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: todaySchedules.length,
                  itemBuilder: (context, idx) {
                    final s = todaySchedules[idx];
                    return _buildJadwalRow('${s['timeStart']} - ${s['timeEnd']}', s['subject'], Icons.class_outlined, AppColors.primary);
                  },
                ),
          const SizedBox(height: 24),

          // FEED NOTIFIKASI AKTIVITAS
          const Text('Aktivitas Terkini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onBackground)),
          const SizedBox(height: 12),
          studentActivities.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
                  child: Center(
                    child: Text('Belum ada riwayat aktivitas terbaru.', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: studentActivities.take(3).length,
                  itemBuilder: (context, idx) {
                    final act = studentActivities[idx];
                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade100, width: 1),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: act['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.notifications_active, color: act['color'], size: 20),
                        ),
                        title: Text(act['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(act['description'], style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                            const SizedBox(height: 6),
                            Text(act['time'], style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildJadwalRow(String time, String title, IconData icon, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.1),
            radius: 18,
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(time, style: const TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showWeeklySchedule(BuildContext context, Map<String, dynamic> std) {
    // Filter and group schedules by day
    final classSchedule = globalStateInstance.schedules
        .where((s) => s['class'] == std['class'])
        .toList();
        
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var s in classSchedule) {
      final day = s['day'] as String;
      grouped.putIfAbsent(day, () => []).add(s);
    }
    
    final daysOrder = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final sortedDays = grouped.keys.toList()
      ..sort((a, b) => daysOrder.indexOf(a).compareTo(daysOrder.indexOf(b)));

    for (var day in sortedDays) {
      grouped[day]!.sort((a, b) => (a['timeStart'] as String).compareTo(b['timeStart'] as String));
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Jadwal Pembelajaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              Expanded(
                child: sortedDays.isEmpty
                    ? Center(
                        child: Text(
                          'Belum ada jadwal akademik.',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      )
                    : ListView.builder(
                        itemCount: sortedDays.length,
                        itemBuilder: (context, index) {
                          final day = sortedDays[index];
                          final daySchedules = grouped[day]!;
                          final tasks = daySchedules.map((s) => 
                            '${s['timeStart'].toString().substring(0, 5)} - ${s['timeEnd'].toString().substring(0, 5)} : ${s['subject']}'
                          ).toList();
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildDaySchedule(day, tasks),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDaySchedule(String day, List<String> tasks) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(day, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
            const SizedBox(height: 6),
            ...tasks.map((t) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(t, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
            )),
          ],
        ),
      ),
    );
  }

  // ==================== TAB 1: PROGRES TAB ====================
  Widget _buildProgresTab(Map<String, dynamic> std) {
    double percentage = (std['juz'] / 30.0).clamp(0.0, 1.0);
    
    // Filter setorans
    final studentSetorans = globalStateInstance.setorans
        .where((s) => s['santriId'] == std['id'])
        .toList()
      ..sort((a, b) => (b['id'] as String).compareTo(a['id'] as String)); // sort latest

    // Extract Attendance
    final att = std['attendance'] as Map<String, dynamic>? ?? {'hadir': 0, 'sakit': 0, 'izin': 0, 'alpha': 0};
    final hadir = att['hadir'] as int? ?? 0;
    final sakit = att['sakit'] as int? ?? 0;
    final izin = att['izin'] as int? ?? 0;
    final alpha = att['alpha'] as int? ?? 0;
    final total = hadir + sakit + izin + alpha;
    
    final attPercentage = total > 0 ? (hadir / total) * 100 : 100.0;
    
    // Academic Grades
    final studentGrades = globalStateInstance.grades.where((g) => g['studentName'] == std['name']).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // PROGRESS LINGKARAN ANIMASI (PREMIUM)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 24, offset: const Offset(0, 8))],
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                const Text('Pencapaian Target Hafalan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.onBackground)),
                const SizedBox(height: 24),
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: CircularProgressIndicator(
                          value: percentage,
                          strokeWidth: 14,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(percentage * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${std['juz']} / 30 Juz',
                            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Tetap semangat mengawal hafalan ananda di rumah.', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // NILAI AKADEMIK (SEKOLAH FORMAL)
          const Text('Nilai Akademik (Sekolah Formal)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onBackground)),
          const SizedBox(height: 12),
          studentGrades.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
                  child: Center(
                    child: Text('Belum ada nilai akademik yang diinputkan.', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: studentGrades.length,
                  itemBuilder: (context, idx) {
                    final g = studentGrades[idx];
                    final double score = g['finalScore'] != null ? double.tryParse(g['finalScore'].toString()) ?? 0.0 : 0.0;
                    final isGood = score >= 75.0;
                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade100, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(g['subject'] ?? 'Pelajaran', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isGood ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    score.toStringAsFixed(1),
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isGood ? Colors.green : Colors.red),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildGradeDetail('Tugas', g['tugas']),
                                _buildGradeDetail('UH', g['uh']),
                                _buildGradeDetail('UTS', g['uts']),
                                _buildGradeDetail('UAS', g['uas']),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
          const SizedBox(height: 24),

          // STATISTIK KEHADIRAN (Real Data)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 16, offset: const Offset(0, 4))],
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Statistik Kehadiran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.onBackground)),
                    Text('${attPercentage.toStringAsFixed(0)}% Hadir', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAttendanceStat('Hadir', hadir, Colors.green),
                    _buildAttendanceStat('Sakit', sakit, Colors.orange),
                    _buildAttendanceStat('Izin', izin, Colors.blue),
                    _buildAttendanceStat('Alpha', alpha, Colors.red),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // HEATMAP KEHADIRAN (Bulan Ini)
          const Text('Aktivitas Kehadiran (Bulan Ini)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onBackground)),
          const SizedBox(height: 12),
          _buildHeatmapGrid(hadir, sakit + izin, alpha),
          const SizedBox(height: 28),

          // RIWAYAT SETORAN TAHFIZH
          const Text('Riwayat Setoran Tahfizh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onBackground)),
          const SizedBox(height: 12),
          studentSetorans.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
                  child: Column(
                    children: [
                      Icon(Icons.history_toggle_off, color: Colors.grey.shade300, size: 40),
                      const SizedBox(height: 12),
                      Text('Belum ada riwayat setoran tahfizh.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: studentSetorans.length,
                  itemBuilder: (context, idx) {
                    final setoran = studentSetorans[idx];
                    final isZiyadah = setoran['type'] == 'Ziyadah';
                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade100),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: (isZiyadah ? Colors.green : Colors.blue).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Icon(isZiyadah ? Icons.add_circle_outline : Icons.replay, color: isZiyadah ? Colors.green.shade700 : Colors.blue.shade700, size: 20),
                                  const SizedBox(height: 4),
                                  Text(
                                    setoran['type'],
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isZiyadah ? Colors.green.shade800 : Colors.blue.shade800),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'QS. ${setoran['surah']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.onBackground),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Ayat ${setoran['ayatDari']} - ${setoran['ayatSampai']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _buildSetoranBadge('Lancar: ${setoran['kelancaran']}', setoran['kelancaran'] == 'Sangat Baik' ? Colors.green : Colors.orange),
                                      const SizedBox(width: 8),
                                      _buildSetoranBadge('Tajwid: ${setoran['tajwid']}', Colors.blue),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  setoran['date'],
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
                                ),
                                if (setoran['time'] != '')
                                  Text(
                                    setoran['time'],
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSetoranBadge(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color.shade800)),
    );
  }

  Widget _buildAttendanceStat(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(count.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildHeatmapGrid(int hadir, int izinSakit, int alpha) {
    // Generate dates for the current month
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final List<DateTime> monthDays = List.generate(daysInMonth, (index) => DateTime(now.year, now.month, index + 1));

    List<int> statuses = List.filled(daysInMonth, 5); // 5 = Future

    int workingDaysPassed = 0;
    for (int i = 0; i < now.day; i++) {
      if (monthDays[i].weekday == DateTime.sunday) {
        statuses[i] = 6; // 6 = Libur (Minggu)
      } else {
        statuses[i] = 4; // 4 = Past Unrecorded
        workingDaysPassed++;
      }
    }
    
    List<int> pastStatusesPool = [];
    for (int i = 0; i < hadir; i++) {
      pastStatusesPool.add(3); // Hadir
    }
    for (int i = 0; i < izinSakit; i++) {
      pastStatusesPool.add(1); // Izin/Sakit
    }
    for (int i = 0; i < alpha; i++) {
      pastStatusesPool.add(0); // Alpha
    }

    if (pastStatusesPool.length > workingDaysPassed) {
      pastStatusesPool = pastStatusesPool.sublist(0, workingDaysPassed);
    }
    
    // Pad the pool with 4s up to workingDaysPassed
    while (pastStatusesPool.length < workingDaysPassed) {
      pastStatusesPool.add(4);
    }
    
    pastStatusesPool.shuffle();

    // Fill the pool back into the statuses array
    int poolIndex = 0;
    for (int i = 0; i < now.day; i++) {
      if (statuses[i] == 4) {
        statuses[i] = pastStatusesPool[poolIndex];
        poolIndex++;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, idx) {
              final date = monthDays[idx];
              final val = statuses[idx];
              
              Color cellColor = Colors.grey.shade50; // Unrecorded (4)
              Color textColor = Colors.grey.shade400;
              Color borderColor = Colors.grey.shade200;

              if (val == 3) {
                cellColor = Colors.green.shade500;
                textColor = Colors.white;
                borderColor = Colors.green.shade600;
              } else if (val == 1) {
                cellColor = Colors.orange.shade400;
                textColor = Colors.white;
                borderColor = Colors.orange.shade500;
              } else if (val == 0) {
                cellColor = Colors.red.shade400;
                textColor = Colors.white;
                borderColor = Colors.red.shade500;
              } else if (val == 5) {
                cellColor = Colors.grey.shade100; // Future
                textColor = Colors.grey.shade400;
                borderColor = Colors.transparent;
              } else if (val == 6) {
                cellColor = Colors.red.shade50; // Libur (Minggu)
                textColor = Colors.red.shade400;
                borderColor = Colors.red.shade200;
              }

              return Container(
                decoration: BoxDecoration(
                  color: cellColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderColor, width: 0.5),
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: val == 4 ? FontWeight.normal : FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendCell(Colors.green.shade500),
              const Text(' Hadir', style: TextStyle(fontSize: 10, color: Colors.grey)),
              const SizedBox(width: 12),
              _buildLegendCell(Colors.orange.shade400),
              const Text(' Izin/Sakit', style: TextStyle(fontSize: 10, color: Colors.grey)),
              const SizedBox(width: 12),
              _buildLegendCell(Colors.red.shade400),
              const Text(' Alpha', style: TextStyle(fontSize: 10, color: Colors.grey)),
              const SizedBox(width: 12),
              _buildLegendCell(Colors.red.shade50),
              const Text(' Libur', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildGradeDetail(String label, dynamic value) {
    final v = value != null ? double.tryParse(value.toString()) ?? 0.0 : 0.0;
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(v.toStringAsFixed(0), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLegendCell(Color color) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // ==================== TAB 2: KEUANGAN TAB ====================
  Widget _buildKeuanganTab(Map<String, dynamic> std, List<Map<String, dynamic>> bills) {
    final unpaidBills = bills.where((b) => b['status'].toString().toLowerCase() != 'lunas').toList();
    final paidBills = bills.where((b) => b['status'].toString().toLowerCase() == 'lunas').toList();
    final totalUnpaid = unpaidBills.fold<double>(0.0, (sum, b) {
      final rawAmount = b['amount'].toString();
      final parsed = double.tryParse(rawAmount) ?? 0.0;
      return sum + parsed;
    });

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // TUNGGAKAN HERO CARD
          Card(
            color: totalUnpaid > 0 ? const Color(0xFFBA1A1A) : const Color(0xFF004D40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      totalUnpaid > 0 ? 'TOTAL TUNGGAKAN AKTIF' : 'STATUS PEMBAYARAN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: totalUnpaid > 0 ? const Color(0xFFFFDAD6) : const Color(0xFF81C784),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rp ${totalUnpaid.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      totalUnpaid > 0
                          ? 'Mohon segera lunasi pembayaran SPP & Biaya pembangunan ananda.'
                          : 'Terima kasih, semua kewajiban administrasi telah lunas.',
                      style: TextStyle(
                        fontSize: 11,
                        color: totalUnpaid > 0 ? const Color(0xFFFFDAD6) : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // UNPAID BILLS
          const Text('Tagihan Belum Bayar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.onBackground)),
          const SizedBox(height: 8),
          unpaidBills.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('Tidak ada tagihan tertunda.', style: TextStyle(color: Colors.grey, fontSize: 12))),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: unpaidBills.length,
                  itemBuilder: (context, idx) {
                    final bill = unpaidBills[idx];
                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade100),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(bill['type'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text(bill['period'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Text('Rp ${(double.tryParse(bill['amount'].toString()) ?? 0).toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red)),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              icon: const Icon(Icons.payment, size: 14),
                              label: const Text('Bayar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                _triggerPaymentGateway(bill);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          const SizedBox(height: 20),

          // PAID BILLS
          const Text('Riwayat Lunas', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.onBackground)),
          const SizedBox(height: 8),
          paidBills.isEmpty
              ? const Text('Belum ada riwayat pembayaran.', style: TextStyle(color: Colors.grey, fontSize: 12))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: paidBills.length,
                  itemBuilder: (context, idx) {
                    final bill = paidBills[idx];
                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade100),
                      ),
                      child: ListTile(
                        title: Text(bill['type'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(bill['period'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Rp ${(double.tryParse(bill['amount'].toString()) ?? 0).toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.receipt_long, color: AppColors.primary, size: 18),
                              onPressed: () {
                                _showInvoiceDialog(context, bill);
                              },
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _triggerPaymentGateway(Map<String, dynamic> bill) {
    final parsedAmount = double.tryParse(bill['amount'].toString()) ?? 0.0;
    final formattedAmount = parsedAmount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    
    final nav = Navigator.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        String selectedMethod = 'Virtual Account BSI';
        return StatefulBuilder(
          builder: (builderContext, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 40, height: 4, decoration: const BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.all(Radius.circular(4)))),
                  ),
                  const SizedBox(height: 24),
                  const Text('Instruksi Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onBackground)),
                  const SizedBox(height: 4),
                  Text('Selesaikan pembayaran untuk tagihan ${bill['type']}.', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Tagihan', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text('Rp $formattedAmount', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Transfer ke Rekening Berikut', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(16)),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.account_balance, color: AppColors.primary, size: 24),
                            SizedBox(width: 12),
                            Text('BSI (Bank Syariah Indonesia)', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SizedBox(height: 16),
                        Text('No. Rekening', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('7123 4567 8910', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        SizedBox(height: 8),
                        Text('a.n. Pesantren Rijaalul Quran', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Harap transfer tepat sesuai nominal tagihan. Setelah transfer selesai, silakan klik tombol di bawah ini untuk mengonfirmasi ke Admin.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: const Text('Saya Sudah Transfer (Konfirmasi)', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        nav.pop(); // Close Modal
                        // Simulate loading delay
                        showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator(color: AppColors.primary)));
                        await Future.delayed(const Duration(seconds: 2));
                        if (!mounted) return;
                        nav.pop(); // Close Loading

                        // Execute Payment via globalStateInstance
                        await globalStateInstance.payBill(
                          billId: bill['id'].toString(),
                          nominal: parsedAmount,
                          method: selectedMethod,
                          notes: 'Dibayar via Gateway ($selectedMethod)',
                          date: DateTime.now().toString().split(' ')[0],
                        );

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Pembayaran Rp $formattedAmount via $selectedMethod Berhasil!'), backgroundColor: Colors.green),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMethodTile(String title, IconData icon, String selectedMethod, Function(String) onSelect) {
    final isSelected = title == selectedMethod;
    return GestureDetector(
      onTap: () => onSelect(title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey, size: 24),
            const SizedBox(width: 16),
            Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? AppColors.primary : Colors.black87)),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  void _showInvoiceDialog(BuildContext context, Map<String, dynamic> bill) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Kwitansi Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                    Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),
                _buildInvoiceRow('Tipe Tagihan', bill['type']),
                _buildInvoiceRow('Periode', bill['period']),
                _buildInvoiceRow('Santri', bill['studentName']),
                _buildInvoiceRow('Jumlah', 'Rp ${bill['amount']}'),
                _buildInvoiceRow('Status', 'Lunas / Paid'),
                _buildInvoiceRow('No. Invoice', 'INV/RQ/${DateTime.now().year}/${DateTime.now().millisecond}'),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInvoiceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ==================== TAB 3: PERIZINAN TAB ====================
  Widget _buildPerizinanTab(Map<String, dynamic> std, List<Map<String, dynamic>> perms) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // FORM PENGAJUAN IZIN
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _permFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Form Pengajuan Izin Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                    const SizedBox(height: 12),
                    
                    // Tipe Izin
                    DropdownButtonFormField<String>(
                      value: _permType,
                      decoration: InputDecoration(
                        labelText: 'Tipe Izin',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['Sakit', 'Pulang', 'Keluar', 'Liburan'].map((t) {
                        return DropdownMenuItem<String>(
                          value: t,
                          child: Text(t),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _permType = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Tanggal Mulai & Tanggal Selesai
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _permStartController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Mulai',
                              suffixIcon: const Icon(Icons.calendar_today, size: 16),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onTap: () => _selectDate(context, _permStartController),
                            validator: (val) => val == null || val.isEmpty ? 'Isi tgl mulai' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _permEndController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Selesai',
                              suffixIcon: const Icon(Icons.calendar_today, size: 16),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onTap: () => _selectDate(context, _permEndController),
                            validator: (val) => val == null || val.isEmpty ? 'Isi tgl selesai' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Alasan Izin
                    TextFormField(
                      controller: _permReasonController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Alasan Perizinan',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Isi alasan perizinan' : null,
                    ),
                    const SizedBox(height: 12),

                    // Kontak Wali
                    TextFormField(
                      controller: _permContactController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'No. HP / Kontak Wali',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Isi kontak wali' : null,
                    ),
                    const SizedBox(height: 16),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          if (_permFormKey.currentState!.validate()) {
                            // Add pending permission
                            globalStateInstance.addPermission({
                              'id': 'perm_${DateTime.now().millisecondsSinceEpoch}',
                              'studentName': std['name'],
                              'type': _permType,
                              'dateStart': _permStartController.text,
                              'dateEnd': _permEndController.text,
                              'durationDays': 1,
                              'reason': _permReasonController.text,
                              'contact': _permContactController.text,
                              'status': 'Ditinjau',
                            });

                            // Reset fields
                            _permStartController.clear();
                            _permEndController.clear();
                            _permReasonController.clear();
                            _permContactController.clear();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Pengajuan izin berhasil direkam dengan status "Ditinjau" (Pending)'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                        },
                        child: const Text('Ajukan Perizinan', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // DAFTAR RIWAYAT PERIZINAN
          const Text('Riwayat Pengajuan Izin', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.onBackground)),
          const SizedBox(height: 8),
          perms.isEmpty
              ? const Text('Belum ada riwayat perizinan.', style: TextStyle(color: Colors.grey, fontSize: 12))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: perms.length,
                  itemBuilder: (context, idx) {
                    final perm = perms[idx];
                    Color statColor = Colors.orange;
                    if (perm['status'] == 'Disetujui') statColor = Colors.green;
                    if (perm['status'] == 'Ditolak') statColor = Colors.red;

                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade100),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Izin ${perm['type']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 2),
                                  Text('Tgl: ${perm['dateStart']} s/d ${perm['dateEnd']}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Text('Alasan: ${perm['reason']}', style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                perm['status'] == 'Ditinjau' ? 'Pending' : perm['status'],
                                style: TextStyle(color: statColor, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 100),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  // ==================== TAB 4: CHAT TAB ====================
  Widget _buildChatTab(Map<String, dynamic> std) {
    // Determine Musyrif details
    String teacherName = 'Ust. Musyrif';
    String musyrifAvatar = 'MS';
    for (var h in globalStateInstance.halaqohs) {
      if (h['name'] == std['halaqoh']) {
        teacherName = h['teacher'] ?? 'Ust. Musyrif';
        break;
      }
    }
    final mName = teacherName.replaceAll('Ust. ', '').replaceAll('Ustadz ', '');
    if (mName.isNotEmpty) {
      musyrifAvatar = mName.split(' ').take(2).map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').join();
    }

    // Determine Admin details
    String adminName = 'Layanan Admin Suntri';
    String adminId = '1';
    try {
      final adminUser = globalStateInstance.appUsers.firstWhere((u) => u['role'] == 'Admin');
      adminId = adminUser['id'];
      adminName = adminUser['name'] ?? adminName;
    } catch (_) {}

    // Find real chat rooms from globalState
    final waliId = globalStateInstance.currentUser?['id']?.toString() ?? '';
    final santriId = std['id'].toString();
    final musyrifId = std['musyrif_id'].toString();

    // Admin Room
    final adminRoom = globalStateInstance.chats.firstWhere(
      (c) => c['targetId'] == adminId,
      orElse: () => {},
    );

    // Musyrif Room
    final musyrifRoom = globalStateInstance.chats.firstWhere(
      (c) => c['targetId'] == musyrifId,
      orElse: () => {},
    );

    // Build session data
    List<Map<String, dynamic>> sessions = [];
    
    // Musyrif Session
    List musyrifMessages = musyrifRoom.isNotEmpty ? musyrifRoom['messages'] : [];
    int musyrifUnread = musyrifMessages.where((m) => m['senderId'] != waliId && m['isRead'] == false).length;
    sessions.add({
      'id': 'musyrif',
      'roomId': musyrifRoom['id'],
      'targetId': musyrifId,
      'name': teacherName,
      'role': 'Musyrif ${std['halaqoh']}',
      'avatar': musyrifAvatar,
      'lastMsg': musyrifMessages.isNotEmpty ? musyrifMessages.last['text'] : 'Belum ada pesan',
      'unread': musyrifUnread,
      'messages': musyrifMessages,
    });

    // Admin Session
    List adminMessages = adminRoom.isNotEmpty ? adminRoom['messages'] : [];
    int adminUnread = adminMessages.where((m) => m['senderId'] != waliId && m['isRead'] == false).length;
    sessions.add({
      'id': 'admin',
      'roomId': adminRoom['id'],
      'targetId': adminId,
      'name': adminName,
      'role': 'Admin Keuangan & Umum',
      'avatar': 'AD',
      'lastMsg': adminMessages.isNotEmpty ? adminMessages.last['text'] : 'Belum ada pesan',
      'unread': adminUnread,
      'messages': adminMessages,
    });

    if (_activeChatContact != null) {
      final session = sessions.firstWhere((s) => s['id'] == _activeChatContact);
      final messages = session['messages'] as List;

      return Column(
        children: [
          // Chat screen header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                  onPressed: () {
                    setState(() {
                      _activeChatContact = null;
                    });
                  },
                ),
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(session['avatar'], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(session['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(session['role'], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _chatScrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, idx) {
                final msg = messages[idx];
                final isMe = msg['senderId'] == waliId;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary : Colors.grey.shade200,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
                        bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
                      ),
                    ),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['text'] ?? '',
                          style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            msg['time'] ?? '',
                            style: TextStyle(color: isMe ? Colors.white60 : Colors.black45, fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Input field
          Container(
            padding: const EdgeInsets.only(left: 12, top: 12, right: 12, bottom: 140),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatTextController,
                    decoration: InputDecoration(
                      hintText: 'Ketik pesan...',
                      hintStyle: const TextStyle(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: () async {
                      final text = _chatTextController.text.trim();
                      if (text.isNotEmpty) {
                        _chatTextController.clear();
                        
                        String roomId = session['roomId']?.toString() ?? '';
                        if (roomId.isEmpty) {
                          // Room doesn't exist yet, create it
                          final newRoom = await globalStateInstance.getOrCreateChatRoom(santriId, session['targetId']);
                          if (newRoom.isNotEmpty) {
                            roomId = newRoom['id'].toString();
                          }
                        }

                        if (roomId.isNotEmpty) {
                          globalStateInstance.sendChatMessage(roomId, text);
                          _scrollToBottom();
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Contact List View
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hubungi Layanan & Ustadz', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.onBackground)),
          const SizedBox(height: 4),
          const Text('Kirim pesan real-time ke wali kelas, musyrif halaqoh, atau admin.', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (context, idx) {
                final session = sessions[idx];
                final hasUnread = session['unread'] > 0;
                return Card(
                  elevation: 0,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade100),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(session['avatar'], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(session['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(
                          session['role'],
                          style: const TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      session['lastMsg'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal),
                    ),
                    trailing: hasUnread
                        ? Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: Text(
                              '${session['unread']}',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          )
                        : const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                    onTap: () {
                      setState(() {
                        _activeChatContact = session['id'];
                      });
                      _scrollToBottom();
                    },
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

// Custom Painter for Radar Akhlak Chart
class RadarAkhlakPainter extends CustomPainter {
  final double sidiq;
  final double amanah;
  final double tabligh;
  final double fathonah;

  RadarAkhlakPainter({
    required this.sidiq,
    required this.amanah,
    required this.tabligh,
    required this.fathonah,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final maxRadius = size.width / 2 * 0.8;

    final paintGrid = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final paintFill = Paint()
      ..color = const Color(0xFF004D40).withOpacity(0.18)
      ..style = PaintingStyle.fill;

    final paintStroke = Paint()
      ..color = const Color(0xFF004D40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Concentric diamond grid rings (3 levels: 33%, 66%, 100%)
    for (var i = 1; i <= 3; i++) {
      final r = maxRadius * (i / 3);
      final gridPath = Path()
        ..moveTo(centerX, centerY - r)
        ..lineTo(centerX + r, centerY)
        ..lineTo(centerX, centerY + r)
        ..lineTo(centerX - r, centerY)
        ..close();
      canvas.drawPath(gridPath, paintGrid);
    }

    // Grid lines connecting axes
    canvas.drawLine(Offset(centerX, centerY - maxRadius), Offset(centerX, centerY + maxRadius), paintGrid);
    canvas.drawLine(Offset(centerX - maxRadius, centerY), Offset(centerX + maxRadius, centerY), paintGrid);

    // Draw Radar values polygon
    final radarPath = Path()
      ..moveTo(centerX, centerY - maxRadius * sidiq)
      ..lineTo(centerX + maxRadius * amanah, centerY)
      ..lineTo(centerX, centerY + maxRadius * tabligh)
      ..lineTo(centerX - maxRadius * fathonah, centerY)
      ..close();

    canvas.drawPath(radarPath, paintFill);
    canvas.drawPath(radarPath, paintStroke);

    // Grid Labels (Sidiq, Amanah, Tabligh, Fathonah)
    const textStyle = TextStyle(color: Color(0xFF004D40), fontSize: 9, fontWeight: FontWeight.bold);
    
    _drawText(canvas, 'Sidiq', Offset(centerX - 12, centerY - maxRadius - 14), textStyle);
    _drawText(canvas, 'Amanah', Offset(centerX + maxRadius + 6, centerY - 6), textStyle);
    _drawText(canvas, 'Tabligh', Offset(centerX - 16, centerY + maxRadius + 4), textStyle);
    _drawText(canvas, 'Fathonah', Offset(centerX - maxRadius - 52, centerY - 6), textStyle);
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant RadarAkhlakPainter oldDelegate) => true;
}
