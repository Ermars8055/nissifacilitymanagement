import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ClientFormScreen extends StatelessWidget {
  const ClientFormScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('Add New Client'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TextField(decoration: InputDecoration(labelText: 'Client Name')),
              const SizedBox(height: 16),
              const TextField(decoration: InputDecoration(labelText: 'Contact Person')),
              const SizedBox(height: 16),
              const TextField(decoration: InputDecoration(labelText: 'Contact Email')),
              const SizedBox(height: 16),
              const TextField(decoration: InputDecoration(labelText: 'Contact Phone')),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Save Client'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
