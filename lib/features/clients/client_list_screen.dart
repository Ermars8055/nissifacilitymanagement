import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  List<dynamic> _clients = [];
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiClient.get('/Hierarchy/clients');
      setState(() {
        _clients = data;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddClientSheet() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFDDD5C8), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.business_rounded, color: Color(0xFF1E3D2F), size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Text('New Client', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                ],
              ),
              const SizedBox(height: 24),
              _buildField(nameCtrl, 'CLIENT NAME', 'e.g. Apex Industries', Icons.business_outlined),
              const SizedBox(height: 16),
              _buildField(emailCtrl, 'CONTACT EMAIL', 'contact@company.com', Icons.email_outlined, keyboard: TextInputType.emailAddress),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(color: const Color(0xFFEEE8DF), borderRadius: BorderRadius.circular(14)),
                        child: const Center(child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4A4540), fontSize: 15))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () async {
                        if (nameCtrl.text.trim().isEmpty) return;
                        Navigator.pop(ctx);
                        setState(() => _isLoading = true);
                        try {
                          await ApiClient.post('/Hierarchy/clients', {
                            'name': nameCtrl.text.trim(),
                            'contactEmail': emailCtrl.text.trim(),
                          });
                          _fetch();
                        } catch (e) {
                          setState(() => _isLoading = false);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                        }
                      },
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(color: const Color(0xFF1E3D2F), borderRadius: BorderRadius.circular(14)),
                        child: const Center(child: Text('Add Client', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15))),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, String hint, IconData icon, {TextInputType? keyboard}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF8C8278), letterSpacing: 1.1)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          autofocus: label == 'CLIENT NAME',
          style: const TextStyle(color: Color(0xFF1A1714), fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFBBB3A8)),
            prefixIcon: Icon(icon, color: const Color(0xFF8C8278), size: 20),
            filled: true,
            fillColor: const Color(0xFFEEE8DF),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1E3D2F), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _search.isEmpty
        ? _clients
        : _clients.where((c) => (c['name'] ?? '').toString().toLowerCase().contains(_search.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: const Color(0xFFEEE8DF), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1A1714)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text('Clients', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                      const Spacer(),
                      GestureDetector(
                        onTap: _showAddClientSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(color: const Color(0xFF1E3D2F), borderRadius: BorderRadius.circular(12)),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _search = v),
                    style: const TextStyle(color: Color(0xFF1A1714), fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search clients...',
                      hintStyle: const TextStyle(color: Color(0xFFBBB3A8)),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8C8278), size: 20),
                      filled: true,
                      fillColor: const Color(0xFFEEE8DF),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3D2F)))
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 72, height: 72,
                                decoration: const BoxDecoration(color: Color(0xFFEBF2ED), shape: BoxShape.circle),
                                child: const Icon(Icons.people_outline_rounded, size: 34, color: Color(0xFF2D6B4F)),
                              ),
                              const SizedBox(height: 16),
                              const Text('No clients yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1714))),
                              const SizedBox(height: 6),
                              const Text('Add your first client to get started.', style: TextStyle(color: Color(0xFF8C8278))),
                              const SizedBox(height: 20),
                              GestureDetector(
                                onTap: _showAddClientSheet,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                                  decoration: BoxDecoration(color: const Color(0xFF1E3D2F), borderRadius: BorderRadius.circular(14)),
                                  child: const Text('Add First Client', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetch,
                          color: const Color(0xFF1E3D2F),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final c = filtered[i] as Map<String, dynamic>;
                              return GestureDetector(
                                onTap: () => context.push('/clients/details/${c['id']}'),
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [BoxShadow(
                                      color: const Color(0xFF1A1714).withValues(alpha: 0.04),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    )],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 50, height: 50,
                                        decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(15)),
                                        child: const Icon(Icons.business_rounded, color: Color(0xFF1E3D2F), size: 26),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(c['name'] ?? 'Unknown',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1714))),
                                            if ((c['contactEmail'] ?? '').toString().isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(Icons.email_outlined, size: 13, color: Color(0xFF8C8278)),
                                                  const SizedBox(width: 5),
                                                  Expanded(
                                                    child: Text(c['contactEmail'].toString(),
                                                        style: const TextStyle(fontSize: 12, color: Color(0xFF8C8278)),
                                                        overflow: TextOverflow.ellipsis),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEBF2ED),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Text('Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2D6B4F))),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.chevron_right_rounded, color: Color(0xFFDDD5C8), size: 22),
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
    );
  }
}
