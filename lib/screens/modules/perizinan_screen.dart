import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../dashboards/admin_dashboard.dart'; // To access globalStateInstance

class PerizinanScreen extends StatefulWidget {
  const PerizinanScreen({super.key});

  @override
  State<PerizinanScreen> createState() => _PerizinanScreenState();
}

class _PerizinanScreenState extends State<PerizinanScreen> {
  final TextEditingController _studentNameCtrl = TextEditingController();
  final TextEditingController _reasonCtrl = TextEditingController();
  final TextEditingController _contactCtrl = TextEditingController();
  
  String _selectedLeaveType = 'Sakit';
  String _selectedStartDate = '2023-10-27';
  String _selectedEndDate = '2023-10-28';
  int _durationDays = 1;

  void _calculateDuration() {
    try {
      final start = DateTime.parse(_selectedStartDate);
      final end = DateTime.parse(_selectedEndDate);
      final diff = end.difference(start).inDays + 1;
      setState(() {
        _durationDays = diff > 0 ? diff : 1;
      });
    } catch (_) {}
  }

  void _submitRequest() {
    if (_studentNameCtrl.text.isEmpty || _reasonCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi nama santri & alasan!'), backgroundColor: Colors.red),
      );
      return;
    }

    globalStateInstance.addPermission({
      'id': 'perm_${DateTime.now().millisecondsSinceEpoch}',
      'studentName': _studentNameCtrl.text,
      'type': _selectedLeaveType,
      'dateStart': _selectedStartDate,
      'dateEnd': _selectedEndDate,
      'durationDays': _durationDays,
      'reason': _reasonCtrl.text,
      'contact': _contactCtrl.text,
      'status': 'Ditinjau',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pengajuan perizinan berhasil dikirim!'),
        backgroundColor: AppColors.primary,
      ),
    );

    _studentNameCtrl.clear();
    _reasonCtrl.clear();
    _contactCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Manajemen Perizinan', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0.5,
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.outline,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Ajukan Izin'),
              Tab(text: 'Persetujuan Admin'),
            ],
          ),
        ),
        body: ListenableBuilder(
          listenable: globalStateInstance,
          builder: (context, child) {
            // Compute real-time stats
            final total = globalStateInstance.permissions.length;
            final approved = globalStateInstance.permissions.where((p) => p['status'] == 'Disetujui').length;
            final rejected = globalStateInstance.permissions.where((p) => p['status'] == 'Ditolak').length;

            return TabBarView(
              children: [
                // TAB 1: FORM PENGAJUAN IZIN
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Realtime stats row
                      Row(
                        children: [
                          Expanded(child: _buildStatBox('Total Izin', '$total', Colors.blue)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildStatBox('Disetujui', '$approved', Colors.green)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildStatBox('Ditolak', '$rejected', Colors.red)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Formulir Perizinan Santri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 18),

                              // Student Name
                              const Text('Nama Santri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _studentNameCtrl,
                                decoration: const InputDecoration(hintText: 'Cari atau ketik nama...'),
                              ),
                              const SizedBox(height: 16),

                              // Leave Type
                              const Text('Jenis Izin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _selectedLeaveType,
                                items: ['Sakit', 'Pulang', 'Keluar', 'Liburan'].map((type) {
                                  return DropdownMenuItem(value: type, child: Text(type));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedLeaveType = val;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 16),

                              // Dates & Duration Math
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Mulai Tanggal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                        const SizedBox(height: 6),
                                        InkWell(
                                          onTap: () async {
                                            final date = await showDatePicker(
                                              context: context,
                                              initialDate: DateTime.now(),
                                              firstDate: DateTime(2020),
                                              lastDate: DateTime(2030),
                                            );
                                            if (date != null) {
                                              setState(() {
                                                _selectedStartDate = date.toString().split(' ')[0];
                                                _calculateDuration();
                                              });
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceContainerLowest,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: AppColors.outlineVariant),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [Text(_selectedStartDate, style: const TextStyle(fontSize: 12)), const Icon(Icons.calendar_today, size: 14)],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Hingga Tanggal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                        const SizedBox(height: 6),
                                        InkWell(
                                          onTap: () async {
                                            final date = await showDatePicker(
                                              context: context,
                                              initialDate: DateTime.now().add(const Duration(days: 1)),
                                              firstDate: DateTime(2020),
                                              lastDate: DateTime(2030),
                                            );
                                            if (date != null) {
                                              setState(() {
                                                _selectedEndDate = date.toString().split(' ')[0];
                                                _calculateDuration();
                                              });
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceContainerLowest,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: AppColors.outlineVariant),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [Text(_selectedEndDate, style: const TextStyle(fontSize: 12)), const Icon(Icons.calendar_today, size: 14)],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Durasi: $_durationDays Hari',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12),
                              ),
                              const SizedBox(height: 16),

                              // Reason
                              const Text('Alasan Izin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _reasonCtrl,
                                maxLines: 2,
                                decoration: const InputDecoration(hintText: 'Tuliskan alasan lengkap...'),
                              ),
                              const SizedBox(height: 16),

                              // Emergency Contact
                              const Text('Kontak Darurat (Wali)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _contactCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(hintText: '08xxxxxxxxx'),
                              ),
                              const SizedBox(height: 24),

                              // Submit
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _submitRequest,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: const Text('Kirim Pengajuan Izin', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),

                // TAB 2: ADMIN PERSUBANGAN LIST
                _buildAdminApprovalTab(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildAdminApprovalTab() {
    final list = globalStateInstance.permissions.where((p) => p['status'] == 'Ditinjau').toList();

    if (list.isEmpty) {
      return const Center(child: Text('Tidak ada pengajuan izin tertunda.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final perm = list[idx];
        return Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(perm['studentName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Izin: ${perm['type']}',
                        style: const TextStyle(color: Colors.purple, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text('Tanggal: ${perm['dateStart']} s/d ${perm['dateEnd']} (${perm['durationDays']} hari)', style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                Text('Alasan: ${perm['reason']}', style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        globalStateInstance.rejectPermission(perm['id']);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Tolak', style: TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        globalStateInstance.approvePermission(perm['id']);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Setujui', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
