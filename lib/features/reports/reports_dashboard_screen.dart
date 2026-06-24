import 'package:flutter/material.dart';
import '../../core/widgets/empty_state.dart';

class ReportsDashboardScreen extends StatelessWidget {
  const ReportsDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Analytics')),
      body: const EmptyState(
        title: 'Analytics Empty',
        message: 'Not enough data to generate reports yet.',
        icon: Icons.analytics,
      ),
    );
  }
}
