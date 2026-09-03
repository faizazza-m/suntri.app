import 'package:flutter/material.dart';
import '../constants/colors.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  String? _selectedStudent = '1'; // Ahmad Zidan
  String _permissionType = 'sakit';
  DateTime _startDate = DateTime.parse('2023-10-25');
  DateTime _endDate = DateTime.parse('2023-10-26');
  final TextEditingController _reasonCtrl = TextEditingController();
  final TextEditingController _emergencyContactCtrl = TextEditingController();

  int get _durationDays {
    return _endDate.difference(_startDate).inDays + 1;
  }

  void _showSuccessDialog() {
    final String studentName = _selectedStudent == '1' ? 'Ahmad Zidan' : 'Fatimah Az-Zahra';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: AppColors.surface,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD1FAE5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pengajuan Berhasil',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Permohonan izin untuk $studentName telah dikirim dan sedang menunggu persetujuan dari Musyrif.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Close screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD1FAE5),
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ajukan Izin',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ajukan Izin',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onBackground),
              ),
              const SizedBox(height: 4),
              const Text(
                'Isi formulir di bawah ini untuk mengajukan izin ketidakhadiran santri.',
                style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 24),

              // Student selection
              const Text('Pilih Santri', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onBackground, fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedStudent,
                decoration: const InputDecoration(fillColor: AppColors.surface),
                items: const [
                  DropdownMenuItem(value: '1', child: Text('Ahmad Zidan (Kelas 10A)')),
                  DropdownMenuItem(value: '2', child: Text('Fatimah Az-Zahra (Kelas 8B)')),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedStudent = val;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Permission Type
              const Text('Jenis Izin', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onBackground, fontSize: 14)),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: [
                  _buildTypeRadioCard('Pulang', 'pulang', Icons.home),
                  _buildTypeRadioCard('Sakit', 'sakit', Icons.sick),
                  _buildTypeRadioCard('Keluarga', 'keluarga', Icons.family_restroom),
                  _buildTypeRadioCard('Lainnya', 'lainnya', Icons.more_horiz),
                ],
              ),
              const SizedBox(height: 20),

              // Dates
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mulai', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onBackground, fontSize: 14)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _startDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              setState(() {
                                _startDate = date;
                                if (_endDate.isBefore(_startDate)) {
                                  _endDate = _startDate;
                                }
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.outlineVariant),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${_startDate.day}/${_startDate.month}/${_startDate.year}', style: const TextStyle(fontSize: 14)),
                                const Icon(Icons.calendar_today, size: 16, color: AppColors.outline),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Selesai', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onBackground, fontSize: 14)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _endDate,
                              firstDate: _startDate,
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              setState(() {
                                _endDate = date;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.outlineVariant),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${_endDate.day}/${_endDate.month}/${_endDate.year}', style: const TextStyle(fontSize: 14)),
                                const Icon(Icons.calendar_today, size: 16, color: AppColors.outline),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Duration summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.schedule, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Durasi: $_durationDays Hari',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Reason
              const Text('Alasan', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onBackground, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Tuliskan alasan izin secara detail...',
                  fillColor: AppColors.surface,
                ),
              ),
              const SizedBox(height: 20),

              // Emergency Contact
              const Text('Kontak Darurat selama Izin', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onBackground, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _emergencyContactCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '0812-XXXX-XXXX',
                  fillColor: AppColors.surface,
                ),
              ),
              const SizedBox(height: 20),

              // File upload widget (mocked)
              const Text('Dokumen Pendukung (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onBackground, fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.outlineVariant, style: BorderStyle.none),
                ),
                child: InkWell(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.outlineVariant, style: BorderStyle.solid),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.cloud_upload, color: AppColors.onSurfaceVariant, size: 32),
                        SizedBox(height: 8),
                        Text(
                          'Unggah Surat Dokter / Bukti lainnya',
                          style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.normal),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Maks. 5MB (JPG, PNG, PDF)',
                          style: TextStyle(fontSize: 12, color: AppColors.outline),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Action
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showSuccessDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Ajukan Izin',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeRadioCard(String label, String value, IconData icon) {
    final bool isSelected = _permissionType == value;
    return InkWell(
      onTap: () {
        setState(() {
          _permissionType = value;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.onPrimaryContainer : AppColors.onSurface,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.onPrimaryContainer : AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
