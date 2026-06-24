import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/session/session_manager.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Pending', 'In Progress', 'Completed', 'Missed'];
  List<dynamic> allTasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() => isLoading = true);
    final session = SessionManager();
    final bId = session.selectedBuildingId ?? '';
    var url = '/Tasks?buildingId=$bId';
    // Non-admin users only see tasks assigned to them
    if (!session.isAdmin) {
      final uid = session.currentUser?['id'] as String?;
      if (uid != null) url += '&assignedToId=$uid';
    }
    try {
      final tasks = await ApiClient.get(url);
      setState(() {
        allTasks = tasks;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Completed':   return const Color(0xFF2D6B4F);
      case 'Pending':     return const Color(0xFFA05A10);
      case 'In Progress': return const Color(0xFF1E5080);
      case 'Missed':      return const Color(0xFF9B2020);
      default:            return const Color(0xFF8C8278);
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'Completed':   return Icons.check_circle_rounded;
      case 'Pending':     return Icons.schedule_rounded;
      case 'In Progress': return Icons.play_circle_rounded;
      case 'Missed':      return Icons.cancel_rounded;
      default:            return Icons.circle_outlined;
    }
  }

  int _countFor(String filter) =>
      filter == 'All' ? allTasks.length : allTasks.where((t) => t['status'] == filter).length;

  @override
  Widget build(BuildContext context) {
    final tasks = _selectedFilter == 'All'
        ? allTasks
        : allTasks.where((t) => t['status'] == _selectedFilter).toList();

    final activeCount = allTasks.where((t) => t['status'] == 'Pending' || t['status'] == 'In Progress').length;
    final doneCount   = allTasks.where((t) => t['status'] == 'Completed').length;

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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Expanded(
                        child: Text(
                          'Work Orders',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A1714)),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/tasks/add'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3D2F),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 6),
                              Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$activeCount active  ·  $doneCount completed today',
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
                        return GestureDetector(
                          onTap: () => setState(() => _selectedFilter = filter),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF1E3D2F) : const Color(0xFFEEE8DF),
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

            // ── Task List ─────────────────────────────────────────────────
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3D2F)))
                  : tasks.isEmpty
                      ? _EmptyState(filter: _selectedFilter)
                      : RefreshIndicator(
                          onRefresh: _fetchTasks,
                          color: const Color(0xFF1E3D2F),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
                            itemCount: tasks.length,
                            itemBuilder: (context, index) {
                              final task = tasks[index];
                              return _TaskCard(
                                task: task,
                                statusColor: _statusColor(task['status'] ?? 'Pending'),
                                statusIcon: _statusIcon(task['status'] ?? 'Pending'),
                                onTap: () => context.push('/tasks/details/${task['id']}'),
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

// ── Task Card ─────────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final dynamic task;
  final Color statusColor;
  final IconData statusIcon;
  final VoidCallback onTap;

  const _TaskCard({
    required this.task,
    required this.statusColor,
    required this.statusIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheduledTime = DateTime.tryParse(task['scheduledTime'] ?? '')?.toLocal();
    final timeStr = scheduledTime != null
        ? '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}'
        : '--:--';
    final dateStr = scheduledTime != null ? '${scheduledTime.day}/${scheduledTime.month}' : '';

    final assignedName = (task['assignedToName'] as String?) ?? '';
    final initials = assignedName.isNotEmpty
        ? assignedName.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
        : 'FM';
    final firstName = assignedName.split(' ').first;

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
              // Left accent bar
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: statusColor,
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
                      // Status + time
                      Row(
                        children: [
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
                                  task['status'] ?? 'Pending',
                                  style: TextStyle(fontSize: 13, color: statusColor, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(timeStr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                              if (dateStr.isNotEmpty)
                                Text(dateStr, style: const TextStyle(fontSize: 12, color: Color(0xFF8C8278))),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Title
                      Text(
                        task['title'] ?? 'Untitled Task',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1714)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 10),

                      // Location + Assignee
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF8C8278)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${task['entityName'] ?? ''} (${task['entityType'] ?? ''})',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF4A4540)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: const Color(0xFFEBF2ED),
                            child: Text(
                              initials,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E3D2F)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            firstName,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF4A4540), fontWeight: FontWeight.w600),
                          ),
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
              decoration: const BoxDecoration(color: Color(0xFFEBF2ED), shape: BoxShape.circle),
              child: const Icon(Icons.assignment_outlined, size: 40, color: Color(0xFF2D6B4F)),
            ),
            const SizedBox(height: 18),
            Text(
              filter == 'All' ? 'No tasks yet' : 'No $filter tasks',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1714)),
            ),
            const SizedBox(height: 8),
            Text(
              filter == 'All'
                  ? 'Tasks assigned to you will appear here'
                  : 'Try a different filter to see other tasks',
              style: const TextStyle(fontSize: 14, color: Color(0xFF8C8278)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
