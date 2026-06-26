import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/network/api_client.dart';
import '../../core/session/session_manager.dart';

class ReportsDashboardScreen extends StatefulWidget {
  const ReportsDashboardScreen({super.key});

  @override
  State<ReportsDashboardScreen> createState() => _ReportsDashboardScreenState();
}

class _ReportsDashboardScreenState extends State<ReportsDashboardScreen> {
  Map<String, dynamic>? _dashboard;
  List<dynamic> _tasks = [];
  List<dynamic> _complaints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    final bId = SessionManager().selectedBuildingId ?? '';
    try {
      final results = await Future.wait([
        ApiClient.get('/Dashboard?buildingId=$bId'),
        ApiClient.get('/Tasks?buildingId=$bId'),
        ApiClient.get('/Complaints?buildingId=$bId'),
      ]);
      setState(() {
        _dashboard = results[0] as Map<String, dynamic>;
        _tasks = results[1] as List;
        _complaints = results[2] as List;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  // ── Task status counts ────────────────────────────────────────────────────
  Map<String, int> get _taskStatusCounts {
    final m = <String, int>{'Pending': 0, 'In Progress': 0, 'Completed': 0};
    for (final t in _tasks) {
      final s = t['status'] as String? ?? 'Pending';
      m[s] = (m[s] ?? 0) + 1;
    }
    return m;
  }

  // ── Complaint open vs resolved ────────────────────────────────────────────
  int get _openComplaints => _complaints.where((c) {
    final s = (c['status'] as String? ?? '').toLowerCase();
    return s != 'resolved' && s != 'closed';
  }).length;
  int get _resolvedComplaints => _complaints.length - _openComplaints;

  @override
  Widget build(BuildContext context) {
    final kpi = _dashboard?['kpi'] as Map<String, dynamic>? ?? {};
    final taskCounts = _taskStatusCounts;
    final totalTasks = _tasks.length;

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
                  const Text('Reports', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                  const Spacer(),
                  GestureDetector(
                    onTap: _fetch,
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: const Color(0xFFEEE8DF), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF1A1714)),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3D2F)))
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      color: const Color(0xFF1E3D2F),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // ── KPI Cards ──────────────────────────────────
                            Row(children: [
                              Expanded(child: _KpiCard(
                                label: 'Total Tasks',
                                value: totalTasks.toString(),
                                icon: Icons.assignment_rounded,
                                color: const Color(0xFF1E3D2F),
                              )),
                              const SizedBox(width: 12),
                              Expanded(child: _KpiCard(
                                label: 'Completed',
                                value: (taskCounts['Completed'] ?? 0).toString(),
                                icon: Icons.check_circle_rounded,
                                color: const Color(0xFF2D6B4F),
                              )),
                            ]),
                            const SizedBox(height: 12),
                            Row(children: [
                              Expanded(child: _KpiCard(
                                label: 'Open Issues',
                                value: _openComplaints.toString(),
                                icon: Icons.report_problem_rounded,
                                color: const Color(0xFF9B2020),
                              )),
                              const SizedBox(width: 12),
                              Expanded(child: _KpiCard(
                                label: 'Health Score',
                                value: kpi['buildingHealth'] as String? ?? '—',
                                icon: Icons.health_and_safety_rounded,
                                color: const Color(0xFF1E5080),
                              )),
                            ]),

                            const SizedBox(height: 28),

                            // ── Tasks by Status Bar Chart ──────────────────
                            _SectionLabel(label: 'TASKS BY STATUS'),
                            const SizedBox(height: 12),
                            _ChartCard(
                              child: totalTasks == 0
                                  ? _NoData()
                                  : SizedBox(
                                      height: 180,
                                      child: BarChart(
                                        BarChartData(
                                          alignment: BarChartAlignment.spaceAround,
                                          maxY: (taskCounts.values.reduce((a, b) => a > b ? a : b) + 2).toDouble(),
                                          barTouchData: BarTouchData(enabled: false),
                                          titlesData: FlTitlesData(
                                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 11, color: Color(0xFF8C8278))))),
                                            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, _) {
                                              const labels = ['Pending', 'In Progress', 'Completed'];
                                              const shorts = ['Pending', 'In Prog.', 'Done'];
                                              final idx = v.toInt();
                                              if (idx < 0 || idx >= labels.length) return const SizedBox();
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 6),
                                                child: Text(shorts[idx], style: const TextStyle(fontSize: 10, color: Color(0xFF8C8278))),
                                              );
                                            })),
                                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          ),
                                          gridData: FlGridData(
                                            show: true,
                                            drawVerticalLine: false,
                                            getDrawingHorizontalLine: (_) => FlLine(color: const Color(0xFFEDE7DD), strokeWidth: 1),
                                          ),
                                          borderData: FlBorderData(show: false),
                                          barGroups: [
                                            _bar(0, taskCounts['Pending']!.toDouble(), const Color(0xFFA05A10)),
                                            _bar(1, taskCounts['In Progress']!.toDouble(), const Color(0xFF1E5080)),
                                            _bar(2, taskCounts['Completed']!.toDouble(), const Color(0xFF2D6B4F)),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),

                            const SizedBox(height: 24),

                            // ── Complaints Pie Chart ───────────────────────
                            _SectionLabel(label: 'COMPLAINTS OVERVIEW'),
                            const SizedBox(height: 12),
                            _ChartCard(
                              child: _complaints.isEmpty
                                  ? _NoData()
                                  : Row(
                                      children: [
                                        SizedBox(
                                          width: 140,
                                          height: 140,
                                          child: PieChart(
                                            PieChartData(
                                              sectionsSpace: 3,
                                              centerSpaceRadius: 36,
                                              sections: [
                                                if (_openComplaints > 0)
                                                  PieChartSectionData(
                                                    value: _openComplaints.toDouble(),
                                                    color: const Color(0xFF9B2020),
                                                    radius: 38,
                                                    title: _openComplaints.toString(),
                                                    titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                                  ),
                                                if (_resolvedComplaints > 0)
                                                  PieChartSectionData(
                                                    value: _resolvedComplaints.toDouble(),
                                                    color: const Color(0xFF2D6B4F),
                                                    radius: 38,
                                                    title: _resolvedComplaints.toString(),
                                                    titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            _Legend(color: const Color(0xFF9B2020), label: 'Open', value: _openComplaints),
                                            const SizedBox(height: 12),
                                            _Legend(color: const Color(0xFF2D6B4F), label: 'Resolved', value: _resolvedComplaints),
                                            const SizedBox(height: 12),
                                            Text('Total: ${_complaints.length}', style: const TextStyle(fontSize: 12, color: Color(0xFF8C8278))),
                                          ],
                                        ),
                                      ],
                                    ),
                            ),

                            const SizedBox(height: 24),

                            // ── Completion Rate ────────────────────────────
                            _SectionLabel(label: 'COMPLETION RATE'),
                            const SizedBox(height: 12),
                            _ChartCard(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Task Completion', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1714))),
                                      Text(
                                        totalTasks > 0
                                            ? '${((taskCounts['Completed']! / totalTasks) * 100).round()}%'
                                            : '0%',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3D2F)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: totalTasks > 0 ? (taskCounts['Completed']! / totalTasks) : 0,
                                      minHeight: 12,
                                      backgroundColor: const Color(0xFFEEE8DF),
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2D6B4F)),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(children: [
                                    _MiniStat(label: 'Pending', value: taskCounts['Pending']!, color: const Color(0xFFA05A10)),
                                    const SizedBox(width: 16),
                                    _MiniStat(label: 'In Progress', value: taskCounts['In Progress']!, color: const Color(0xFF1E5080)),
                                    const SizedBox(width: 16),
                                    _MiniStat(label: 'Done', value: taskCounts['Completed']!, color: const Color(0xFF2D6B4F)),
                                  ]),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _bar(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 32,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
      ],
    );
  }
}

// ── Supporting widgets ─────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _KpiCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF1A1714).withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF8C8278))),
        ]),
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF8C8278), letterSpacing: 1.2));
  }
}

class _ChartCard extends StatelessWidget {
  final Widget child;
  const _ChartCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: const Color(0xFF1A1714).withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final int value;
  const _Legend({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 8),
      Text('$label: $value', style: const TextStyle(fontSize: 13, color: Color(0xFF1A1714))),
    ]);
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value.toString(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF8C8278))),
    ]);
  }
}

class _NoData extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 80,
      child: Center(
        child: Text('No data available', style: TextStyle(color: Color(0xFF8C8278), fontSize: 14)),
      ),
    );
  }
}
