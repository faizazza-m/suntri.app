import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../dashboards/admin_dashboard.dart'; // To access globalStateInstance

class AkademikScreen extends StatefulWidget {
  final bool isTab;
  const AkademikScreen({super.key, this.isTab = false});

  @override
  State<AkademikScreen> createState() => _AkademikScreenState();
}

class _AkademikScreenState extends State<AkademikScreen> {
  // Input fields for grade formula
  final TextEditingController _tugasCtrl = TextEditingController();
  final TextEditingController _uasCtrl = TextEditingController();
  
  String _selectedSubject = 'Fiqih';
  String _selectedClass = '10A MIPA';
  String? _activeStudentForRaport;

  void _openGradeFormulaModal(Map<String, dynamic> student) {
    // Check if grade already exists
    final existingGrade = globalStateInstance.grades.firstWhere(
      (g) => g['studentName'] == student['name'] && g['subject'] == _selectedSubject,
      orElse: () => {},
    );

    if (existingGrade.isNotEmpty) {
      _tugasCtrl.text = existingGrade['tugas'].toString();
      _uasCtrl.text = existingGrade['uas'].toString();
    } else {
      _tugasCtrl.clear();
      _uasCtrl.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
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
                  Text(
                    'Input Nilai: ${student['name']}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                  ),
                  Text('Mata Pelajaran: $_selectedSubject • Kelas: $_selectedClass', style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 20),

                  // Formula Notice Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Formula Penilaian Akademik:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Nilai Akhir = (Tugas/Harian × 20%) + (UAS × 80%)',
                          style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Form inputs
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Nilai Tugas/Harian (20%)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _tugasCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: '85', fillColor: AppColors.surfaceContainerLowest),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Nilai UAS (80%)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _uasCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: '88', fillColor: AppColors.surfaceContainerLowest),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Save action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final tugasVal = double.tryParse(_tugasCtrl.text) ?? 0;
                        final uasVal = double.tryParse(_uasCtrl.text) ?? 0;

                        if (tugasVal > 100 || uasVal > 100) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Nilai tidak boleh melebihi 100!'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        globalStateInstance.saveGrade(
                          studentName: student['name'],
                          className: _selectedClass,
                          subject: _selectedSubject,
                          tugas: tugasVal,
                          uh: 0,
                          uts: 0,
                          uas: uasVal,
                        );

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Nilai akademik berhasil dihitung & disimpan!'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Hitung & Simpan Nilai', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: widget.isTab ? null : IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        automaticallyImplyLeading: !widget.isTab,
        title: const Text('Manajemen Akademik', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: ListenableBuilder(
        listenable: globalStateInstance,
        builder: (context, child) {
          return _buildNilaiTab();
        },
      ),
    );
  }

  Widget _buildNilaiTab() {
    final user = globalStateInstance.currentUser;
    final String? userTeacherId = user?['id']?.toString();

    // 1. Get class list
    final List<String> classesList;
    if (userTeacherId != null) {
      final teacherSchedules = globalStateInstance.schedules
          .where((s) => s['teacherId'].toString() == userTeacherId)
          .toList();
      if (teacherSchedules.isNotEmpty) {
        classesList = teacherSchedules
            .map((s) => s['class'].toString())
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList();
      } else {
        classesList = globalStateInstance.students
            .map((s) => s['class'].toString())
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList();
      }
    } else {
      classesList = globalStateInstance.students
          .map((s) => s['class'].toString())
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList();
    }
    if (classesList.isNotEmpty && !classesList.contains(_selectedClass)) {
      _selectedClass = classesList.first;
    }

    // 2. Get subject list
    final List<String> subjectsList;
    if (userTeacherId != null) {
      final teacherSchedules = globalStateInstance.schedules
          .where((s) => s['teacherId'].toString() == userTeacherId)
          .toList();
      if (teacherSchedules.isNotEmpty) {
        subjectsList = teacherSchedules
            .map((s) => s['subject'].toString())
            .where((sub) => sub.isNotEmpty)
            .toSet()
            .toList();
      } else {
        subjectsList = globalStateInstance.schedules
            .map((s) => s['subject'].toString())
            .where((sub) => sub.isNotEmpty)
            .toSet()
            .toList();
      }
    } else {
      subjectsList = globalStateInstance.schedules
          .map((s) => s['subject'].toString())
          .where((sub) => sub.isNotEmpty)
          .toSet()
          .toList();
    }
    if (subjectsList.isNotEmpty && !subjectsList.contains(_selectedSubject)) {
      _selectedSubject = subjectsList.first;
    }

    // Filter students by selected class
    final classStudents = globalStateInstance.students.where((s) => s['class'] == _selectedClass).toList();

    return Column(
      children: [
        // Dropdowns header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
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
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedClass,
                  decoration: InputDecoration(
                    labelText: 'Kelas',
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.primary.withOpacity(0.04),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                  items: (classesList.isEmpty ? [_selectedClass] : classesList).map((c) {
                    return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedClass = val;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSubject,
                  decoration: InputDecoration(
                    labelText: 'Mata Pelajaran',
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.primary.withOpacity(0.04),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                  items: (subjectsList.isEmpty ? [_selectedSubject] : subjectsList).map((s) {
                    return DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedSubject = val;
                      });
                    }
                  },
                ),
              )
            ],
          ),
        ),

        // List
        Expanded(
          child: classStudents.isEmpty
              ? const Center(child: Text('Tidak ada santri di kelas ini.'))
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, widget.isTab ? 160 : 16),
                  itemCount: classStudents.length,
                  itemBuilder: (context, idx) {
                    final std = classStudents[idx];
                    final grade = globalStateInstance.grades.firstWhere(
                      (g) => g['studentName'] == std['name'] && g['subject'] == _selectedSubject,
                      orElse: () => {},
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                std['name'].toString().substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  std['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.badge_outlined, size: 12, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      'NIS: ${std['nis']} • Kelas: ${std['class']}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                grade.isNotEmpty ? grade['finalScore'].toString() : 'Belum Input',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: grade.isNotEmpty ? 15 : 10,
                                  color: grade.isNotEmpty ? AppColors.primary : AppColors.outline,
                                ),
                              ),
                              if (grade.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'NILAI AKHIR',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () => _openGradeFormulaModal(std),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: grade.isNotEmpty ? Colors.blue.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                grade.isNotEmpty ? Icons.edit : Icons.add_chart,
                                color: grade.isNotEmpty ? Colors.blue : AppColors.primary,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        )
      ],
    );
  }

  Widget _buildRaportTab() {
    if (globalStateInstance.students.isEmpty) {
      return const Center(child: Text('Tidak ada santri untuk raport.'));
    }

    if (_activeStudentForRaport == null && globalStateInstance.students.isNotEmpty) {
      _activeStudentForRaport = globalStateInstance.students[0]['name']?.toString() ?? 'Santri';
    }

    final std = globalStateInstance.students.firstWhere(
      (s) => (s['name']?.toString() ?? 'Santri') == _activeStudentForRaport,
      orElse: () => globalStateInstance.students[0],
    );

    // Get grades for the active student
    final stdGrades = globalStateInstance.grades.where((g) => g['studentName'] == std['name']).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pilih Santri untuk Raport', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _activeStudentForRaport,
            decoration: const InputDecoration(fillColor: Colors.white, filled: true),
            items: globalStateInstance.students.map((s) {
              final String name = s['name']?.toString() ?? 'Santri';
              return DropdownMenuItem(value: name, child: Text(name));
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _activeStudentForRaport = val;
                });
              }
            },
          ),
          const SizedBox(height: 24),

          // Print-ready premium mockup sheet for Raport
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Raport
                const Center(
                  child: Column(
                    children: [
                      Text(
                        'LAPORAN HASIL BELAJAR (RAPORT)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      Text(
                        "MA'HAD TAHFIDZ RIJAALUL QUR'AN",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      Divider(thickness: 1.5),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Student Identity Section
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(2),
                  },
                  children: [
                    TableRow(children: [
                      const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Nama Santri', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(': ${std['name']}', style: const TextStyle(fontSize: 11))),
                    ]),
                    TableRow(children: [
                      const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('NIS / Kelas', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(': ${std['nis']} / ${std['class']}', style: const TextStyle(fontSize: 11))),
                    ]),
                  ],
                ),
                const SizedBox(height: 20),

                // Table Nilai
                Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(1),
                    4: FlexColumnWidth(1),
                    5: FlexColumnWidth(1.2),
                  },
                  children: [
                    // Header row
                    const TableRow(
                      decoration: BoxDecoration(color: AppColors.surfaceContainer),
                      children: [
                        Padding(padding: EdgeInsets.all(6), child: Text('Mata Pelajaran', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(6), child: Text('Tgs', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(6), child: Text('UH', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(6), child: Text('UTS', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(6), child: Text('UAS', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(6), child: Text('Akhir', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    // Value rows
                    if (stdGrades.isEmpty)
                      const TableRow(
                        children: [
                          Padding(padding: EdgeInsets.all(12), child: Text('Belum ada nilai akademik yang masuk.', style: TextStyle(fontSize: 10, color: AppColors.outline))),
                          Padding(padding: EdgeInsets.all(6), child: Text('')),
                          Padding(padding: EdgeInsets.all(6), child: Text('')),
                          Padding(padding: EdgeInsets.all(6), child: Text('')),
                          Padding(padding: EdgeInsets.all(6), child: Text('')),
                          Padding(padding: EdgeInsets.all(6), child: Text('')),
                        ],
                      )
                    else
                      ...stdGrades.map((g) {
                        return TableRow(
                          children: [
                            Padding(padding: const EdgeInsets.all(6), child: Text(g['subject'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                            Padding(padding: const EdgeInsets.all(6), child: Text(g['tugas'].toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 10))),
                            Padding(padding: const EdgeInsets.all(6), child: Text(g['uh'].toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 10))),
                            Padding(padding: const EdgeInsets.all(6), child: Text(g['uts'].toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 10))),
                            Padding(padding: const EdgeInsets.all(6), child: Text(g['uas'].toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 10))),
                            Padding(padding: const EdgeInsets.all(6), child: Text(g['finalScore'].toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary))),
                          ],
                        );
                      }),
                  ],
                ),
                const SizedBox(height: 24),

                // Signature areas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        const Text('Wali Kelas', style: TextStyle(fontSize: 10)),
                        const SizedBox(height: 48),
                        Container(width: 80, height: 1, color: Colors.black),
                        const SizedBox(height: 2),
                        const Text('NIP. -----------------', style: TextStyle(fontSize: 9)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Orang Tua / Wali', style: TextStyle(fontSize: 10)),
                        const SizedBox(height: 48),
                        Text(std['parent'] ?? '-', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        const Text('Tanda Tangan Basah', style: TextStyle(fontSize: 9, color: AppColors.outline)),
                      ],
                    )
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
