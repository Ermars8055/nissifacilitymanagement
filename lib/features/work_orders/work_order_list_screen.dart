import 'package:flutter/material.dart';
import '../../core/widgets/empty_state.dart';

class WorkOrderListScreen extends StatelessWidget {
  const WorkOrderListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Work Orders')),
      body: const EmptyState(
        title: 'No Work Orders',
        message: 'All work orders have been completed.',
        icon: Icons.build,
      ),
    );
  }
}
