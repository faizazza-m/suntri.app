import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../dashboards/admin_dashboard.dart'; // To access globalStateInstance

class KesehatanScreen extends StatefulWidget {
  const KesehatanScreen({super.key});

  @override
  State<KesehatanScreen> createState() => _KesehatanScreenState();
}

class _KesehatanScreenState extends State<KesehatanScreen> {
  final TextEditingController _studentNameCtrl = TextEditingController();
  final TextEditingController _symptomCtrl = TextEditingController();
  final TextEditingController _diagnosisCtrl = TextEditingController();
  final TextEditingController _medicineCtrl = TextEditingController();
  
  bool _isReferredToLeave = false;

  void _openAddRecordModal() {
    _studentNameCtrl.clear();
    _symptomCtrl.clear();
    _diagnosisCtrl.clear();
    _medicineCtrl.clear();
    _isReferredToLeave = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                      const Text(
                        'Catat Rekam Medis Santri (UKS)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                      ),
                      const SizedBox(height: 20),

                      // Student
                      const Text('Nama Santri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _studentNameCtrl,
                        decoration: const InputDecoration(hintText: 'Cari atau tulis nama...'),
                      ),
                      const SizedBox(height: 16),

                      // Symptom
                      const Text('Gejala / Keluhan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _symptomCtrl,
                        decoration: const InputDecoration(hintText: 'Demam tinggi, pusing...'),
                      ),
                      const SizedBox(height: 16),

                      // Diagnosis
                      const Text('Diagnosis Penyakit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _diagnosisCtrl,
                        decoration: const InputDecoration(hintText: 'Gejala Typhus / Flu ringan...'),
                      ),
                      const SizedBox(height: 16),

                      // Medicine
                      const Text('Tindakan & Obat Diberikan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _medicineCtrl,
                        decoration: const InputDecoration(hintText: 'Paracetamol 500mg, Istirahat...'),
                      ),
                      const SizedBox(height: 16),

                      // Referral checkbox (Auto sick leave creator)
                      CheckboxListTile(
                        title: const Text(
                          'Rujuk Izin Sakit Otomatis',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                        ),
                        subtitle: const Text(
                          'Memicu pembuatan surat izin sakit di modul Perizinan.',
                          style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                        ),
                        value: _isReferredToLeave,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              _isReferredToLeave = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      // Submit
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_studentNameCtrl.text.isEmpty || _diagnosisCtrl.text.isEmpty) return;

                            globalStateInstance.addMedicalRecord({
                              'id': 'med_${DateTime.now().millisecondsSinceEpoch}',
                              'studentName': _studentNameCtrl.text,
                              'date': DateTime.now().toString().split(' ')[0],
                              'symptom': _symptomCtrl.text,
                              'diagnosis': _diagnosisCtrl.text,
                              'medicine': _medicineCtrl.text,
                              'isReferredToLeave': _isReferredToLeave,
                            });

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _isReferredToLeave
                                      ? 'Rekam medis disimpan & izin sakit otomatis berhasil diajukan!'
                                      : 'Rekam medis UKS berhasil disimpan!',
                                ),
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
                          child: const Text('Simpan Rekam Medis', style: TextStyle(fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Kesehatan & UKS', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: ListenableBuilder(
        listenable: globalStateInstance,
        builder: (context, child) {
          final list = globalStateInstance.medicalRecords;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Jurnal Kesehatan UKS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: _openAddRecordModal,
                      icon: const Icon(Icons.add_circle, size: 16),
                      label: const Text('Catat Sakit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? const Center(child: Text('Tidak ada riwayat medis terdaftar.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: list.length,
                        itemBuilder: (context, idx) {
                          final med = list[idx];
                          final hasReferral = med['isReferredToLeave'] == true;

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
                                      Text(med['studentName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      Text(med['date'], style: const TextStyle(fontSize: 10, color: AppColors.outline)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text('Gejala: ${med['symptom']}', style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                                  Text('Diagnosis: ${med['diagnosis']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  Text('Tindakan/Obat: ${med['medicine']}', style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                                  if (hasReferral) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.assignment_turned_in, size: 10, color: Colors.red),
                                          SizedBox(width: 4),
                                          Text('Rujukan Izin Sakit Aktif', style: TextStyle(color: Colors.red, fontSize: 8, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    )
                                  ]
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              )
            ],
          );
        },
      ),
    );
  }
}
