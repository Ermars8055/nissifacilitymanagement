import 'package:flutter/material.dart';
import '../../core/widgets/empty_state.dart';

class PmDashboardScreen extends StatelessWidget {
  const PmDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preventive Maintenance')),
      body: const EmptyState(
        title: 'PM Calendar',
        message: 'No upcoming preventive maintenance scheduled.',
        icon: Icons.event,
      ),
    );
  }
}
