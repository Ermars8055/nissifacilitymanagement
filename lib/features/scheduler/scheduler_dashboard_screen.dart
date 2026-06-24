import 'package:flutter/material.dart';
import '../../core/widgets/empty_state.dart';

class SchedulerDashboardScreen extends StatelessWidget {
  const SchedulerDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Scheduler')),
      body: const EmptyState(
        title: 'Schedule Empty',
        message: 'No tasks scheduled for today. Build recurring schedules to automate tasks.',
        icon: Icons.calendar_month,
      ),
    );
  }
}
