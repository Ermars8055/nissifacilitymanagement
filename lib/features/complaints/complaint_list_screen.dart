import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/session/session_manager.dart';
import 'complaint_form_screen.dart';

class ComplaintListScreen extends StatefulWidget {
  const ComplaintListScreen({super.key});

  @override
  State<ComplaintListScreen> createState() => _ComplaintListScreenState();
}

class _ComplaintListScreenState extends State<ComplaintListScreen> {
  List<dynamic> allComplaints = [];
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Open', 'In Progress', 'Resolved', 'Closed'];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    setState(() => isLoading = true);
    final bId = SessionManager().selectedBuildingId ?? '';
    try {
      final complaints = await ApiClient.get('/Complaints?buildingId=$bId');
      setState(() {
        allComplaints = complaints;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Resolved':    return const Color(0xFF2D6B4F);
      case 'Open':        return const Color(0xFF9B2020);
      case 'In Progress': return const Color(0xFFA05A10);
      case 'Closed':      return const Color(0xFF8C8278);
      default:            return const Color(0xFF8C8278);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Resolved':    return Icons.check_circle_rounded;
      case 'Open':        return Icons.error_rounded;
      case 'In Progress': return Icons.pending_rounded;
      case 'Closed':      return Icons.lock_rounded;
      default:            return Icons.circle_outlined;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'Critical': return const Color(0xFF9B2020);
      case 'High':     return const Color(0xFFA05A10);
      case 'Medium':   return const Color(0xFF1E5080);
      case 'Low':      return const Color(0xFF2D6B4F);
      default:         return const Color(0xFF8C8278);
    }
  }

  int _countFor(String filter) =>
      filter == 'All' ? allComplaints.length : allComplaints.where((c) => c['status'] == filter).length;

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedFilter == 'All'
        ? allComplaints
        : allComplaints.where((c) => c['status'] == _selectedFilter).toList();

    final openCount       = allComplaints.where((c) => c['status'] == 'Open').length;
    final inProgressCount = allComplaints.where((c) => c['status'] == 'In Progress').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EC),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Complaints',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A1714)),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final refresh = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => const ComplaintFormScreen(),
                              fullscreenDialog: true,
                            ),
                          );
                          if (refresh == true) _fetchComplaints();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9B2020),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 6),
                              Text('Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$openCount open  ·  $inProgressCount in progress',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF8C8278)),
                  ),
                  const SizedBox(height: 18),

                  // Filter chips
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final filter = _filters[i];
                        final isSelected = filter == _selectedFilter;
                        final count = _countFor(filter);
                        final activeColor = filter == 'Open'
                            ? const Color(0xFF9B2020)
                            : const Color(0xFF1E3D2F);
                        return GestureDetector(
                          onTap: () => setState(() => _selectedFilter = filter),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected ? activeColor : const Color(0xFFEEE8DF),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  filter,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : const Color(0xFF4A4540),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.22)
                                        : const Color(0xFFDDD5C8),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : const Color(0xFF4A4540),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),

            // ── List ──────────────────────────────────────────────────────
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3D2F)))
                  : filtered.isEmpty
                      ? _EmptyState(filter: _selectedFilter)
                      : RefreshIndicator(
                          onRefresh: _fetchComplaints,
                          color: const Color(0xFF1E3D2F),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final c = filtered[index];
                              return _ComplaintCard(
                                complaint: c,
                                statusColor: _statusColor(c['status'] ?? 'Open'),
                                statusIcon: _statusIcon(c['status'] ?? 'Open'),
                                priorityColor: _priorityColor(c['priority'] ?? 'Low'),
                                onTap: () => context.go('/complaints/details/${c['id']}'),
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

// ── Complaint Card ────────────────────────────────────────────────────────────

class _ComplaintCard extends StatelessWidget {
  final dynamic complaint;
  final Color statusColor;
  final IconData statusIcon;
  final Color priorityColor;
  final VoidCallback onTap;

  const _ComplaintCard({
    required this.complaint,
    required this.statusColor,
    required this.statusIcon,
    required this.priorityColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    DateTime? createdAt;
    try { createdAt = DateTime.parse(complaint['createdAt']).toLocal(); } catch (_) {}
    final timeStr = createdAt != null
        ? '${createdAt.day}/${createdAt.month}  ${createdAt.hour.toString().padLeft(2,'0')}:${createdAt.minute.toString().padLeft(2,'0')}'
        : '';

    final isAutoGenerated = complaint['isAutoGenerated'] == true;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A1714).withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left accent bar (priority color)
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: priority + auto badge + status
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              complaint['priority'] ?? 'Low',
                              style: TextStyle(fontSize: 13, color: priorityColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (isAutoGenerated) ...[
                            const SizedBox(width: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEE8DF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.smart_toy_rounded, size: 12, color: Color(0xFF4A4540)),
                                  SizedBox(width: 4),
                                  Text('Auto', style: TextStyle(fontSize: 11, color: Color(0xFF4A4540), fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 13, color: statusColor),
                                const SizedBox(width: 5),
                                Text(
                                  complaint['status'] ?? 'Open',
                                  style: TextStyle(fontSize: 13, color: statusColor, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Title
                      Text(
                        complaint['title'] ?? 'Unknown Issue',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1714)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 10),

                      // Location + Date
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF8C8278)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${complaint['entityName'] ?? ''} (${complaint['entityType'] ?? ''})',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF4A4540)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (timeStr.isNotEmpty) ...[
                            const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF8C8278)),
                            const SizedBox(width: 4),
                            Text(timeStr, style: const TextStyle(fontSize: 12, color: Color(0xFF8C8278))),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.chevron_right_rounded, color: Color(0xFFDDD5C8), size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(color: Color(0xFFF5E8E8), shape: BoxShape.circle),
              child: const Icon(Icons.report_problem_outlined, size: 40, color: Color(0xFF9B2020)),
            ),
            const SizedBox(height: 18),
            Text(
              filter == 'All' ? 'No complaints' : 'No $filter complaints',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1714)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Facility issues will be listed here when reported',
              style: TextStyle(fontSize: 14, color: Color(0xFF8C8278)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
