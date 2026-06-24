import 'package:flutter/material.dart';
import '../../core/widgets/empty_state.dart';

class UserListScreen extends StatelessWidget {
  const UserListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: const EmptyState(
        title: 'Manage Users',
        message: 'Add workers, managers, and clients here.',
        icon: Icons.people,
      ),
    );
  }
}
