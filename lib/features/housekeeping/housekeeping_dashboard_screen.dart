import 'package:flutter/material.dart';
import '../../core/widgets/empty_state.dart';

class HousekeepingDashboardScreen extends StatelessWidget {
  const HousekeepingDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Housekeeping')),
      body: const EmptyState(
        title: 'Housekeeping Dashboard',
        message: 'Monitor washrooms and cleaning schedules.',
        icon: Icons.cleaning_services,
      ),
    );
  }
}
