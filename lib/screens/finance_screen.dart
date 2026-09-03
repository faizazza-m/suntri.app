import 'package:flutter/material.dart';
import '../constants/colors.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  // Bottom Sheet controller values
  final TextEditingController _modalSantriName = TextEditingController();
  final TextEditingController _modalTagihanType = TextEditingController();
  final TextEditingController _modalNominal = TextEditingController();
  final TextEditingController _modalNotes = TextEditingController();
  String _selectedDate = '2023-10-24';
  String _selectedMethod = 'Transfer Bank (BSI)';

  void _openPaymentModal({
    required String name,
    required String type,
    required String amount,
  }) {
    setState(() {
      _modalSantriName.text = name;
      _modalTagihanType.text = type;
      _modalNominal.text = amount;
      _modalNotes.clear();
      _selectedDate = '2023-10-24';
      _selectedMethod = 'Transfer Bank (BSI)';
    });

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
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
                  'Catat Pembayaran',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const Text(
                  'Lengkapi data pembayaran santri.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),

                // Santri Name (Disabled/Read-only)
                const Text('Nama Santri', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _modalSantriName,
                  enabled: false,
                  decoration: InputDecoration(
                    fillColor: Colors.grey.shade100,
                  ),
                ),
                const SizedBox(height: 16),

                // Tagihan Type (Disabled/Read-only)
                const Text('Jenis Tagihan', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _modalTagihanType,
                  enabled: false,
                  decoration: InputDecoration(
                    fillColor: Colors.grey.shade100,
                  ),
                ),
                const SizedBox(height: 16),

                // Nominal
                const Text('Nominal (Rp)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _modalNominal,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  decoration: const InputDecoration(fillColor: AppColors.surfaceContainerLowest),
                ),
                const SizedBox(height: 16),

                // Date
                const Text('Tanggal Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant, fontSize: 13)),
                const SizedBox(height: 6),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_selectedDate, style: const TextStyle(fontSize: 14)),
                        const Icon(Icons.calendar_today, size: 20, color: AppColors.outline),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Method
                const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedMethod,
                  decoration: const InputDecoration(fillColor: AppColors.surfaceContainerLowest),
                  items: ['Transfer Bank (BSI)', 'Transfer Bank (Mandiri)', 'Tunai (Kasir)', 'Virtual Account'].map((m) {
                    return DropdownMenuItem(value: m, child: Text(m));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedMethod = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Notes
                const Text('Catatan (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _modalNotes,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Tambahkan catatan...',
                    fillColor: AppColors.surfaceContainerLowest,
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
                          side: const BorderSide(color: AppColors.outline),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pembayaran berhasil dicatat!'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Simpan',
                              style: TextStyle(fontWeight: FontWeight.bold),
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
          'Manajemen Keuangan',
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
            // Page Context
            const Text(
              'Manajemen Keuangan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onSurface),
            ),
            const Text(
              'Ringkasan tagihan dan pembayaran bulan ini.',
              style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),

            // Top Stats (Bento Grid Style)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.4,
              children: [
                // Total Tagihan
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TOTAL TAGIHAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant)),
                          Icon(Icons.account_balance_wallet, color: AppColors.primary, size: 20),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rp 125M', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                          Text('Bulan Ini', style: TextStyle(fontSize: 11, color: AppColors.tertiaryFixedDim, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Pendapatan
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('PENDAPATAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryFixed)),
                          Icon(Icons.trending_up, color: AppColors.primaryFixed, size: 20),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rp 85M', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('+12% vs bulan lalu', style: TextStyle(fontSize: 11, color: AppColors.primaryFixedDim, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Sudah Dibayar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(radius: 4, backgroundColor: AppColors.tertiaryFixedDim),
                          SizedBox(width: 8),
                          Text('SUDAH DIBAYAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('342', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                          SizedBox(width: 4),
                          Text('Santri', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Belum Dibayar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.errorContainer),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(radius: 4, backgroundColor: AppColors.error),
                          SizedBox(width: 8),
                          Text('BELUM DIBAYAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onErrorContainer)),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('128', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.onErrorContainer)),
                          SizedBox(width: 4),
                          Text('Santri', style: TextStyle(fontSize: 12, color: AppColors.onErrorContainer)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Tagihan List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daftar Tagihan',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.filter_list, size: 18),
                  label: const Text('Filter'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Card 1 (Belum Bayar)
            _buildTagihanCard(
              name: 'Ahmad Rasyid',
              nis: 'NIS: 2023001 • Kelas 10A',
              status: 'Belum Bayar',
              statusBg: AppColors.secondaryContainer.withOpacity(0.2),
              statusText: AppColors.secondaryContainer,
              jenisTagihan: 'SPP Bulanan',
              periode: 'Okt 2023',
              nominal: 'Rp 450.000',
              hasLeftStrip: false,
              actionButton: ElevatedButton.icon(
                onPressed: () => _openPaymentModal(
                  name: 'Ahmad Rasyid',
                  type: 'SPP Bulanan',
                  amount: '450000',
                ),
                icon: const Icon(Icons.payments, size: 16),
                label: const Text('Catat Pembayaran'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Card 2 (Jatuh Tempo)
            _buildTagihanCard(
              name: 'Siti Aminah',
              nis: 'NIS: 2023042 • Kelas 11B',
              status: 'Jatuh Tempo',
              statusBg: AppColors.errorContainer,
              statusText: AppColors.error,
              jenisTagihan: 'Uang Pangkal',
              periode: 'Thn Ajaran 23/24',
              nominal: 'Rp 2.500.000',
              hasLeftStrip: true,
              actionButton: ElevatedButton.icon(
                onPressed: () => _openPaymentModal(
                  name: 'Siti Aminah',
                  type: 'Uang Pangkal',
                  amount: '2500000',
                ),
                icon: const Icon(Icons.payments, size: 16),
                label: const Text('Catat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Card 3 (Lunas - View Only)
            Opacity(
              opacity: 0.75,
              child: _buildTagihanCard(
                name: 'Budi Santoso',
                nis: 'NIS: 2023015 • Kelas 10A',
                status: 'Lunas',
                statusBg: AppColors.tertiaryFixedDim.withOpacity(0.2),
                statusText: AppColors.tertiaryContainer,
                jenisTagihan: 'SPP Bulanan',
                periode: 'Okt 2023',
                nominal: 'Rp 450.000',
                hasLeftStrip: false,
                actionButton: const Text(
                  'Tgl: 05 Okt',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.outline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagihanCard({
    required String name,
    required String nis,
    required String status,
    required Color statusBg,
    required Color statusText,
    required String jenisTagihan,
    required String periode,
    required String nominal,
    required bool hasLeftStrip,
    required Widget actionButton,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasLeftStrip ? AppColors.error.withOpacity(0.5) : AppColors.outlineVariant,
          width: hasLeftStrip ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            if (hasLeftStrip)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  color: AppColors.error,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          Text(
                            nis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusText,
                          ),
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
                            const Text('Jenis Tagihan', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(jenisTagihan, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Periode', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(periode, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.only(top: 16),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.outlineVariant, width: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Nominal', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              nominal,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: hasLeftStrip ? AppColors.error : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        actionButton,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
