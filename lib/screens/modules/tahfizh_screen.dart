import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../dashboards/admin_dashboard.dart'; // To access globalStateInstance

class TahfizhScreen extends StatefulWidget {
  const TahfizhScreen({super.key});

  @override
  State<TahfizhScreen> createState() => _TahfizhScreenState();
}

class _TahfizhScreenState extends State<TahfizhScreen> {
  // Input fields controllers
  final TextEditingController _studentNameCtrl = TextEditingController();
  final TextEditingController _surahCtrl = TextEditingController();
  final TextEditingController _ayatDariCtrl = TextEditingController();
  final TextEditingController _ayatSampaiCtrl = TextEditingController();
  final TextEditingController _juzCtrl = TextEditingController();

  String _selectedType = 'Ziyadah';
  String _selectedKelancaran = 'Sangat Baik';
  String _selectedTajwid = 'Baik';
  String _selectedMakharijul = 'Baik';

  // Halaqoh Form Controllers
  final TextEditingController _hqNameCtrl = TextEditingController();
  final TextEditingController _hqTeacherCtrl = TextEditingController();

  void _openAddSetoranModal({Map<String, dynamic>? editItem}) {
    if (editItem != null) {
      _studentNameCtrl.text = editItem['studentName'];
      _surahCtrl.text = editItem['surah'];
      _ayatDariCtrl.text = editItem['ayatDari'];
      _ayatSampaiCtrl.text = editItem['ayatSampai'];
      _juzCtrl.text = editItem['juz'];
      _selectedType = editItem['type'];
      _selectedKelancaran = editItem['kelancaran'];
      _selectedTajwid = editItem['tajwid'];
      _selectedMakharijul = editItem['makharijul'];
    } else {
      _studentNameCtrl.clear();
      _surahCtrl.clear();
      _ayatDariCtrl.clear();
      _ayatSampaiCtrl.clear();
      _juzCtrl.clear();
      _selectedType = 'Ziyadah';
      _selectedKelancaran = 'Sangat Baik';
      _selectedTajwid = 'Baik';
      _selectedMakharijul = 'Baik';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
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
                        editItem != null ? 'Edit Setoran Hafalan' : 'Input Setoran Baru',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                      ),
                      const SizedBox(height: 20),

                      // Student Selector (Autocomplete style textfield for simplicity)
                      const Text('Nama Santri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _studentNameCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Cari nama santri...',
                          fillColor: AppColors.surfaceContainerLowest,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Setoran Type Choice Chips
                      Row(
                        children: ['Ziyadah', 'Murajaah', 'Tasmi\''].map((type) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(type),
                              selected: _selectedType == type,
                              onSelected: (val) {
                                if (val) {
                                  setModalState(() {
                                    _selectedType = type;
                                  });
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Surah, Verses & Juz
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Surah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.onSurfaceVariant)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _surahCtrl,
                                  decoration: const InputDecoration(hintText: 'Al-Baqarah', fillColor: AppColors.surfaceContainerLowest),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Juz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.onSurfaceVariant)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _juzCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(hintText: '1', fillColor: AppColors.surfaceContainerLowest),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Dari Ayat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.onSurfaceVariant)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _ayatDariCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(hintText: '1', fillColor: AppColors.surfaceContainerLowest),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Sampai Ayat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.onSurfaceVariant)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _ayatSampaiCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(hintText: '10', fillColor: AppColors.surfaceContainerLowest),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Evaluation dropdowns (Kelancaran, Tajwid, Makharijul)
                      const Text('Evaluasi Kelancaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedKelancaran,
                        decoration: const InputDecoration(fillColor: AppColors.surfaceContainerLowest),
                        items: ['Sangat Baik', 'Baik', 'Cukup', 'Kurang'].map((k) {
                          return DropdownMenuItem(value: k, child: Text(k));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              _selectedKelancaran = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      // Save action
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_studentNameCtrl.text.isEmpty || _surahCtrl.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Mohon isi nama dan surah!'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if (editItem != null) {
                              // Edit existing record
                              globalStateInstance.deleteSetoran(editItem['id']);
                            }

                            // Add new setoran
                            globalStateInstance.addSetoran({
                              'id': editItem != null ? editItem['id'] : 'set_${DateTime.now().millisecondsSinceEpoch}',
                              'studentName': _studentNameCtrl.text,
                              'type': _selectedType,
                              'surah': _surahCtrl.text,
                              'ayatDari': _ayatDariCtrl.text,
                              'ayatSampai': _ayatSampaiCtrl.text,
                              'juz': _juzCtrl.text.isEmpty ? '1' : _juzCtrl.text,
                              'kelancaran': _selectedKelancaran,
                              'tajwid': _selectedTajwid,
                              'makharijul': _selectedMakharijul,
                              'date': DateTime.now().toString().split(' ')[0],
                            });

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(editItem != null ? 'Setoran berhasil diperbarui!' : 'Setoran baru berhasil disimpan!'),
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
                          child: Text(editItem != null ? 'Perbarui Setoran' : 'Simpan Setoran', style: const TextStyle(fontWeight: FontWeight.bold)),
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

  void _openAddHalaqohModal({Map<String, dynamic>? editItem}) {
    if (editItem != null) {
      _hqNameCtrl.text = editItem['name'];
      _hqTeacherCtrl.text = editItem['teacher'];
    } else {
      _hqNameCtrl.clear();
      _hqTeacherCtrl.clear();
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(editItem != null ? 'Edit Halaqoh' : 'Tambah Halaqoh'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _hqNameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Halaqoh'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _hqTeacherCtrl,
                decoration: const InputDecoration(labelText: 'Guru / Musyrif'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                if (_hqNameCtrl.text.isEmpty || _hqTeacherCtrl.text.isEmpty) return;

                if (editItem != null) {
                  globalStateInstance.updateHalaqoh(
                    editItem['id'],
                    _hqNameCtrl.text,
                    _hqTeacherCtrl.text,
                    List<String>.from(editItem['studentIds']),
                  );
                } else {
                  globalStateInstance.addHalaqoh(
                    _hqNameCtrl.text,
                    _hqTeacherCtrl.text,
                    [],
                  );
                }
                Navigator.pop(context);
              },
              child: const Text('Simpan'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Manajemen Tahfizh', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0.5,
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.outline,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Setoran'),
              Tab(text: 'Halaqoh'),
              Tab(text: 'Analisis'),
            ],
          ),
        ),
        body: ListenableBuilder(
          listenable: globalStateInstance,
          builder: (context, child) {
            return TabBarView(
              children: [
                // TAB 1: SETORAN CRUD
                _buildSetoranTab(),
                // TAB 2: HALAQOH CRUD
                _buildHalaqohTab(),
                // TAB 3: ANALISIS & TOP SANTRI
                _buildAnalisisTab(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSetoranTab() {
    final list = globalStateInstance.setorans;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Daftar Setoran Hafalan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _openAddSetoranModal(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Input Setoran'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              )
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('Belum ada data setoran.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (context, idx) {
                    final item = list[idx];
                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        title: Text(item['studentName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${item['type']} • Surah ${item['surah']} • Ayat ${item['ayatDari']}-${item['ayatSampai']} (Juz ${item['juz']})\nKondisi: ${item['kelancaran']}',
                          style: const TextStyle(fontSize: 12, height: 1.4),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                              onPressed: () => _openAddSetoranModal(editItem: item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () {
                                globalStateInstance.deleteSetoran(item['id']);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        )
      ],
    );
  }

  Widget _buildHalaqohTab() {
    final list = globalStateInstance.halaqohs;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Kelompok Halaqoh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _openAddHalaqohModal(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Tambah Halaqoh'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              )
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('Belum ada data halaqoh.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (context, idx) {
                    final item = list[idx];
                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Musyrif: ${item['teacher']}\nJumlah Santri: ${item['studentIds'].length} orang'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                              onPressed: () => _openAddHalaqohModal(editItem: item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () {
                                globalStateInstance.deleteHalaqoh(item['id']);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        )
      ],
    );
  }

  Widget _buildAnalisisTab() {
    // Sort students by Juz achievement to display Top Santri
    final sortedStudents = List<Map<String, dynamic>>.from(globalStateInstance.students);
    sortedStudents.sort((a, b) => (b['juz'] as int).compareTo(a['juz'] as int));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Santri Hafalan Terbanyak', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...List.generate(sortedStudents.take(3).length, (idx) {
            final std = sortedStudents[idx];
            IconData medal = Icons.workspace_premium;
            Color medalColor = Colors.yellow.shade700;
            if (idx == 1) medalColor = Colors.grey.shade400;
            if (idx == 2) medalColor = Colors.orange.shade400;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Icon(medal, color: medalColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(std['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Kelas ${std['class']} • NIS ${std['nis']}', style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Text('Juz ${std['juz']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),

          // Simple 7-day progress bar chart
          const Text('Progress Hafalan (7 Hari)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar(3, '20/10'),
                _buildBar(5, '21/10'),
                _buildBar(2, '22/10'),
                _buildBar(8, '23/10'),
                _buildBar(6, '24/10'),
                _buildBar(10, '25/10'),
                _buildBar(4, '26/10'),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBar(double val, String label) {
    return Column(
      children: [
        Container(
          width: 18,
          height: val * 8,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.8),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text('$val', style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
