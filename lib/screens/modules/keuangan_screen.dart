import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../dashboards/admin_dashboard.dart'; // To access globalStateInstance

class KeuanganScreen extends StatefulWidget {
  const KeuanganScreen({super.key});

  @override
  State<KeuanganScreen> createState() => _KeuanganScreenState();
}

class _KeuanganScreenState extends State<KeuanganScreen> {
  // Generate Form Fields
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _periodCtrl = TextEditingController(text: 'November 2023');
  String _selectedBillType = 'SPP Bulanan';
  String _targetScope = 'Semua Santri'; // Semua Santri, Per Kelas, Individu
  String _selectedClass = '10A MIPA';
  String? _selectedStudent;

  // Pay Form Fields
  final TextEditingController _modalNominal = TextEditingController();
  final TextEditingController _modalNotes = TextEditingController();
  String _selectedMethod = 'Transfer Bank (BSI)';
  String _selectedDate = '2023-10-27';

  void _openPaymentModal(Map<String, dynamic> bill) {
    // Protection: Block paying/editing bills that are already paid
    if (bill['status'] == 'Lunas') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proteksi Keuangan: Tagihan ini sudah lunas dan tidak dapat diubah!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _modalNominal.text = bill['amount'].toString();
    _modalNotes.clear();
    _selectedMethod = 'Transfer Bank (BSI)';
    _selectedDate = DateTime.now().toString().split(' ')[0];

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
                      Text(
                        'Catat Pembayaran: ${bill['studentName']}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.onBackground),
                      ),
                      Text('Tagihan: ${bill['type']} (${bill['period']})', style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 20),

                      // Nominal
                      const Text('Nominal Pembayaran (Rp)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _modalNominal,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(fillColor: AppColors.surfaceContainerLowest),
                      ),
                      const SizedBox(height: 16),

                      // Method
                      const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedMethod,
                        decoration: const InputDecoration(fillColor: AppColors.surfaceContainerLowest),
                        items: ['Transfer Bank (BSI)', 'Transfer Bank (Mandiri)', 'Tunai (Kasir)', 'Virtual Account'].map((m) {
                          return DropdownMenuItem(value: m, child: Text(m));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              _selectedMethod = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Date picker style trigger
                      const Text('Tanggal Bayar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                            setModalState(() {
                              _selectedDate = date.toString().split(' ')[0];
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.outlineVariant),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_selectedDate),
                              const Icon(Icons.calendar_today, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Notes
                      const Text('Catatan Tambahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _modalNotes,
                        maxLines: 2,
                        decoration: const InputDecoration(hintText: 'Masukkan catatan...', fillColor: AppColors.surfaceContainerLowest),
                      ),
                      const SizedBox(height: 24),

                      // Save action
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final nominalVal = double.tryParse(_modalNominal.text) ?? 0;
                            if (nominalVal <= 0) return;

                            globalStateInstance.payBill(
                              billId: bill['id'],
                              nominal: nominalVal,
                              method: _selectedMethod,
                              notes: _modalNotes.text,
                              date: _selectedDate,
                            );

                            Navigator.pop(context);
                            _showInvoiceReceipt(bill['id']);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Simpan Pembayaran & Cetak Resi', style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _showInvoiceReceipt(String billId) {
    // Query paid bill
    final bill = globalStateInstance.bills.firstWhere((b) => b['id'] == billId);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('KUITANSI PEMBAYARAN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'e-Invoice Resmi Suntri',
                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.outline),
                ),
              ),
              const Divider(thickness: 1.5),
              const SizedBox(height: 8),
              _buildReceiptRow('Nama Santri:', bill['studentName']),
              _buildReceiptRow('Jenis Tagihan:', bill['type']),
              _buildReceiptRow('Periode:', bill['period']),
              _buildReceiptRow('Metode Pembayaran:', bill['method'] ?? '-'),
              _buildReceiptRow('Tanggal Lunas:', bill['datePaid'] ?? '-'),
              const Divider(),
              _buildReceiptRow('JUMLAH BAYAR:', 'Rp ${bill['amount']}', isBold: true),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'STATUS: LUNAS - SAH',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12),
                  ),
                ),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String val, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          Text(val, style: TextStyle(fontSize: 11, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
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
          title: const Text('Manajemen Keuangan', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0.5,
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.outline,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Daftar Tagihan'),
              Tab(text: 'Generate Tagihan'),
            ],
          ),
        ),
        body: ListenableBuilder(
          listenable: globalStateInstance,
          builder: (context, child) {
            return TabBarView(
              children: [
                _buildDaftarTagihanTab(),
                _buildGenerateTagihanTab(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDaftarTagihanTab() {
    final list = globalStateInstance.bills;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final bill = list[idx];
        final isPaid = bill['status'] == 'Lunas';

        return Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(bill['studentName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isPaid ? Colors.green : Colors.red).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              bill['status'],
                              style: TextStyle(color: isPaid ? Colors.green : Colors.red, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('${bill['type']} (${bill['period']})', style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11)),
                      Text('Nominal: Rp ${bill['amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                    ],
                  ),
                ),
                // Lock icon on paid, action button on unpaid
                isPaid
                    ? const Icon(Icons.lock, color: Colors.green, size: 20)
                    : ElevatedButton.icon(
                        onPressed: () => _openPaymentModal(bill),
                        icon: const Icon(Icons.payments, size: 14),
                        label: const Text('Bayar', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenerateTagihanTab() {
    if (_selectedStudent == null && globalStateInstance.students.isNotEmpty) {
      _selectedStudent = globalStateInstance.students[0]['name'];
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Generate Tagihan Baru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),

              // Scope selection
              const Text('Target Tagihan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _targetScope,
                items: ['Semua Santri', 'Per Kelas', 'Individu'].map((scope) {
                  return DropdownMenuItem(value: scope, child: Text(scope));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _targetScope = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              if (_targetScope == 'Per Kelas') ...[
                const Text('Pilih Kelas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedClass,
                  items: ['10A MIPA', '10B IPS', '11B IPS'].map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedClass = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],

              if (_targetScope == 'Individu') ...[
                const Text('Pilih Santri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedStudent,
                  items: globalStateInstance.students.map((s) {
                    return DropdownMenuItem(value: s['name'] as String, child: Text(s['name'] as String));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedStudent = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Bill Type
              const Text('Jenis Tagihan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedBillType,
                items: ['SPP Bulanan', 'Uang Pangkal', 'Uang Seragam', 'Katering'].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedBillType = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Period
              const Text('Periode Tagihan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: _periodCtrl,
                decoration: const InputDecoration(hintText: 'Contoh: November 2023'),
              ),
              const SizedBox(height: 16),

              // Amount
              const Text('Nominal Tagihan (Rp)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: '450000'),
              ),
              const SizedBox(height: 24),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final amountVal = double.tryParse(_amountCtrl.text) ?? 0;
                    if (amountVal <= 0 || _periodCtrl.text.isEmpty || (_targetScope == 'Individu' && _selectedStudent == null)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lengkapi nominal, periode, & sasaran santri!'), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    globalStateInstance.generateBill(
                      type: _selectedBillType,
                      period: _periodCtrl.text,
                      amount: amountVal,
                      targetClass: _targetScope == 'Per Kelas' ? _selectedClass : null,
                      targetStudent: _targetScope == 'Individu' ? _selectedStudent : null,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tagihan baru berhasil digenerate ke santri terkait!'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                    _amountCtrl.clear();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Generate Tagihan', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
