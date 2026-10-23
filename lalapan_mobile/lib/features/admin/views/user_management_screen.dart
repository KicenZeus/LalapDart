import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _users = [];
  List<dynamic> _institutions = [];
  String? _selectedRoleFilter;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInstitutions();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInstitutions() async {
    try {
      final res = await _apiClient.dio.get('/institutions');
      if (mounted) {
        setState(() => _institutions = res.data['data'] ?? []);
      }
    } catch (_) {}
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> params = {};
      if (_selectedRoleFilter != null) params['role'] = _selectedRoleFilter;
      if (_searchCtrl.text.trim().isNotEmpty) params['search'] = _searchCtrl.text.trim();

      final res = await _apiClient.dio.get('/users', queryParameters: params);
      if (mounted) {
        setState(() {
          _users = res.data['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat pengguna: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Toggle Status Aktif / Nonaktif
  Future<void> _toggleUserActive(String userId, String username, bool currentStatus) async {
    try {
      await _apiClient.dio.patch('/users/$userId/toggle-active');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status pengguna $username berhasil diubah menjadi ${!currentStatus ? "Aktif" : "Nonaktif"}'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Dialog Reset Password
  Future<void> _showResetPasswordDialog(String userId, String username) async {
    final passCtrl = TextEditingController(text: 'Password123!');
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Reset Kata Sandi: $username', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Masukkan kata sandi baru untuk akun ini (minimal 6 karakter):', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                decoration: const InputDecoration(labelText: 'Kata Sandi Baru *', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => navigator.pop(), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
              onPressed: () async {
                if (passCtrl.text.trim().length < 6) return;
                try {
                  await _apiClient.dio.post(
                    '/users/$userId/reset-password',
                    data: {'newPassword': passCtrl.text.trim()},
                  );
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(content: Text('Kata sandi untuk $username berhasil direset!'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Gagal reset password: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Reset Sandi'),
            ),
          ],
        );
      },
    );
  }

  /// Dialog Tambah Pengguna Baru
  Future<void> _showCreateUserDialog() async {
    final formKey = GlobalKey<FormState>();
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController(text: 'Bidan123!');
    final fullNameCtrl = TextEditingController();
    String role = 'OPERATOR_RS';
    String? selectedInstId;
    final nipCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              title: const Text('Tambah Pengguna Baru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: usernameCtrl,
                          decoration: const InputDecoration(labelText: 'Username *', border: OutlineInputBorder()),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: passwordCtrl,
                          decoration: const InputDecoration(labelText: 'Password Awal *', border: OutlineInputBorder()),
                          validator: (v) => v == null || v.trim().length < 6 ? 'Minimal 6 karakter' : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: fullNameCtrl,
                          decoration: const InputDecoration(labelText: 'Nama Lengkap & Gelar *', border: OutlineInputBorder()),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: role,
                          decoration: const InputDecoration(labelText: 'Peran / Role *', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'OPERATOR_RS', child: Text('Operator Faskes (Bidan / RS)')),
                            DropdownMenuItem(value: 'OPERATOR_DUKCAPIL', child: Text('Verifikator Disdukcapil')),
                            DropdownMenuItem(value: 'ADMIN', child: Text('Super Admin')),
                          ],
                          onChanged: (v) => setDlgState(() => role = v ?? 'OPERATOR_RS'),
                        ),
                        if (role == 'OPERATOR_RS') ...[
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String?>(
                            isExpanded: true,
                            initialValue: selectedInstId,
                            decoration: const InputDecoration(labelText: 'Pilih Instansi Faskes *', border: OutlineInputBorder()),
                            items: [
                              for (final inst in _institutions)
                                DropdownMenuItem(
                                  value: inst['id']?.toString(),
                                  child: Text(inst['name'] ?? '', overflow: TextOverflow.ellipsis),
                                ),
                            ],
                            validator: (v) => v == null ? 'Faskes wajib dipilih' : null,
                            onChanged: (v) => setDlgState(() => selectedInstId = v),
                          ),
                        ],
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: nipCtrl,
                          decoration: const InputDecoration(labelText: 'NIP (Opsional)', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: emailCtrl,
                          decoration: const InputDecoration(labelText: 'Email (Opsional)', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: phoneCtrl,
                          decoration: const InputDecoration(labelText: 'Nomor WhatsApp / HP', border: OutlineInputBorder()),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => navigator.pop(), child: const Text('Batal')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    try {
                      await _apiClient.dio.post(
                        '/users',
                        data: {
                          'username': usernameCtrl.text.trim(),
                          'password': passwordCtrl.text.trim(),
                          'fullName': fullNameCtrl.text.trim(),
                          'role': role,
                          'institutionId': role == 'OPERATOR_RS' ? selectedInstId : null,
                          'nip': nipCtrl.text.trim().isEmpty ? null : nipCtrl.text.trim(),
                          'email': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                        },
                      );
                      navigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Pengguna baru berhasil ditambahkan!'), backgroundColor: Colors.green),
                      );
                      await _loadUsers();
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Gagal menambah pengguna: $e'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: const Text('Simpan Pengguna'),
                ),
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Manajemen Akun Pengguna', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Tambah Pengguna',
            onPressed: _showCreateUserDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Bar
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Cari username / nama lengkap / email...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onSubmitted: (_) => _loadUsers(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onPressed: _loadUsers,
                        child: const Text('Cari'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: _selectedRoleFilter,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      labelText: 'Filter Peran (Role)',
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Semua Role Pengguna')),
                      DropdownMenuItem(value: 'OPERATOR_RS', child: Text('Operator Faskes (Bidan/Petugas RS)')),
                      DropdownMenuItem(value: 'OPERATOR_DUKCAPIL', child: Text('Verifikator Disdukcapil')),
                      DropdownMenuItem(value: 'ADMIN', child: Text('Super Admin')),
                    ],
                    onChanged: (v) {
                      setState(() => _selectedRoleFilter = v);
                      _loadUsers();
                    },
                  ),
                ],
              ),
            ),

            // Users List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _users.isEmpty
                      ? const Center(child: Text('Tidak ada pengguna ditemukan.', style: TextStyle(color: Colors.grey)))
                      : RefreshIndicator(
                          onRefresh: _loadUsers,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: _users.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final u = _users[index];
                              final isActive = u['is_active'] == true;
                              final roleStr = u['role']?.toString() ?? '';

                              Color roleColor = Colors.blue;
                              if (roleStr == 'OPERATOR_DUKCAPIL') roleColor = Colors.indigo;
                              if (roleStr == 'ADMIN') roleColor = Colors.purple;

                              return Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: roleColor.withAlpha(38),
                                        foregroundColor: roleColor,
                                        child: Text(
                                          (u['full_name'] ?? 'U')[0].toUpperCase(),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    u['full_name'] ?? '-',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: roleColor.withAlpha(25),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    roleStr.replaceAll('_', ' '),
                                                    style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text('@${u['username']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                            if (u['institution_name'] != null)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 2.0),
                                                child: Text('Instansi: ${u['institution_name']}',
                                                    style: const TextStyle(fontSize: 11, color: Colors.black87)),
                                              ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Text(
                                                  isActive ? 'Status: Aktif' : 'Status: Nonaktif (Suspended)',
                                                  style: TextStyle(
                                                    color: isActive ? Colors.green.shade700 : Colors.red,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Switch(
                                                  value: isActive,
                                                  activeThumbColor: Colors.green,
                                                  onChanged: (_) => _toggleUserActive(u['id'], u['username'], isActive),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.key, size: 18, color: Colors.grey),
                                                  tooltip: 'Reset Password',
                                                  onPressed: () => _showResetPasswordDialog(u['id'], u['username']),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah User'),
        onPressed: _showCreateUserDialog,
      ),
    );
  }
}
