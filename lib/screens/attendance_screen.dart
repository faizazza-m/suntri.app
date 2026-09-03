import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AttendanceScreen extends StatefulWidget {
  final bool isTab;
  const AttendanceScreen({super.key, this.isTab = false});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // Student List Data
  final List<Map<String, dynamic>> students = [
    {
      'name': 'Abdullah Azam',
      'nis': '23001',
      'class': 'Kelas 10A',
      'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBMlFL2aGqEuDLuhAKcy90Dq7ho2F-QYDSVZ8oqwZ6Wzv51GvyUlDxtTwfiBT7tgGL-lf8xmNqfbE4HhusW_COYSicJLSsBz2-IY4PTKtZ4IpxfN42_RfLjFBWVFknleONs9SrrXvjXGrydq4gZtEPGjSQJ29FbHbtDXTZPHn_L0MQlVH98xt6iE5Z90F52phmO8DyxMDA_whKe29Lfm2bw8w67Xra7bfw54Es5ysSO7j4_WMoK0gCN',
    },
    {
      'name': 'Bintang Ramadhan',
      'nis': '23002',
      'class': 'Kelas 10A',
      'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDQ7_Qj4aEzPCZg0jpR8ygJtBjTz-KETDm2WwLwuxkQbt-EhyxcqzWfh7CYAIwJoFz5bRcCeRj12zLw7i7FBLa2gckRjrvl42ou_zBYYbBc9cjAbmxQs6F7qv6oO32BrFZBx1Lh_napvdx8WdVHgqMDSk2wHkU17uTA60y0aZ1D9CSjTtaObEz8RY29uLSj2KqyBwnffrCTZVn_VLJgJCHwsj5wrJuP7yKQuSbRL6wIpXRrCwgmpuTE',
    },
    {
      'name': 'Daffa Firdaus',
      'nis': '23003',
      'class': 'Kelas 10A',
      'initials': 'DF',
    },
  ];

  // Attendance state tracker: mapping index -> status ('H', 'S', 'I', 'A')
  late List<String?> attendanceState;

  @override
  void initState() {
    super.initState();
    attendanceState = List<String?>.filled(students.length, null);
  }

  void _setAllHadir() {
    setState(() {
      for (int i = 0; i < attendanceState.length; i++) {
        attendanceState[i] = 'H';
      }
    });
  }

  bool get _isAllFilled => attendanceState.every((status) => status != null);

  void _showConfirmationSheet() {
    int h = 0, s = 0, i = 0, a = 0;
    for (var status in attendanceState) {
      if (status == 'H') h++;
      if (status == 'S') s++;
      if (status == 'I') i++;
      if (status == 'A') a++;
    }

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
              // Grab handle
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
              const SizedBox(height: 20),
              const Text(
                'Konfirmasi Absensi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pastikan data kehadiran santri sudah benar sebelum disimpan.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              // Summary Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: [
                  _buildSummaryTile(
                    icon: Icons.check_circle,
                    color: AppColors.primary,
                    bgColor: AppColors.primary.withOpacity(0.1),
                    label: 'Hadir',
                    count: h.toString(),
                  ),
                  _buildSummaryTile(
                    icon: Icons.local_hospital,
                    color: AppColors.secondary,
                    bgColor: AppColors.secondaryContainer.withOpacity(0.2),
                    label: 'Sakit',
                    count: s.toString(),
                  ),
                  _buildSummaryTile(
                    icon: Icons.info,
                    color: AppColors.tertiary,
                    bgColor: AppColors.tertiary.withOpacity(0.1),
                    label: 'Izin',
                    count: i.toString(),
                  ),
                  _buildSummaryTile(
                    icon: Icons.cancel,
                    color: AppColors.error,
                    bgColor: AppColors.error.withOpacity(0.1),
                    label: 'Alpha',
                    count: a.toString(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notification_important, color: AppColors.onSurfaceVariant),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Data yang sudah disimpan akan tercatat di sistem akademik dan dapat dilihat oleh wali santri.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Footer Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Kembali Mengedit',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close bottom sheet
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Absensi berhasil disimpan!'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                        Navigator.pop(context); // Go back to Dashboard
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Konfirmasi & Simpan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryTile({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String label,
    required String count,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                count,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.isTab ? null : AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Input Absensi',
          style: TextStyle(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Context Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(color: AppColors.outlineVariant),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halaqoh Tahfizh A',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: AppColors.onSurfaceVariant),
                            SizedBox(width: 6),
                            Text(
                              'Senin, 15 Okt 2023',
                              style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.person, size: 16, color: AppColors.onSurfaceVariant),
                            SizedBox(width: 6),
                            Text(
                              'Ust. Ahmad Fauzi',
                              style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.group, size: 16, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            '12 Santri',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryFixed,
                    foregroundColor: AppColors.secondary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.secondaryFixedDim),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ).applyTo(
                    ElevatedButton(
                      onPressed: _setAllHadir,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Set Semua Hadir',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Student List
          Expanded(
            child: ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                final currentStatus = attendanceState[index];

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    border: Border(
                      bottom: BorderSide(color: AppColors.outlineVariant),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.surfaceVariant,
                            backgroundImage: student['avatar'] != null
                                ? NetworkImage(student['avatar'])
                                : null,
                            child: student['avatar'] == null
                                ? Text(
                                    student['initials'] ?? '',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student['name'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${student['class']} • NIS: ${student['nis']}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatusChip(
                              label: 'Hadir',
                              status: 'H',
                              isSelected: currentStatus == 'H',
                              activeColor: AppColors.primary,
                              activeTextColor: AppColors.onPrimary,
                              onPressed: () => setState(() => attendanceState[index] = 'H'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatusChip(
                              label: 'Sakit',
                              status: 'S',
                              isSelected: currentStatus == 'S',
                              activeColor: AppColors.secondaryContainer,
                              activeTextColor: AppColors.onSecondary,
                              onPressed: () => setState(() => attendanceState[index] = 'S'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatusChip(
                              label: 'Izin',
                              status: 'I',
                              isSelected: currentStatus == 'I',
                              activeColor: AppColors.tertiary,
                              activeTextColor: AppColors.onTertiary,
                              onPressed: () => setState(() => attendanceState[index] = 'I'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatusChip(
                              label: 'Alpha',
                              status: 'A',
                              isSelected: currentStatus == 'A',
                              activeColor: AppColors.error,
                              activeTextColor: AppColors.onError,
                              onPressed: () => setState(() => attendanceState[index] = 'A'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Sticky Bottom Action
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.outlineVariant),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isAllFilled ? _showConfirmationSheet : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                  disabledForegroundColor: AppColors.onPrimary.withOpacity(0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save),
                    SizedBox(width: 8),
                    Text(
                      'Simpan Absensi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required String status,
    required bool isSelected,
    required Color activeColor,
    required Color activeTextColor,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : (status == 'A' ? AppColors.error.withOpacity(0.5) : AppColors.outlineVariant),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? activeTextColor
                : (status == 'A' ? AppColors.error : AppColors.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

// Helper extension to make standard ElevatedButton styles apply cleanly.
extension AppButtonExtension on ButtonStyle {
  ElevatedButton applyTo(ElevatedButton button) {
    return ElevatedButton(
      onPressed: button.onPressed,
      style: this,
      child: button.child,
    );
  }
}
