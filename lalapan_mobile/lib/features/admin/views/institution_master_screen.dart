import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';

class InstitutionMasterScreen extends StatefulWidget {
  const InstitutionMasterScreen({super.key});

  @override
  State<InstitutionMasterScreen> createState() => _InstitutionMasterScreenState();
}

class _InstitutionMasterScreenState extends State<InstitutionMasterScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _institutions = [];
  String _selectedType = 'ALL';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInstitutions();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInstitutions() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.dio.get('/institutions');
      if (mounted) {
        setState(() {
          _institutions = res.data['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat faskes: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<dynamic> get _filteredInstitutions {
    final query = _searchCtrl.text.trim().toLowerCase();
    return _institutions.where((item) {
      final type = (item['type'] ?? '').toString().toUpperCase();
      if (_selectedType != 'ALL' && type != _selectedType) {
        return false;
      }
      if (query.isNotEmpty) {
        final name = (item['name'] ?? '').toString().toLowerCase();
        final code = (item['code'] ?? '').toString().toLowerCase();
        final address = (item['address'] ?? '').toString().toLowerCase();
        return name.contains(query) || code.contains(query) || address.contains(query);
      }
      return true;
    }).toList();
  }

  Future<void> _showAddInstitutionDialog() async {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String type = 'PUSKESMAS';
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.local_hospital, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Tambah Instansi / Faskes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: type,
                          decoration: const InputDecoration(labelText: 'Jenis Instansi', prefixIcon: Icon(Icons.category)),
                          items: const [
                            DropdownMenuItem(value: 'PUSKESMAS', child: Text('Puskesmas')),
                            DropdownMenuItem(value: 'RSUD', child: Text('Rumah Sakit Umum Daerah (RSUD)')),
                            DropdownMenuItem(value: 'KLINIK', child: Text('Klinik Pratama / Bersalin')),
                          ],
                          onChanged: (val) {
                            if (val != null) setDialogState(() => type = val);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nama Instansi *',
                            hintText: 'Misal: Puskesmas Wungu',
                            prefixIcon: Icon(Icons.business),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Nama instansi wajib diisi' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: codeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Kode Faskes *',
                            hintText: 'Misal: PKM-WUNGU',
                            prefixIcon: Icon(Icons.tag),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Kode instansi wajib diisi' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: addressCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Alamat Lengkap *',
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Alamat wajib diisi' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Nomor Telepon (Opsional)',
                            prefixIcon: Icon(Icons.phone),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email (Opsional)',
                            prefixIcon: Icon(Icons.email),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    try {
                      await _apiClient.dio.post('/institutions', data: {
                        'name': nameCtrl.text.trim(),
                        'code': codeCtrl.text.trim().toUpperCase(),
                        'type': type,
                        'address': addressCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                        'email': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                      });
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Instansi baru berhasil ditambahkan'), backgroundColor: Colors.green),
                        );
                        _loadInstitutions();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal menambah instansi: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: const Text('Simpan'),
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
    final filtered = _filteredInstitutions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Instansi & Faskes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Tambah Faskes',
            icon: const Icon(Icons.add),
            onPressed: _showAddInstitutionDialog,
          ),
          IconButton(
            tooltip: 'Segarkan',
            icon: const Icon(Icons.refresh),
            onPressed: _loadInstitutions,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter & Search Header
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.white,
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Cari nama, kode, atau alamat faskes...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Semua (${_institutions.length})', 'ALL'),
                        const SizedBox(width: 8),
                        _buildFilterChip('RSUD (${_institutions.where((i) => i['type'] == 'RSUD').length})', 'RSUD'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Puskesmas (${_institutions.where((i) => i['type'] == 'PUSKESMAS').length})', 'PUSKESMAS'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_hospital_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                'Tidak ada instansi yang cocok',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadInstitutions,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              final isRsud = item['type'] == 'RSUD';

                              return Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: (isRsud ? Colors.indigo : Colors.teal).shade50,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              isRsud ? Icons.local_hospital : Icons.medical_services_outlined,
                                              color: isRsud ? Colors.indigo : Colors.teal,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        item['name'] ?? '',
                                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: isRsud ? Colors.indigo.shade100 : Colors.teal.shade100,
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        item['type'] ?? '',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                          color: isRsud ? Colors.indigo.shade900 : Colors.teal.shade900,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Kode: ${item['code'] ?? '-'}',
                                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 20),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              item['address'] ?? '-',
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (item['phone'] != null && (item['phone'] as String).isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(Icons.phone_outlined, size: 16, color: Colors.grey.shade600),
                                            const SizedBox(width: 6),
                                            Text(
                                              item['phone'],
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (item['email'] != null && (item['email'] as String).isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(Icons.email_outlined, size: 16, color: Colors.grey.shade600),
                                            const SizedBox(width: 6),
                                            Text(
                                              item['email'],
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                                            ),
                                          ],
                                        ),
                                      ],
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
        onPressed: _showAddInstitutionDialog,
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business),
        label: const Text('Tambah Faskes'),
      ),
    );
  }

  Widget _buildFilterChip(String label, String type) {
    final isSelected = _selectedType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedType = type);
      },
      selectedColor: Colors.blue.shade100,
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue.shade900 : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }
}
