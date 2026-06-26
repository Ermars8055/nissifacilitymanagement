import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/session/session_manager.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  List<dynamic> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final bId = SessionManager().selectedBuildingId ?? '';
      final data = await ApiClient.get('/Dashboard?buildingId=$bId');
      setState(() {
        _activities = (data['recentActivity'] as List?) ?? [];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  IconData _icon(String type) {
    switch (type.toLowerCase()) {
      case 'task':       return Icons.assignment_rounded;
      case 'complaint':  return Icons.report_problem_rounded;
      case 'asset':      return Icons.devices_rounded;
      default:           return Icons.notifications_rounded;
    }
  }

  Color _color(String type) {
    switch (type.toLowerCase()) {
      case 'task':       return const Color(0xFF1E3D2F);
      case 'complaint':  return const Color(0xFF9B2020);
      default:           return const Color(0xFF1E5080);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  const Text('Notifications', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                ],
              ),
            ),

            // Body
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3D2F)))
                  : _activities.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.notifications_none_rounded, size: 52, color: Color(0xFFDDD5C8)),
                              SizedBox(height: 12),
                              Text("You're all caught up!", style: TextStyle(fontSize: 16, color: Color(0xFF8C8278))),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetch,
                          color: const Color(0xFF1E3D2F),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(18),
                            itemCount: _activities.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final a = _activities[i] as Map<String, dynamic>;
                              final type = a['type'] as String? ?? '';
                              final c = _color(type);
                              final id = a['id']?.toString() ?? a['entityId']?.toString();
                              return GestureDetector(
                                onTap: id == null ? null : () {
                                  if (type.toLowerCase() == 'task') context.push('/tasks/details/$id');
                                  if (type.toLowerCase() == 'complaint') context.push('/complaints/details/$id');
                                },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [BoxShadow(color: const Color(0xFF1A1714).withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                      child: Icon(_icon(type), color: c, size: 20),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(a['title'] as String? ?? a['description'] as String? ?? 'Activity', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1714))),
                                          if ((a['description'] ?? '').toString().isNotEmpty && a['title'] != null) ...[
                                            const SizedBox(height: 3),
                                            Text(a['description'].toString(), style: const TextStyle(fontSize: 12, color: Color(0xFF8C8278)), maxLines: 2, overflow: TextOverflow.ellipsis),
                                          ],
                                          const SizedBox(height: 4),
                                          Text(a['time'] as String? ?? a['createdAt'] as String? ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFFAA9F94))),
                                        ],
                                      ),
                                    ),
                                    if (id != null && (type.toLowerCase() == 'task' || type.toLowerCase() == 'complaint'))
                                      const Icon(Icons.chevron_right_rounded, color: Color(0xFFDDD5C8), size: 20),
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
