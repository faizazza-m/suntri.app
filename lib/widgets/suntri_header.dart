import 'package:flutter/material.dart';
import '../screens/dashboards/admin_dashboard.dart';

class SUNTRIHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final String initials;
  final VoidCallback? onLogout;

  const SUNTRIHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.initials,
    this.onLogout,
  });

  @override
  Size get preferredSize => const Size.fromHeight(140);

  void _showProfileModal(BuildContext context) {
    // Load real contact data from logged-in user
    final currentUser = globalStateInstance.currentUser;
    final String email = currentUser?['email'] ?? '';
    final String phone = currentUser?['phone'] ?? '';
    bool showPasswordFields = false;
    
    final emailController = TextEditingController(text: email);
    final phoneController = TextEditingController(text: phone);
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 10,
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 20),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header of modal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Profil & Pengaturan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Plus Jakarta Sans',
                            color: Color(0xFF004D40),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(),
                    
                    // Scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            // Big Avatar
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF004D40).withOpacity(0.15),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 36,
                                backgroundColor: const Color(0xFF004D40).withOpacity(0.1),
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF004D40),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Name
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Subtitle/Role
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF81C784).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                subtitle,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF004D40),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Info static rows
                            _buildInfoRow(Icons.domain, 'Pesantren', "Ma'had Tahfidz Rijaalul Quran"),
                            const SizedBox(height: 8),
                            _buildInfoRow(Icons.security, 'Status Akun', 'Aktif'),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 12),
                            
                            // Input fields section
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Data Kontak',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF004D40),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Email Field
                            TextField(
                              controller: emailController,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Alamat Email',
                                labelStyle: const TextStyle(fontSize: 13, color: Colors.black54),
                                prefixIcon: const Icon(Icons.email_outlined, size: 18, color: Color(0xFF004D40)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Color(0xFF004D40), width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Phone Field
                            TextField(
                              controller: phoneController,
                              style: const TextStyle(fontSize: 14),
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Nomor Telepon',
                                labelStyle: const TextStyle(fontSize: 13, color: Colors.black54),
                                prefixIcon: const Icon(Icons.phone_outlined, size: 18, color: Color(0xFF004D40)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Color(0xFF004D40), width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Expandable Password Section
                            InkWell(
                              onTap: () {
                                setState(() {
                                  showPasswordFields = !showPasswordFields;
                                });
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: showPasswordFields ? const Color(0xFF004D40).withOpacity(0.05) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: showPasswordFields ? const Color(0xFF004D40).withOpacity(0.2) : Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.lock_outline, size: 20, color: showPasswordFields ? const Color(0xFF004D40) : Colors.grey.shade700),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Ubah Kata Sandi',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: showPasswordFields ? const Color(0xFF004D40) : Colors.grey.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Icon(
                                      showPasswordFields ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                      size: 22,
                                      color: showPasswordFields ? const Color(0xFF004D40) : Colors.grey.shade600,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            if (showPasswordFields) ...[
                              const SizedBox(height: 12),
                              TextField(
                                controller: oldPasswordController,
                                style: const TextStyle(fontSize: 14),
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'Kata Sandi Lama',
                                  labelStyle: const TextStyle(fontSize: 13, color: Colors.black54),
                                  prefixIcon: const Icon(Icons.lock_open, size: 18, color: Colors.grey),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Color(0xFF004D40), width: 1.5),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: newPasswordController,
                                style: const TextStyle(fontSize: 14),
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'Kata Sandi Baru',
                                  labelStyle: const TextStyle(fontSize: 13, color: Colors.black54),
                                  prefixIcon: const Icon(Icons.lock_outline, size: 18, color: Colors.grey),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Color(0xFF004D40), width: 1.5),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: confirmPasswordController,
                                style: const TextStyle(fontSize: 14),
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'Konfirmasi Kata Sandi Baru',
                                  labelStyle: const TextStyle(fontSize: 13, color: Colors.black54),
                                  prefixIcon: const Icon(Icons.check_circle_outline, size: 18, color: Colors.grey),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Color(0xFF004D40), width: 1.5),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    
                    const Divider(),
                    const SizedBox(height: 8),
                    // Action Buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.red.shade400, width: 1.5),
                              foregroundColor: Colors.red.shade600,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              if (onLogout != null) {
                                onLogout!();
                              }
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.logout, size: 16),
                                SizedBox(width: 6),
                                Text('Keluar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF004D40),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () async {
                              // Perform validation and saving
                              final updatedEmail = emailController.text.trim();
                              final updatedPhone = phoneController.text.trim();
                              
                              if (updatedEmail.isEmpty || updatedPhone.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Email dan No. Telepon tidak boleh kosong!'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              String? newPwToSave;
                              if (showPasswordFields) {
                                final oldPw = oldPasswordController.text;
                                final newPw = newPasswordController.text;
                                final confPw = confirmPasswordController.text;
                                
                                if (oldPw.isEmpty || newPw.isEmpty || confPw.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Semua kolom kata sandi harus diisi!'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                
                                if (newPw != confPw) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Konfirmasi kata sandi baru tidak cocok!'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                newPwToSave = newPw;
                              }
                              
                              // Show saving indicator if we had one, but for now just await
                              final messenger = ScaffoldMessenger.of(context);
                              final currentUser = globalStateInstance.currentUser;
                              
                              if (currentUser == null || currentUser['id'] == null) return;
                              
                              final success = await globalStateInstance.updateProfile(
                                currentUser['id'].toString(), 
                                updatedEmail, 
                                updatedPhone,
                                newPassword: newPwToSave,
                              );
                              
                              if (!context.mounted) return;
                              Navigator.of(context).pop();
                              
                              if (success) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Perubahan profil berhasil disimpan!'),
                                    backgroundColor: Color(0xFF004D40),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } else {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Gagal menyimpan profil, coba lagi nanti.'),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save, size: 16),
                                SizedBox(width: 6),
                                Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _getIndonesianDate() {
    final now = DateTime.now();
    final days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    
    final dayName = days[now.weekday - 1];
    final monthName = months[now.month - 1];
    
    return '$dayName, ${now.day} $monthName ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: HeaderClipper(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF004D40), // Forest green
              Color(0xFF002D24), // Deeper forest green
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 42),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          color: Color(0xFF81C784), // Light green tint
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getIndonesianDate(),
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                // Circular avatar
                GestureDetector(
                  onTap: () => _showProfileModal(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF81C784).withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.12),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);
    // Smooth quadratic curve from (0, height-30) to (width, height-30) curving down to (width/2, height)
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 30,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
