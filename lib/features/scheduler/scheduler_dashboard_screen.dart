import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/session/session_manager.dart';

class SchedulerDashboardScreen extends StatefulWidget {
  const SchedulerDashboardScreen({super.key});

  @override
  State<SchedulerDashboardScreen> createState() => _SchedulerDashboardScreenState();
}

class _SchedulerDashboardScreenState extends State<SchedulerDashboardScreen> {
  List<dynamic> _schedules = [];
  bool _isLoading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiClient.get('/PmSchedules');
      setState(() {
        _schedules = data;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleSchedule(dynamic schedule) async {
    final id = schedule['id'].toString();
    final wasActive = schedule['isActive'] as bool? ?? false;
    setState(() {
      final idx = _schedules.indexWhere((s) => s['id'].toString() == id);
      if (idx != -1) _schedules[idx]['isActive'] = !wasActive;
    });
    try {
      await ApiClient.put('/PmSchedules/$id/toggle', {});
    } catch (_) {
      setState(() {
        final idx = _schedules.indexWhere((s) => s['id'].toString() == id);
        if (idx != -1) _schedules[idx]['isActive'] = wasActive;
      });
    }
  }

  Future<void> _generateTasks() async {
    setState(() => _isGenerating = true);
    try {
      await ApiClient.post('/PmSchedules/generate-tasks', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tasks generated successfully.'),
            backgroundColor: Color(0xFF2D6B4F),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: const Color(0xFF9B2020)),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showAddScheduleSheet() {
    final nameCtrl = TextEditingController();
    String frequency = 'Daily';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
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
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF1E3D2F), size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Text('New PM Schedule', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                ]),
                const SizedBox(height: 24),
                const Text('SCHEDULE NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF8C8278), letterSpacing: 1.1)),
                const SizedBox(height: 8),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  style: const TextStyle(color: Color(0xFF1A1714), fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'e.g. Weekly HVAC Check',
                    hintStyle: const TextStyle(color: Color(0xFFBBB3A8)),
                    prefixIcon: const Icon(Icons.edit_outlined, color: Color(0xFF8C8278), size: 20),
                    filled: true,
                    fillColor: const Color(0xFFEEE8DF),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1E3D2F), width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('FREQUENCY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF8C8278), letterSpacing: 1.1)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(color: const Color(0xFFEEE8DF), borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: frequency,
                      isExpanded: true,
                      dropdownColor: const Color(0xFFF7F3EC),
                      style: const TextStyle(color: Color(0xFF1A1714), fontSize: 14),
                      items: ['Daily', 'Weekly', 'Monthly', 'Quarterly']
                          .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                          .toList(),
                      onChanged: (val) => setSheet(() => frequency = val!),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(children: [
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
                        final bId = SessionManager().selectedBuildingId ?? '';
                        try {
                          await ApiClient.post('/PmSchedules', {
                            'name': nameCtrl.text.trim(),
                            'frequency': frequency,
                            'buildingId': bId,
                            'isActive': true,
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
                        child: const Center(child: Text('Create Schedule', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15))),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _freqColor(String freq) {
    switch (freq.toLowerCase()) {
      case 'daily':     return const Color(0xFF1E5080);
      case 'weekly':    return const Color(0xFF1E3D2F);
      case 'monthly':   return const Color(0xFF6B3FA0);
      case 'quarterly': return const Color(0xFFA05A10);
      default:          return const Color(0xFF8C8278);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _schedules.where((s) => s['isActive'] == true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              child: Column(
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
                      const Text('PM Scheduler', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                      const Spacer(),
                      GestureDetector(
                        onTap: _showAddScheduleSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(color: const Color(0xFF1E3D2F), borderRadius: BorderRadius.circular(12)),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.add_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          ]),
                        ),
                      ),
                    ],
                  ),
                  if (!_isLoading && _schedules.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: _isGenerating ? null : _generateTasks,
                      child: Container(
                        width: double.infinity,
                        height: 46,
                        decoration: BoxDecoration(
                          color: _isGenerating ? const Color(0xFFEEE8DF) : const Color(0xFFEBF2ED),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF1E3D2F).withValues(alpha: 0.3)),
                        ),
                        child: _isGenerating
                            ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E3D2F))))
                            : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.play_arrow_rounded, color: Color(0xFF1E3D2F), size: 20),
                                SizedBox(width: 8),
                                Text('Generate Tasks from Active Schedules', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3D2F), fontSize: 13)),
                              ]),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Stats
            if (!_isLoading && _schedules.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                child: Row(children: [
                  _ChipStat(label: 'Total', value: _schedules.length.toString(), color: const Color(0xFF1A1714)),
                  const SizedBox(width: 10),
                  _ChipStat(label: 'Active', value: activeCount.toString(), color: const Color(0xFF2D6B4F)),
                  const SizedBox(width: 10),
                  _ChipStat(label: 'Inactive', value: (_schedules.length - activeCount).toString(), color: const Color(0xFF8C8278)),
                ]),
              ),

            // Body
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3D2F)))
                  : _schedules.isEmpty
                      ? Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                              width: 72, height: 72,
                              decoration: const BoxDecoration(color: Color(0xFFEBF2ED), shape: BoxShape.circle),
                              child: const Icon(Icons.calendar_month_outlined, size: 34, color: Color(0xFF2D6B4F)),
                            ),
                            const SizedBox(height: 16),
                            const Text('No schedules yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1714))),
                            const SizedBox(height: 6),
                            const Text('Create recurring PM schedules to auto-generate tasks.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF8C8278))),
                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: _showAddScheduleSheet,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                                decoration: BoxDecoration(color: const Color(0xFF1E3D2F), borderRadius: BorderRadius.circular(14)),
                                child: const Text('Add First Schedule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                              ),
                            ),
                          ]),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetch,
                          color: const Color(0xFF1E3D2F),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
                            itemCount: _schedules.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final s = _schedules[i] as Map<String, dynamic>;
                              final isActive = s['isActive'] as bool? ?? false;
                              final freq = s['frequency'] as String? ?? '';
                              final fc = _freqColor(freq);
                              final nextRun = s['nextRunDate'] as String?;

                              return Container(
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
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: fc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                    child: Icon(Icons.repeat_rounded, color: fc, size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(s['name'] ?? 'Schedule', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1714))),
                                      const SizedBox(height: 3),
                                      Row(children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: fc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                          child: Text(freq, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fc)),
                                        ),
                                        if (nextRun != null) ...[
                                          const SizedBox(width: 8),
                                          const Icon(Icons.calendar_today_outlined, size: 11, color: Color(0xFF8C8278)),
                                          const SizedBox(width: 3),
                                          Text(_formatDate(nextRun), style: const TextStyle(fontSize: 11, color: Color(0xFF8C8278))),
                                        ],
                                      ]),
                                    ]),
                                  ),
                                  Switch(
                                    value: isActive,
                                    onChanged: (_) => _toggleSchedule(s),
                                    activeColor: const Color(0xFF1E3D2F),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ]),
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

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _ChipStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ChipStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Text('$value $label', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
