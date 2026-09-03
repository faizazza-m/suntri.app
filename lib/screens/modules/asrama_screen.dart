import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../dashboards/admin_dashboard.dart'; // To access globalStateInstance

class AsramaScreen extends StatefulWidget {
  const AsramaScreen({super.key});

  @override
  State<AsramaScreen> createState() => _AsramaScreenState();
}

class _AsramaScreenState extends State<AsramaScreen> {
  String? _selectedStudentToAssign;

  void _openAssignModal(Map<String, dynamic> room) {
    _selectedStudentToAssign = null;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Filter students who are NOT already in this room
            final List<String> currentOccupants = List<String>.from(room['occupants']);
            final availableStudents = globalStateInstance.students
                .where((s) => !currentOccupants.contains(s['name']))
                .toList();

            return AlertDialog(
              title: Text('Tambah Penghuni: ${room['name']}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pilih Santri:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  availableStudents.isEmpty
                      ? const Text('Semua santri sudah memiliki asrama ini.')
                      : DropdownButtonFormField<String>(
                          value: _selectedStudentToAssign,
                          hint: const Text('Pilih nama...'),
                          items: availableStudents.map((s) {
                            return DropdownMenuItem(value: s['name'] as String, child: Text(s['name'] as String));
                          }).toList(),
                          onChanged: (val) {
                            setModalState(() {
                              _selectedStudentToAssign = val;
                            });
                          },
                        ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: _selectedStudentToAssign == null
                      ? null
                      : () {
                          globalStateInstance.assignOccupant(room['id'], _selectedStudentToAssign!);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$_selectedStudentToAssign dimasukkan ke ${room['name']}!'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                  child: const Text('Simpan'),
                )
              ],
            );
          },
        );
      },
    );
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
        title: const Text('Manajemen Asrama', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: ListenableBuilder(
        listenable: globalStateInstance,
        builder: (context, child) {
          final listRooms = globalStateInstance.rooms;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: listRooms.length,
            itemBuilder: (context, idx) {
              final room = listRooms[idx];
              final List<String> occupants = List<String>.from(room['occupants']);
              final cap = room['capacity'];
              final filledPct = cap > 0 ? (occupants.length / cap) : 0.0;
              Color indicatorColor = AppColors.primary;
              if (filledPct >= 0.9) {
                indicatorColor = Colors.red;
              } else if (filledPct >= 0.75) {
                indicatorColor = Colors.orange;
              }

              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Assign Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(room['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('Kapasitas: $cap Santri • Tersedia: ${cap - occupants.length}', style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: occupants.length >= cap ? null : () => _openAssignModal(room),
                            icon: const Icon(Icons.add, size: 14),
                            label: const Text('Tambah', style: TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Capacity Indicator bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: filledPct,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Occupants List tags/chips
                      const Text('Daftar Penghuni:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 6),
                      occupants.isEmpty
                          ? const Text('Kamar ini masih kosong.', style: TextStyle(fontSize: 11, color: AppColors.outline))
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: occupants.map((occName) {
                                return Chip(
                                  backgroundColor: AppColors.surfaceContainer,
                                  deleteIconColor: Colors.red,
                                  onDeleted: () {
                                    globalStateInstance.removeOccupant(room['id'], occName);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('$occName dikeluarkan dari ${room['name']}!'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  },
                                  label: Text(occName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                );
                              }).toList(),
                            ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
