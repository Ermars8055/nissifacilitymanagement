import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../qr/qr_scanner_screen.dart';

class TaskDetailsScreen extends StatefulWidget {
  final String taskId;
  const TaskDetailsScreen({super.key, required this.taskId});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  Map<String, dynamic>? task;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTask();
  }

  Future<void> _fetchTask() async {
    try {
      final found = await ApiClient.get('/Tasks/${widget.taskId}');
      setState(() { task = found; isLoading = false; });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _markInProgress() async {
    setState(() => task = {...?task, 'status': 'In Progress'});
    try {
      await ApiClient.put('/Tasks/${widget.taskId}/status', {'status': 'In Progress'});
    } catch (_) {
      setState(() => task = {...?task, 'status': 'Pending'});
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':   return const Color(0xFF2D6B4F);
      case 'Pending':     return const Color(0xFFA05A10);
      case 'In Progress': return const Color(0xFF1E5080);
      case 'Missed':      return const Color(0xFF9B2020);
      default:            return const Color(0xFF8C8278);
    }
  }

  Future<void> _startWithQrScan() async {
    final entityQr = task?['entityQrCode'] as String?;
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => QrScannerScreen(expectedCode: entityQr, title: 'Scan Location QR'),
        fullscreenDialog: true,
      ),
    );
    if (scanned != null && mounted) {
      context.push('/tasks/details/${widget.taskId}/execute', extra: scanned);
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
    if (task == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F3EC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1714)), onPressed: () => context.pop()),
          title: const Text('Task Details', style: TextStyle(color: Color(0xFF1A1714), fontWeight: FontWeight.bold)),
        ),
        body: const Center(child: Text('Task not found', style: TextStyle(color: Color(0xFF8C8278), fontSize: 15))),
      );
    }

    final status = task!['status'] as String? ?? 'Pending';
    final statusColor = _statusColor(status);
    final isPending    = status == 'Pending';
    final isInProgress = status == 'In Progress';
    final scheduledTime = DateTime.tryParse(task!['scheduledTime'] ?? '')?.toLocal();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1714)),
          onPressed: () => context.pop(),
        ),
        title: const Text('Work Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A1714))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status + title card
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
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    if (task!['isVerified'] == true) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(8)),
                        child: const Row(children: [
                          Icon(Icons.qr_code_2_rounded, size: 13, color: Color(0xFF2D6B4F)),
                          SizedBox(width: 4),
                          Text('QR Verified', style: TextStyle(color: Color(0xFF2D6B4F), fontWeight: FontWeight.bold, fontSize: 12)),
                        ]),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 14),
                  Text(task!['title'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                  if ((task!['description'] as String?)?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Text(task!['description'], style: const TextStyle(fontSize: 14, color: Color(0xFF8C8278), height: 1.4)),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Meta info card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: const Color(0xFF1A1714).withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  _InfoRow(Icons.location_on_outlined, 'Location', '${task!['entityName']} (${task!['entityType']})'),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, color: Color(0xFFEDE7DD))),
                  _InfoRow(Icons.person_outline_rounded, 'Assigned To', task!['assignedToName'] ?? '—'),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, color: Color(0xFFEDE7DD))),
                  _InfoRow(
                    Icons.schedule_rounded,
                    'Scheduled',
                    scheduledTime != null
                        ? '${scheduledTime.day}/${scheduledTime.month}/${scheduledTime.year}  ${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}'
                        : '—',
                  ),
                  if (task!['notes']?.toString().isNotEmpty == true) ...[
                    const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, color: Color(0xFFEDE7DD))),
                    _InfoRow(Icons.notes_rounded, 'Notes', task!['notes']),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Pending → Start Task (no QR needed, just moves to In Progress)
            if (isPending) ...[
              GestureDetector(
                onTap: _markInProgress,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E5080),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: const Color(0xFF1E5080).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_outline_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text('Start Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],

            // In Progress → QR scan to complete
            if (isInProgress) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF2ED),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2D6B4F).withValues(alpha: 0.25)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF1E3D2F), size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Scan Required to Complete', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3D2F), fontSize: 15)),
                          SizedBox(height: 4),
                          Text(
                            'Go to the location and scan the QR code to verify your presence before completing the checklist.',
                            style: TextStyle(fontSize: 13, color: Color(0xFF2D6B4F), height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _startWithQrScan,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3D2F),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: const Color(0xFF1E3D2F).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text('Scan QR & Complete', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],

            if (status == 'Completed') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF2ED),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2D6B4F).withValues(alpha: 0.3)),
                ),
                child: const Row(children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF2D6B4F), size: 24),
                  SizedBox(width: 12),
                  Text('This task has been completed.', style: TextStyle(color: Color(0xFF2D6B4F), fontWeight: FontWeight.w600, fontSize: 15)),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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
          width: 40,
          height: 40,
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
