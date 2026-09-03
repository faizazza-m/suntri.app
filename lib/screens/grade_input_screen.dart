import 'package:flutter/material.dart';
import '../constants/colors.dart';

class GradeInputScreen extends StatefulWidget {
  const GradeInputScreen({super.key});

  @override
  State<GradeInputScreen> createState() => _GradeInputScreenState();
}

class _GradeInputScreenState extends State<GradeInputScreen> {
  String _selectedCategory = 'Ujian Akhir Semester (UAS)';

  // Student list data with controller state
  late List<Map<String, dynamic>> students;

  @override
  void initState() {
    super.initState();
    students = [
      {
        'name': 'Ahmad Hidayat',
        'nis': '10293847',
        'initials': 'AH',
        'avatar': null,
        'tugasCtrl': TextEditingController(text: '85'),
        'uasCtrl': TextEditingController(text: '80'),
        'akhir': '83',
        'hasError': false,
      },
      {
        'name': 'Budi Utama',
        'nis': '10293848',
        'initials': 'BU',
        'avatar': null,
        'tugasCtrl': TextEditingController(text: '92'),
        'uasCtrl': TextEditingController(text: '105'),
        'akhir': 'Err',
        'hasError': true,
      },
      {
        'name': 'Citra Lestari',
        'nis': '10293849',
        'initials': 'CL',
        'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAiLDrgoHPWmt58_jQfUCJ5G_9Yfaq14ok3sY6nBofoK7VbgD_zdO8BBVJMZBtaoMZYVWJNbH5cCBRI2EXpRV69_Ovisv9lJ1PFavdfNcqxZTAac0nG12FaPlCT4oYsqfbqDmvRrn3gxhbg8i_H5Rsf-ey5cB9lqydnsnlCQgCSlCC-L1MUaUwi0YVU0IWLHKmi0CFz_vX-Rc8dEyEcA-03Y9IK12NXaIB0mgxNemaNkLgFC-8qxrE-',
        'tugasCtrl': TextEditingController(text: ''),
        'uasCtrl': TextEditingController(text: ''),
        'akhir': '-',
        'hasError': false,
      },
    ];

    // Listeners for live computations
    for (var student in students) {
      student['tugasCtrl'].addListener(() => _calculateScore(student));
      student['uasCtrl'].addListener(() => _calculateScore(student));
    }
  }

  @override
  void dispose() {
    for (var student in students) {
      student['tugasCtrl'].dispose();
      student['uasCtrl'].dispose();
    }
    super.dispose();
  }

  void _calculateScore(Map<String, dynamic> student) {
    final String tStr = student['tugasCtrl'].text;
    final String uasStr = student['uasCtrl'].text;

    int? tVal = int.tryParse(tStr);
    int? uasVal = int.tryParse(uasStr);

    // Validate values (0 to 100)
    bool error = false;
    if ((tStr.isNotEmpty && (tVal == null || tVal < 0 || tVal > 100)) ||
        (uasStr.isNotEmpty && (uasVal == null || uasVal < 0 || uasVal > 100))) {
      error = true;
    }

    setState(() {
      student['hasError'] = error;
      if (error) {
        student['akhir'] = 'Err';
      } else {
        // Average computation
        List<int> vals = [];
        if (tVal != null) vals.add(tVal);
        if (uasVal != null) vals.add(uasVal);

        if (vals.isEmpty) {
          student['akhir'] = '-';
        } else {
          double avg = vals.reduce((a, b) => a + b) / vals.length;
          student['akhir'] = avg.round().toString();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Input Nilai',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.onSurface),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Scrollable chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Fiqih'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Kelas 10-A'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Ganjil 2023'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Category row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kategori:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedCategory = newValue;
                              });
                            }
                          },
                          items: <String>[
                            'Tugas/Harian',
                            'Ujian Akhir Semester (UAS)',
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Grading List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                final bool isOpacityLow = student['tugasCtrl'].text.isEmpty &&
                    student['uasCtrl'].text.isEmpty;

                return Opacity(
                  opacity: isOpacityLow ? 0.75 : 1.0,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: student['hasError'] ? AppColors.error : AppColors.outlineVariant,
                        width: student['hasError'] ? 2.0 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Left error strip indicator
                        if (student['hasError'])
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 4,
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
                              ),
                            ),
                          ),
                        Padding(
                          padding: EdgeInsets.only(left: student['hasError'] ? 8.0 : 0.0),
                          child: Column(
                            children: [
                              // Student Details Header
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.surfaceContainerHigh,
                                    backgroundImage: student['avatar'] != null
                                        ? NetworkImage(student['avatar'])
                                        : null,
                                    child: student['avatar'] == null
                                        ? Text(
                                            student['initials'],
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
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
                                      Text(
                                        'NIS: ${student['nis']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Inputs Grid
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: _buildGradeInputField(
                                      label: 'Tugas/Harian',
                                      controller: student['tugasCtrl'],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: _buildGradeInputField(
                                      label: 'UAS',
                                      controller: student['uasCtrl'],
                                      isHighlighted: true,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Final block
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainerLowest,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
                                      ),
                                      child: Column(
                                        children: [
                                          const Text(
                                            'Akhir',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            student['akhir'],
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: student['akhir'] == 'Err'
                                                  ? AppColors.error
                                                  : (student['akhir'] == '-'
                                                      ? AppColors.onSurfaceVariant
                                                      : AppColors.onSurface),
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
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Action Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest.withOpacity(0.9),
              border: const Border(
                top: BorderSide(color: AppColors.outlineVariant),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_done,
                      color: AppColors.tertiaryFixedDim,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Semua perubahan tersimpan otomatis',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Check for errors
                      bool hasAnyError = students.any((s) => s['hasError']);
                      if (hasAnyError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Terdapat kesalahan pengisian nilai. Harap perbaiki!'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Nilai berhasil disimpan dan divalidasi!'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save),
                        SizedBox(width: 8),
                        Text(
                          'Simpan & Validasi Nilai',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.onSurface),
        ],
      ),
    );
  }

  Widget _buildGradeInputField({
    required String label,
    required TextEditingController controller,
    bool isHighlighted = false,
  }) {
    // Detect error locally for background styling
    final int? val = int.tryParse(controller.text);
    final bool isInvalid = controller.text.isNotEmpty && (val == null || val < 0 || val > 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isHighlighted ? AppColors.primary : AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: isInvalid ? AppColors.error : AppColors.onSurface,
          ),
          decoration: InputDecoration(
            fillColor: isInvalid
                ? AppColors.errorContainer.withOpacity(0.3)
                : (isHighlighted ? AppColors.surfaceContainerLow : AppColors.surface),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isInvalid
                    ? AppColors.error
                    : (isHighlighted ? AppColors.primary : AppColors.outlineVariant),
                width: isHighlighted ? 2.0 : 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isInvalid ? AppColors.error : AppColors.primary,
                width: 2.0,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            hintText: '-',
          ),
        ),
      ],
    );
  }
}
