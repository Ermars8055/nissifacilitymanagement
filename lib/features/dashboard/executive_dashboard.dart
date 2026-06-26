import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/session/session_manager.dart';

class ExecutiveDashboard extends StatefulWidget {
  const ExecutiveDashboard({super.key});

  @override
  State<ExecutiveDashboard> createState() => _ExecutiveDashboardState();
}

class _ExecutiveDashboardState extends State<ExecutiveDashboard> {
  Map<String, dynamic>? dashboardData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _avatarInitials() {
    final name = SessionManager().currentUser?['name'] as String? ?? '';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'FM';
  }

  Future<void> _fetchDashboardData() async {
    setState(() => isLoading = true);
    final bId = SessionManager().selectedBuildingId ?? '';
    try {
      final data = await ApiClient.get('/Dashboard?buildingId=$bId');
      setState(() {
        dashboardData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
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

    final kpi = dashboardData?['kpi'] as Map<String, dynamic>? ?? {};
    final recentActivity = dashboardData?['recentActivity'] as List? ?? [];
    final userName = SessionManager().currentUser?['name'] as String? ?? 'Field Worker';
    final firstName = userName.split(' ').first;
    final buildingName = SessionManager().selectedBuildingName ?? 'All Buildings';
    final todayTasks      = kpi['todayTasks']              ?? 0;
    final completedTasks  = kpi['completedTasks']          ?? 0;
    final openComplaints  = kpi['openComplaints']          ?? 0;
    final totalAssets     = kpi['totalAssets']             ?? 0;
    final totalBuildings  = kpi['totalBuildings']          ?? 0;
    final resolutionRate  = kpi['complaintResolutionRate'] as String? ?? '0%';
    final completionPct   = todayTasks > 0 ? (completedTasks / todayTasks * 100).round() : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchDashboardData,
          color: const Color(0xFF1E3D2F),
          displacement: 20,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Hero Header ──────────────────────────────────────────
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF142B20), Color(0xFF1E3D2F), Color(0xFF2D6B4F)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.business_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('FacilityPro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis),
                                  Text(buildingName, style: const TextStyle(color: Color(0xFFB8D4C4), fontSize: 12), overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => context.push('/notifications'),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 21),
                                  ),
                                  Positioned(
                                    right: 6,
                                    top: 6,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(color: Color(0xFFF5C842), shape: BoxShape.circle),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => context.push('/settings'),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2D6B4F),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    _avatarInitials(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Greeting
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_greeting()},', style: const TextStyle(color: Color(0xFFB8D4C4), fontSize: 15)),
                            const SizedBox(height: 2),
                            Text(firstName, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                          ],
                        ),
                      ),

                      // Mini stats
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
                        child: Row(
                          children: [
                            _MiniStat(value: todayTasks.toString(), label: "Today's Tasks", icon: Icons.assignment_rounded),
                            Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.18)),
                            _MiniStat(value: openComplaints.toString(), label: 'Open Issues', icon: Icons.report_problem_rounded),
                            Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.18)),
                            _MiniStat(value: '$completionPct%', label: 'Completion', icon: Icons.check_circle_rounded),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── KPI Cards ────────────────────────────────────────────
                const Padding(
                  padding: EdgeInsets.fromLTRB(22, 26, 22, 0),
                  child: Text('Overview', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 162,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    children: [
                      _KpiCard(label: 'Buildings',  value: totalBuildings.toString(), icon: Icons.location_city_rounded,  color: const Color(0xFF1E3D2F), subtitle: 'Active properties'),
                      _KpiCard(label: 'Assets',     value: totalAssets.toString(),    icon: Icons.devices_other_rounded,  color: const Color(0xFF1E5080), subtitle: 'Managed items'),
                      _KpiCard(label: 'Completed',  value: completedTasks.toString(), icon: Icons.task_alt_rounded,       color: const Color(0xFF2D6B4F), subtitle: 'Done today'),
                      _KpiCard(label: 'Resolution', value: resolutionRate,            icon: Icons.verified_rounded,       color: const Color(0xFFA05A10), subtitle: 'Complaint rate'),
                    ],
                  ),
                ),

                // ── Today's Progress ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text("Today's Progress", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEBF2ED),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('$completedTasks / $todayTasks tasks', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E3D2F))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: todayTasks > 0 ? completedTasks / todayTasks : 0,
                            minHeight: 12,
                            backgroundColor: const Color(0xFFEEE8DF),
                            valueColor: const AlwaysStoppedAnimation(Color(0xFF1E3D2F)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _ProgressLegend(color: const Color(0xFF2D6B4F), label: '$completedTasks Completed'),
                            const SizedBox(width: 20),
                            _ProgressLegend(color: const Color(0xFFA05A10), label: '${todayTasks - completedTasks} Remaining'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Recent Activity ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 14),
                  child: Row(
                    children: [
                      const Text('Recent Activity', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                      const Spacer(),
                      Text('${recentActivity.length} items', style: const TextStyle(fontSize: 13, color: Color(0xFF8C8278))),
                    ],
                  ),
                ),

                if (recentActivity.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(color: const Color(0xFFEEE8DF), shape: BoxShape.circle),
                            child: const Icon(Icons.inbox_outlined, size: 34, color: Color(0xFF8C8278)),
                          ),
                          const SizedBox(height: 12),
                          const Text('No recent activity', style: TextStyle(color: Color(0xFF8C8278), fontSize: 15)),
                        ],
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Container(
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
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recentActivity.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0EAE0), indent: 72),
                        itemBuilder: (context, i) {
                          final item = recentActivity[i] as Map<String, dynamic>;
                          final isTask = item['type'] == 'task';
                          final itemColor = isTask ? const Color(0xFF1E3D2F) : const Color(0xFF9B2020);
                          DateTime? time;
                          try { time = DateTime.parse(item['time']).toLocal(); } catch (_) {}
                          final timeStr = time != null
                              ? '${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}'
                              : '--:--';

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: itemColor.withValues(alpha: 0.09),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    isTask ? Icons.task_alt_rounded : Icons.report_problem_rounded,
                                    color: itemColor,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1A1714)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 3),
                                      Text(item['subtitle'] ?? '', style: const TextStyle(color: Color(0xFF8C8278), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(timeStr, style: const TextStyle(fontSize: 13, color: Color(0xFF8C8278), fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: itemColor.withValues(alpha: 0.09),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        item['status'] ?? '',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: itemColor),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                const SizedBox(height: 110),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Mini Stat ─────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _MiniStat({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: Color(0xFFB8D4C4), fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── KPI Card ──────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _KpiCard({required this.label, required this.value, required this.icon, required this.color, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 152,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF4A4540))),
          const SizedBox(height: 1),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF8C8278))),
        ],
      ),
    );
  }
}

// ── Progress Legend ───────────────────────────────────────────────────────────

class _ProgressLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ProgressLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 7),
        Flexible(child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF4A4540), fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
