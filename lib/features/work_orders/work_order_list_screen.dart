import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/session/session_manager.dart';

class WorkOrderListScreen extends StatefulWidget {
  const WorkOrderListScreen({super.key});

  @override
  State<WorkOrderListScreen> createState() => _WorkOrderListScreenState();
}

class _WorkOrderListScreenState extends State<WorkOrderListScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final bId = SessionManager().selectedBuildingId ?? '';
      final data = await ApiClient.get('/Tasks?buildingId=$bId');
      final orders = (data as List)
          .where((t) => (t['entityType'] ?? '').toString().toLowerCase() == 'asset')
          .toList();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':   return const Color(0xFF2D6B4F);
      case 'in progress': return const Color(0xFF1E5080);
      default:            return const Color(0xFFA05A10);
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':   return Icons.check_circle_rounded;
      case 'in progress': return Icons.timelapse_rounded;
      default:            return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 'All'
        ? _orders
        : _orders.where((o) => o['status'] == _filter).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
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
                      const Text('Work Orders', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF2ED),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${filtered.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3D2F), fontSize: 14)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Pending', 'In Progress', 'Completed'].map((s) {
                        final selected = _filter == s;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8, bottom: 14),
                          child: GestureDetector(
                            onTap: () => setState(() => _filter = s),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? const Color(0xFF1E3D2F) : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected ? const Color(0xFF1E3D2F) : const Color(0xFFDDD5C8),
                                ),
                              ),
                              child: Text(s, style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : const Color(0xFF8C8278),
                              )),
                            ),
                          ),
                        );
                      }).toList(),
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
                                child: const Icon(Icons.build_outlined, size: 34, color: Color(0xFF2D6B4F)),
                              ),
                              const SizedBox(height: 16),
                              const Text('No work orders', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1714))),
                              const SizedBox(height: 6),
                              const Text('Asset-linked tasks will appear here.', style: TextStyle(color: Color(0xFF8C8278))),
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
                            itemBuilder: (context, i) {
                              final o = filtered[i] as Map<String, dynamic>;
                              final status = o['status'] as String? ?? 'Pending';
                              final c = _statusColor(status);
                              return GestureDetector(
                                onTap: () => context.push('/tasks/details/${o['id']}'),
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
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                        child: Icon(_statusIcon(status), color: c, size: 20),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(o['title'] as String? ?? 'Work Order',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1714))),
                                            const SizedBox(height: 3),
                                            Text(o['entityName'] as String? ?? '',
                                                style: const TextStyle(fontSize: 12, color: Color(0xFF8C8278))),
                                            if ((o['assignedToName'] ?? '').toString().isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Row(children: [
                                                const Icon(Icons.person_outline_rounded, size: 12, color: Color(0xFFAA9F94)),
                                                const SizedBox(width: 4),
                                                Text(o['assignedToName'].toString(),
                                                    style: const TextStyle(fontSize: 11, color: Color(0xFFAA9F94))),
                                              ]),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: c.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(status,
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: c)),
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
    );
  }
}
