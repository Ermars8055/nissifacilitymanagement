import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';

class ComplaintDetailsScreen extends StatefulWidget {
  final String complaintId;
  const ComplaintDetailsScreen({super.key, required this.complaintId});

  @override
  State<ComplaintDetailsScreen> createState() => _ComplaintDetailsScreenState();
}

class _ComplaintDetailsScreenState extends State<ComplaintDetailsScreen> {
  Map<String, dynamic>? complaint;
  bool isLoading = true;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _fetchComplaint();
  }

  Future<void> _fetchComplaint() async {
    try {
      final data = await ApiClient.get('/Complaints/${widget.complaintId}');
      setState(() { complaint = data; isLoading = false; });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _updating = true);
    try {
      await ApiClient.put('/Complaints/${widget.complaintId}/status', {'status': newStatus});
      setState(() {
        complaint = {...?complaint, 'status': newStatus};
        if (newStatus == 'Resolved' || newStatus == 'Closed') {
          complaint!['resolvedAt'] = DateTime.now().toUtc().toIso8601String();
        }
        _updating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Status updated to $newStatus'),
          backgroundColor: const Color(0xFF1E3D2F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (_) {
      setState(() => _updating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to update status. Try again.'),
          backgroundColor: Color(0xFF9B2020),
        ));
      }
    }
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'Critical': return const Color(0xFF9B2020);
      case 'High':     return const Color(0xFFA05A10);
      case 'Medium':   return const Color(0xFF1E5080);
      case 'Low':      return const Color(0xFF2D6B4F);
      default:         return const Color(0xFF8C8278);
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Resolved':    return const Color(0xFF2D6B4F);
      case 'Open':        return const Color(0xFF9B2020);
      case 'In Progress': return const Color(0xFF1E5080);
      case 'Closed':      return const Color(0xFF8C8278);
      default:            return const Color(0xFF8C8278);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F3EC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1E3D2F))),
      );
    }

    if (complaint == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F3EC),
        body: Column(
          children: [
            Container(
              color: const Color(0xFF1E3D2F),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () => context.canPop() ? context.pop() : null,
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Issue Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                  ]),
                ),
              ),
            ),
            const Expanded(child: Center(child: Text('Complaint not found.', style: TextStyle(color: Color(0xFF8C8278))))),
          ],
        ),
      );
    }

    final status = complaint!['status'] as String? ?? 'Open';
    final priority = complaint!['priority'] as String? ?? 'Medium';
    final priorityColor = _priorityColor(priority);
    final statusColor = _statusColor(status);
    final createdAt = DateTime.tryParse(complaint!['createdAt'] ?? '')?.toLocal();
    final resolvedAt = DateTime.tryParse(complaint!['resolvedAt'] ?? '')?.toLocal();

    final canProgress = status == 'Open';
    final canResolve  = status == 'In Progress' || status == 'Open';
    final isResolved  = status == 'Resolved' || status == 'Closed';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EC),
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────
          Container(
            color: const Color(0xFF1E3D2F),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.canPop() ? context.pop() : null,
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Issue Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title card ───────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: const Color(0xFF1A1714).withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            const SizedBox(width: 8),
                            // Priority badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: priorityColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                priority,
                                style: TextStyle(color: priorityColor, fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                            ),
                            if (complaint!['isAutoGenerated'] == true) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFA05A10).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.auto_awesome_rounded, size: 12, color: Color(0xFFA05A10)),
                                    SizedBox(width: 4),
                                    Text('Auto', style: TextStyle(color: Color(0xFFA05A10), fontSize: 11, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          complaint!['title'] ?? '',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1714)),
                        ),
                        if ((complaint!['description'] as String?)?.isNotEmpty == true) ...[
                          const SizedBox(height: 8),
                          Text(
                            complaint!['description'],
                            style: const TextStyle(fontSize: 14, color: Color(0xFF8C8278), height: 1.5),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Meta info card ───────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: const Color(0xFF1A1714).withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          Icons.location_on_outlined,
                          'Location',
                          '${complaint!['entityName'] ?? ''} (${complaint!['entityType'] ?? ''})',
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, color: Color(0xFFEDE7DD))),
                        _InfoRow(
                          Icons.calendar_today_outlined,
                          'Reported',
                          createdAt != null
                              ? '${createdAt.day}/${createdAt.month}/${createdAt.year}  ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
                              : '—',
                        ),
                        if ((complaint!['assignedToName'] as String?)?.isNotEmpty == true) ...[
                          const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, color: Color(0xFFEDE7DD))),
                          _InfoRow(Icons.person_outline_rounded, 'Assigned To', complaint!['assignedToName']),
                        ],
                        if (resolvedAt != null) ...[
                          const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, color: Color(0xFFEDE7DD))),
                          _InfoRow(
                            Icons.check_circle_outline_rounded,
                            'Resolved',
                            '${resolvedAt.day}/${resolvedAt.month}/${resolvedAt.year}  ${resolvedAt.hour.toString().padLeft(2, '0')}:${resolvedAt.minute.toString().padLeft(2, '0')}',
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Timeline ────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: const Color(0xFF1A1714).withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Resolution Timeline', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                        const SizedBox(height: 16),
                        _TimelineStep(label: 'Complaint Logged', done: true, isLast: false),
                        _TimelineStep(label: 'Assigned to Technician', done: status != 'Open', isLast: false),
                        _TimelineStep(label: 'Work in Progress', done: status == 'Resolved' || status == 'In Progress', isLast: false),
                        _TimelineStep(label: 'Resolved & Verified', done: isResolved, isLast: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Action buttons ───────────────────────────────
                  if (isResolved) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF2ED),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF2D6B4F).withValues(alpha: 0.3)),
                      ),
                      child: const Row(children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF2D6B4F), size: 22),
                        SizedBox(width: 12),
                        Text('This complaint has been resolved.', style: TextStyle(color: Color(0xFF2D6B4F), fontWeight: FontWeight.w600, fontSize: 15)),
                      ]),
                    ),
                  ] else ...[
                    if (canProgress)
                      _ActionButton(
                        label: 'Mark as In Progress',
                        icon: Icons.play_circle_outline_rounded,
                        color: const Color(0xFF1E5080),
                        isLoading: _updating,
                        onTap: () => _updateStatus('In Progress'),
                      ),
                    if (canProgress) const SizedBox(height: 12),
                    if (canResolve)
                      _ActionButton(
                        label: 'Mark as Resolved',
                        icon: Icons.check_circle_outline_rounded,
                        color: const Color(0xFF1E3D2F),
                        isLoading: _updating,
                        onTap: () => _updateStatus('Resolved'),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, size: 19, color: const Color(0xFF1E3D2F)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF8C8278), fontWeight: FontWeight.w500)),
              const SizedBox(height: 3),
              Text(value, style: const TextStyle(fontSize: 15, color: Color(0xFF1A1714), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String label;
  final bool done;
  final bool isLast;
  const _TimelineStep({required this.label, required this.done, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: done ? const Color(0xFF1E3D2F) : const Color(0xFFDDD5C8),
                shape: BoxShape.circle,
              ),
              child: Icon(done ? Icons.check_rounded : Icons.circle, color: Colors.white, size: 13),
            ),
            if (!isLast)
              Container(width: 2, height: 28, color: done ? const Color(0xFFEBF2ED) : const Color(0xFFDDD5C8)),
          ],
        ),
        const SizedBox(width: 14),
        Padding(
          padding: EdgeInsets.only(top: 2, bottom: isLast ? 0 : 28),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: done ? FontWeight.w600 : FontWeight.normal,
              color: done ? const Color(0xFF1A1714) : const Color(0xFF8C8278),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: isLoading ? color.withValues(alpha: 0.5) : color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLoading ? [] : [
            BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 5)),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
        ),
      ),
    );
  }
}
