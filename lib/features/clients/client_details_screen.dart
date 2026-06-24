import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/section_header.dart';

class ClientDetailsScreen extends StatelessWidget {
  final String clientId;

  const ClientDetailsScreen({Key? key, required this.clientId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ideally we would fetch the client details based on ID. We just use dummy data.
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('Client Details: $clientId'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Overview'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: const Icon(Icons.business, size: 40),
                    ),
                    const SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Client Name Placeholder', style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        const Text('Contact: John Doe | john.doe@example.com'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'SLA Settings'),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Resolution Time: 4 Hours (Critical)'),
                    SizedBox(height: 8),
                    Text('Resolution Time: 24 Hours (Normal)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Associated Buildings'),
            const Card(
              child: ListTile(
                leading: Icon(Icons.business),
                title: Text('Building Placeholder 1'),
                subtitle: Text('Location Placeholder'),
                trailing: Icon(Icons.chevron_right),
              ),
            )
          ],
        ),
      ),
    );
  }
}
