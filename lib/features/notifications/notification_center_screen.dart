import 'package:flutter/material.dart';
import '../../core/widgets/empty_state.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const EmptyState(
        title: 'No Notifications',
        message: 'You\'re all caught up!',
        icon: Icons.notifications_none,
      ),
    );
  }
}
