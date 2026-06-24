import 'package:flutter/material.dart';
import '../../core/widgets/empty_state.dart';

class ChecklistLibraryScreen extends StatelessWidget {
  const ChecklistLibraryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checklist Library')),
      body: const EmptyState(
        title: 'No Checklists Found',
        message: 'Create your first checklist template to get started.',
        icon: Icons.checklist,
      ),
    );
  }
}
