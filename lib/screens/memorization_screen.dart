import 'package:flutter/material.dart';
import '../constants/colors.dart';

class MemorizationScreen extends StatefulWidget {
  const MemorizationScreen({super.key});

  @override
  State<MemorizationScreen> createState() => _MemorizationScreenState();
}

class _MemorizationScreenState extends State<MemorizationScreen> {
  // Form values
  final TextEditingController _searchCtrl = TextEditingController(text: 'Ahmad Fulan');
  final TextEditingController _ayatDariCtrl = TextEditingController(text: '1');
  final TextEditingController _ayatSampaiCtrl = TextEditingController(text: '10');
  String _selectedDate = '2023-10-27';
  String _selectedType = 'Ziyadah';
  String _selectedSurah = 'Al-Baqarah';
  String _selectedJuz = '1';

  // Evaluation ratings
  String _kelancaran = 'Baik';
  String _tajwid = 'Sangat Baik';
  String _makharijul = 'Perlu Latihan';

  bool _isStudentSelected = true;

  void _saveSetoran() {
    // Show a floating custom toast
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 80,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: AppColors.primaryFixed, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Setoran Ahmad Fulan berhasil disimpan!',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Remove toast after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
      if (mounted) {
        Navigator.pop(context);
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
          'Tambah Setoran',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Selection Card
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pilih Santri', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Cari nama santri...',
                      prefixIcon: Icon(Icons.search, color: AppColors.outline),
                      fillColor: AppColors.surface,
                    ),
                    onChanged: (val) {
                      setState(() {
                        _isStudentSelected = val.isNotEmpty;
                      });
                    },
                  ),
                  if (_isStudentSelected) ...[
                    const SizedBox(height: 12),
                    // Mock Dropdown suggestion
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
                      ),
                      child: const Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.secondaryContainer,
                            child: Text(
                              'A',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ahmad Fulan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                Text(
                                  'Kelas 10A • Hafalan: 5 Juz',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Session Details Card
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tanggal Setoran', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant, fontSize: 14)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.parse(_selectedDate),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDate = date.toString().split(' ')[0];
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_selectedDate, style: const TextStyle(fontSize: 14, color: AppColors.onSurface)),
                          const Icon(Icons.calendar_today, color: AppColors.outline, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Jenis Setoran', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildToggleChip('Ziyadah', _selectedType == 'Ziyadah', () {
                        setState(() => _selectedType = 'Ziyadah');
                      }),
                      const SizedBox(width: 8),
                      _buildToggleChip('Murajaah', _selectedType == 'Murajaah', () {
                        setState(() => _selectedType = 'Murajaah');
                      }),
                      const SizedBox(width: 8),
                      _buildToggleChip("Tasmi'", _selectedType == "Tasmi'", () {
                        setState(() => _selectedType = "Tasmi'");
                      }),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Target Details Card
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Surah', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant, fontSize: 14)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedSurah,
                    decoration: const InputDecoration(fillColor: AppColors.surface),
                    items: ['Al-Baqarah', "Ali 'Imran", 'An-Nisa'].map((s) {
                      return DropdownMenuItem(value: s, child: Text(s));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedSurah = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ayat Dari', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant, fontSize: 14)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _ayatDariCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(fillColor: AppColors.surface),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Sampai', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant, fontSize: 14)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _ayatSampaiCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(fillColor: AppColors.surface),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Juz', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant, fontSize: 14)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedJuz,
                    decoration: const InputDecoration(fillColor: AppColors.surface),
                    items: ['1', '2', '3'].map((j) {
                      return DropdownMenuItem(value: j, child: Text(j));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedJuz = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Evaluation Card
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Penilaian',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildEvaluationRow('Kelancaran', _kelancaran, (val) {
                    setState(() => _kelancaran = val);
                  }),
                  const SizedBox(height: 16),
                  _buildEvaluationRow('Tajwid', _tajwid, (val) {
                    setState(() => _tajwid = val);
                  }),
                  const SizedBox(height: 16),
                  _buildEvaluationRow('Makharijul Huruf', _makharijul, (val) {
                    setState(() => _makharijul = val);
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSetoran,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Simpan Setoran',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildToggleChip(String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primaryContainer : AppColors.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildEvaluationRow(String label, String activeVal, ValueChanged<String> onChanged) {
    final List<String> options = ['Perlu Latihan', 'Baik', 'Sangat Baik'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant),
            ),
            const Text(
              'Pilih satu',
              style: TextStyle(fontSize: 11, color: AppColors.outline),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: options.map((opt) {
            final bool isSelected = opt == activeVal;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: opt != options.last ? 8.0 : 0.0),
                child: InkWell(
                  onTap: () => onChanged(opt),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryContainer : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryContainer : AppColors.outlineVariant,
                      ),
                    ),
                    child: Text(
                      opt,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
