import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../dashboards/admin_dashboard.dart'; // To access globalStateInstance

class LogAktivitasScreen extends StatefulWidget {
  const LogAktivitasScreen({super.key});

  @override
  State<LogAktivitasScreen> createState() => _LogAktivitasScreenState();
}

class _LogAktivitasScreenState extends State<LogAktivitasScreen> {
  String _activeFilter = 'Semua';

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
          'Log Aktivitas Terintegrasi',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: ListenableBuilder(
        listenable: globalStateInstance,
        builder: (context, child) {
          // Filter logs
          final filteredLogs = globalStateInstance.activities.where((act) {
            if (_activeFilter == 'Semua') return true;
            return act['type'].toString().toLowerCase() == _activeFilter.toLowerCase();
          }).toList();

          return Column(
            children: [
              // Filter Horizontal Scrollbar
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: Colors.white,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: ['Semua', 'Kehadiran', 'Tahfizh', 'Perizinan', 'UKS', 'Keuangan'].map((filter) {
                      final isSelected = _activeFilter == filter;
                      Color itemColor = AppColors.primary;
                      if (filter == 'Tahfizh') itemColor = Colors.orange;
                      if (filter == 'Perizinan') itemColor = Colors.purple;
                      if (filter == 'UKS') itemColor = Colors.red;
                      if (filter == 'Keuangan') itemColor = Colors.blue;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: itemColor,
                          backgroundColor: AppColors.surfaceContainer,
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _activeFilter = filter;
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Log Feed List
              Expanded(
                child: filteredLogs.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada log aktivitas untuk kategori ini.',
                          style: TextStyle(color: AppColors.outline, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredLogs.length,
                        itemBuilder: (context, idx) {
                          final log = filteredLogs[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.outlineVariant.withOpacity(0.4)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.01),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 4,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: log['color'] as Color,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: (log['color'] as Color).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              log['tag'],
                                              style: TextStyle(
                                                color: log['color'] as Color,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            log['time'],
                                            style: const TextStyle(fontSize: 10, color: AppColors.outline),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        log['title'],
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.onBackground),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        log['description'],
                                        style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant, height: 1.3),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
