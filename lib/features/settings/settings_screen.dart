import 'package:flutter/material.dart';
import '../../core/widgets/empty_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const EmptyState(
        title: 'System Settings',
        message: 'Configure company branding, SLAs, and categories.',
        icon: Icons.settings,
      ),
    );
  }
}
