import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ClientListScreen extends StatelessWidget {
  const ClientListScreen({super.key});

  final List<Map<String, dynamic>> _clients = const [
    {
      'id': 'CL-1048',
      'name': 'Apex Industries',
      'sites': '14 Locations',
      'sqft': '1.2M',
      'contact': 'Sarah Jenkins (Director)',
      'email': 's.jenkins@apex.com',
      'status': 'ACTIVE',
      'statusColor': Color(0xFF10B981),
      'setupLabel': null,
      'icon': Icons.domain_rounded,
      'iconBg': Color(0xFF2563EB),
      'complianceReq': null,
    },
    {
      'id': 'CL-2051',
      'name': 'Mercy Health Net',
      'sites': '3 Campuses',
      'sqft': null,
      'contact': 'Dr. Alan Grant',
      'email': '555-0199 ext 44',
      'status': 'ACTIVE',
      'statusColor': Color(0xFF10B981),
      'setupLabel': null,
      'icon': Icons.local_hospital_rounded,
      'iconBg': Color(0xFF6366F1),
      'complianceReq': 'Strict (OSHA/PD)',
    },
    {
      'id': 'CL-4001',
      'name': 'Nexus Retail Group',
      'sites': '—',
      'sqft': null,
      'contact': 'Elena Rostova',
      'email': 'erostova@nexus.io',
      'status': 'PENDING CONTRACT',
      'statusColor': Color(0xFFF59E0B),
      'setupLabel': 'Setup',
      'estStart': 'Oct 1, 2024',
      'icon': Icons.store_rounded,
      'iconBg': Color(0xFF10B981),
      'complianceReq': null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.business_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Facility Pro',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF111827)),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.search_rounded, color: Color(0xFF6B7280)),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Client Management',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                  ),
                  const Text(
                    'Manage corporate accounts and assigned properties.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/clients/create'),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Client', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const TextField(
                            decoration: InputDecoration(
                              hintText: 'Search clients by name or il...',
                              hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                              prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 18),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.tune_rounded, color: Color(0xFF6B7280), size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Client list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _clients.length,
                itemBuilder: (context, index) {
                  return _ClientCard(
                    client: _clients[index],
                    onTap: () => context.go('/clients/details/${_clients[index]['id']}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final Map<String, dynamic> client;
  final VoidCallback onTap;

  const _ClientCard({required this.client, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = client['statusColor'] as Color;
    final isPending = client['status'] == 'PENDING CONTRACT';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: icon + name + menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (client['iconBg'] as Color).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(client['icon'] as IconData, color: client['iconBg'] as Color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client['name'],
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                      ),
                      Text(
                        'ID: ${client['id']}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_vert_rounded, color: Color(0xFF9CA3AF), size: 20),
              ],
            ),
            const SizedBox(height: 14),
            // Stats row
            Row(
              children: [
                Expanded(
                  child: _StatCell(
                    label: 'Managed Sites',
                    value: client['sites'] ?? '—',
                  ),
                ),
                if (client['sqft'] != null)
                  Expanded(
                    child: _StatCell(
                      label: 'Total Sq Ft',
                      value: client['sqft'],
                    ),
                  ),
                if (client['complianceReq'] != null)
                  Expanded(
                    child: _StatCell(
                      label: 'Compliance Req',
                      value: client['complianceReq'],
                      valueSize: 11,
                    ),
                  ),
                if (client['estStart'] != null)
                  Expanded(
                    child: _StatCell(
                      label: 'Est. Start',
                      value: client['estStart'],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Contact
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 4),
                Text(
                  client['contact'],
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.mail_outline_rounded, size: 14, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 4),
                Text(
                  client['email'],
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Status + action row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    client['status'],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const Spacer(),
                if (isPending && client['setupLabel'] != null)
                  TextButton(
                    onPressed: onTap,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      backgroundColor: const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          client['setupLabel'],
                          style: const TextStyle(fontSize: 13, color: Color(0xFF374151), fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF374151)),
                      ],
                    ),
                  )
                else
                  TextButton(
                    onPressed: onTap,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      backgroundColor: const Color(0xFFEFF6FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Row(
                      children: [
                        Text(
                          'View Details',
                          style: TextStyle(fontSize: 13, color: Color(0xFF2563EB), fontWeight: FontWeight.w500),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF2563EB)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final double? valueSize;

  const _StatCell({required this.label, required this.value, this.valueSize});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: valueSize ?? 13, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
      ],
    );
  }
}
