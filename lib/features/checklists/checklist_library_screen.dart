import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/session/session_manager.dart';

class ChecklistLibraryScreen extends StatefulWidget {
  const ChecklistLibraryScreen({super.key});

  @override
  State<ChecklistLibraryScreen> createState() => _ChecklistLibraryScreenState();
}

class _ChecklistLibraryScreenState extends State<ChecklistLibraryScreen> {
  List<dynamic> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiClient.get('/Checklists');
      setState(() {
        _templates = data;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _showTemplateDetail(Map<String, dynamic> template) {
    final items = (template['items'] as List?) ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (ctx, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(color: const Color(0xFFDDD5C8), borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.checklist_rounded, color: Color(0xFF1E3D2F), size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(template['name'] ?? 'Template', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                          Text('${items.length} step${items.length == 1 ? '' : 's'}', style: const TextStyle(fontSize: 13, color: Color(0xFF8C8278))),
                        ]),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(20)),
                        child: const Text('Read-only', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2D6B4F))),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFEDE7DD)),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('No steps defined.', style: TextStyle(color: Color(0xFF8C8278))))
                    : ListView.separated(
                        controller: controller,
                        padding: const EdgeInsets.fromLTRB(24, 10, 24, 32),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final item = items[i] as Map<String, dynamic>;
                          final type = item['itemType'] as String? ?? 'checkbox';
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F3EC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFEDE7DD)),
                            ),
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEBF2ED),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Icon(_typeIcon(type), color: const Color(0xFF1E3D2F), size: 16),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(item['description'] as String? ?? item['label'] as String? ?? 'Step ${i + 1}',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1714))),
                                  Text(type, style: const TextStyle(fontSize: 11, color: Color(0xFF8C8278))),
                                ]),
                              ),
                              Text('${i + 1}', style: const TextStyle(fontSize: 13, color: Color(0xFFDDD5C8), fontWeight: FontWeight.bold)),
                            ]),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'photo':    return Icons.camera_alt_rounded;
      case 'number':   return Icons.pin_rounded;
      case 'text':     return Icons.short_text_rounded;
      default:         return Icons.check_box_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = SessionManager().isAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              child: Row(
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
                  const Text('Checklist Library', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(10)),
                    child: Text('${_templates.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3D2F), fontSize: 14)),
                  ),
                ],
              ),
            ),

            if (!isAdmin)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF2ED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF1E3D2F)),
                  SizedBox(width: 8),
                  Text('View-only. Templates are managed by your admin.', style: TextStyle(fontSize: 12, color: Color(0xFF1E3D2F))),
                ]),
              ),

            // Body
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3D2F)))
                  : _templates.isEmpty
                      ? Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                              width: 72, height: 72,
                              decoration: const BoxDecoration(color: Color(0xFFEBF2ED), shape: BoxShape.circle),
                              child: const Icon(Icons.checklist_rounded, size: 34, color: Color(0xFF2D6B4F)),
                            ),
                            const SizedBox(height: 16),
                            const Text('No templates yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1714))),
                            const SizedBox(height: 6),
                            const Text('Admins can create templates in the web portal.', style: TextStyle(color: Color(0xFF8C8278))),
                          ]),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetch,
                          color: const Color(0xFF1E3D2F),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
                            itemCount: _templates.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final t = _templates[i] as Map<String, dynamic>;
                              final items = (t['items'] as List?) ?? [];
                              return GestureDetector(
                                onTap: () => _showTemplateDetail(t),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [BoxShadow(
                                      color: const Color(0xFF1A1714).withValues(alpha: 0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    )],
                                  ),
                                  child: Row(children: [
                                    Container(
                                      width: 46, height: 46,
                                      decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(13)),
                                      child: const Icon(Icons.checklist_rounded, color: Color(0xFF1E3D2F), size: 22),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(t['name'] ?? 'Template', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1714))),
                                        const SizedBox(height: 3),
                                        Text('${items.length} step${items.length == 1 ? '' : 's'}',
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF8C8278))),
                                      ]),
                                    ),
                                    const Icon(Icons.chevron_right_rounded, color: Color(0xFFDDD5C8), size: 22),
                                  ]),
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
