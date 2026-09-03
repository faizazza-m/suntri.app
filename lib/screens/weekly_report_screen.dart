import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'dashboards/admin_dashboard.dart'; // To access globalStateInstance

class WeeklyReportScreen extends StatefulWidget {
  final bool isTab;
  const WeeklyReportScreen({super.key, this.isTab = false});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  // Form values
  String? _selectedClass;
  String? _selectedSubject;
  final TextEditingController _materiCtrl = TextEditingController();
  final TextEditingController _catatanCtrl = TextEditingController();

  void _showWriteJournalModal(BuildContext context, List<String> classesList, List<String> subjectsList) {
    if (_selectedClass == null || !classesList.contains(_selectedClass)) {
      _selectedClass = classesList.isNotEmpty ? classesList.first : null;
    }
    if (_selectedSubject == null || !subjectsList.contains(_selectedSubject)) {
      _selectedSubject = subjectsList.isNotEmpty ? subjectsList.first : null;
    }

    final now = DateTime.now();
    // ISO format for DB storage (YYYY-MM-DD)
    final String todayDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    // Display format for UI hint (DD/MM/YYYY)
    final String todayDateDisplay = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Tulis Jurnal Mengajar',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.black54),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1, color: AppColors.outlineVariant),
                    
                    // Form Body
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // TANGGAL
                            const Text('TANGGAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 8),
                            TextField(
                              enabled: false,
                              decoration: InputDecoration(
                                hintText: todayDateDisplay,
                                hintStyle: const TextStyle(color: Colors.black87),
                                fillColor: Colors.grey.shade50,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // KELAS & MATA PELAJARAN
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('KELAS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        value: _selectedClass,
                                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                                        decoration: InputDecoration(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                        ),
                                        items: classesList.map((c) {
                                          return DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)));
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) setStateModal(() => _selectedClass = val);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('MATA PELAJARAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        value: _selectedSubject,
                                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                                        decoration: InputDecoration(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                        ),
                                        items: subjectsList.map((s) {
                                          return DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)));
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) setStateModal(() => _selectedSubject = val);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // TOPIK / MATERI
                            const Text('TOPIK / MATERI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _materiCtrl,
                              decoration: InputDecoration(
                                hintText: 'Contoh: Thaharah',
                                hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // CATATAN TAMBAHAN
                            const Text('CATATAN TAMBAHAN (OPSIONAL)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _catatanCtrl,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Tuliskan jika ada kendala, penugasan, atau santri yang bermasalah...',
                                hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    
                    // Footer Buttons
                    const Divider(height: 1, thickness: 1, color: AppColors.outlineVariant),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Batal', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              final jurnal = {
                                'date': todayDate,
                                'class': _selectedClass,
                                'subject': _selectedSubject,
                                'topic': _materiCtrl.text,
                                'notes': _catatanCtrl.text,
                              };
                              globalStateInstance.addJurnal(jurnal);
                              
                              Navigator.pop(context);
                              _materiCtrl.clear();
                              _catatanCtrl.clear();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Jurnal berhasil disimpan!'), backgroundColor: AppColors.primary),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.send, size: 18),
                            label: const Text('Simpan Jurnal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = globalStateInstance.currentUser;
    final teacherName = user?['name']?.toString().toLowerCase() ?? '';
    
    // Get unique classes and subjects from schedules for this teacher
    final mySchedules = globalStateInstance.schedules
        .where((s) => s['teacherId'].toString() == user?['id']?.toString())
        .toList();
        
    List<String> classesList = mySchedules.map((s) => s['class'].toString()).toSet().toList();
    List<String> subjectsList = mySchedules.map((s) => s['subject'].toString()).toSet().toList();
    
    if (classesList.isEmpty) classesList = ['Belum ada kelas'];
    if (subjectsList.isEmpty) subjectsList = ['Belum ada mapel'];
    
    final myJurnals = globalStateInstance.jurnals
        .where((j) => j['teacherId'].toString() == user?['id']?.toString())
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.isTab ? null : AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Jurnal Mengajar', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await globalStateInstance.syncFromDatabase();
        },
        child: myJurnals.isEmpty 
          ? CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.menu_book, size: 80, color: AppColors.outlineVariant),
                        const SizedBox(height: 16),
                        const Text('Riwayat Jurnal Kosong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant)),
                        const SizedBox(height: 8),
                        const Text('Belum ada jurnal mengajar minggu ini.', style: TextStyle(color: AppColors.outline)),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () => _showWriteJournalModal(context, classesList, subjectsList),
                          icon: const Icon(Icons.add),
                          label: const Text('Tulis Jurnal Mengajar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 16, 16, widget.isTab ? 160 : 16),
              itemCount: myJurnals.length,
              itemBuilder: (context, index) {
                final jurnal = myJurnals[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
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
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.primary),
                                        const SizedBox(width: 6),
                                        Text(
                                          jurnal['date'] ?? '', 
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12)
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondaryFixedDim.withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        jurnal['class'] ?? '', 
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onSecondaryContainer)
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(jurnal['subject'] ?? '', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black87)),
                                const SizedBox(height: 6),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.menu_book, size: 14, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Topik: ${jurnal['topic'] ?? '-'}', 
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade800, fontWeight: FontWeight.w500)
                                      ),
                                    ),
                                  ],
                                ),
                                if (jurnal['notes'] != null && jurnal['notes'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.grey.shade200)
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.info_outline, size: 14, color: Colors.black45),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Catatan: ${jurnal['notes']}', 
                                            style: const TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic)
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      ),
      floatingActionButton: myJurnals.isNotEmpty 
          ? Padding(
              padding: EdgeInsets.only(bottom: widget.isTab ? 90.0 : 0),
              child: FloatingActionButton(
                onPressed: () => _showWriteJournalModal(context, classesList, subjectsList),
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            )
          : null,
    );
  }
}
