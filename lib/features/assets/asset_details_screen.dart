import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/network/api_client.dart';

class AssetDetailsScreen extends StatefulWidget {
  final String assetId;
  const AssetDetailsScreen({super.key, required this.assetId});

  @override
  State<AssetDetailsScreen> createState() => _AssetDetailsScreenState();
}

class _AssetDetailsScreenState extends State<AssetDetailsScreen> {
  Map<String, dynamic>? asset;
  List<dynamic> taskHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final results = await Future.wait([
        ApiClient.get('/Assets/${widget.assetId}'),
        ApiClient.get('/Tasks?entityId=${widget.assetId}').catchError((_) => <dynamic>[]),
      ]);
      setState(() {
        asset = results[0] as Map<String, dynamic>;
        taskHistory = results[1] as List<dynamic>;
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Active':            return const Color(0xFF2D6B4F);
      case 'Needs Repair':      return const Color(0xFF9B2020);
      case 'Under Maintenance': return const Color(0xFFA05A10);
      case 'Retired':           return const Color(0xFF8C8278);
      default:                  return const Color(0xFF8C8278);
    }
  }

  void _showQrDialog() {
    final qrValue = asset?['qrCodeValue'] as String? ?? widget.assetId;
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: const Color(0xFFF7F3EC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Asset QR Code', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
              const SizedBox(height: 6),
              Text(asset?['name'] ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF8C8278))),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDDD5C8)),
                ),
                child: QrImageView(data: qrValue, version: QrVersions.auto, size: 180),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(10)),
                child: Text(qrValue, style: const TextStyle(fontSize: 11, color: Color(0xFF2D6B4F))),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(dialogCtx),
                child: Container(
                  width: double.infinity,
                  height: 46,
                  decoration: BoxDecoration(color: const Color(0xFFEEE8DF), borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('Close', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4A4540)))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F3EC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1E3D2F))),
      );
    }

    if (asset == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F3EC),
        body: Column(children: [
          _Header(title: 'Asset Details'),
          const Expanded(child: Center(child: Text('Asset not found.', style: TextStyle(color: Color(0xFF8C8278))))),
        ]),
      );
    }

    final status = asset!['status'] as String? ?? 'Active';
    final statusColor = _statusColor(status);
    final categoryName = asset!['category']?['name'] as String? ?? '—';
    final roomName = asset!['room']?['name'] as String? ?? 'General Building';
    final fieldValues = asset!['fieldValues'] as List? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EC),
      body: Column(
        children: [
          _Header(title: asset!['name'] as String? ?? 'Asset Details'),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchData,
              color: const Color(0xFF1E3D2F),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: _cardDecor(),
                      child: Row(
                        children: [
                          Container(
                            width: 72, height: 72,
                            decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.inventory_2_outlined, size: 34, color: Color(0xFF1E3D2F)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(asset!['name'] ?? '', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                                const SizedBox(height: 4),
                                Text(categoryName, style: const TextStyle(fontSize: 13, color: Color(0xFF8C8278))),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: _showQrDialog,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF1E3D2F), size: 28),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Location card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: _cardDecor(),
                      child: Column(
                        children: [
                          _InfoRow(Icons.location_on_outlined, 'Location', roomName),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, color: Color(0xFFEDE7DD))),
                          _InfoRow(Icons.category_outlined, 'Category', categoryName),
                        ],
                      ),
                    ),

                    // Custom fields
                    if (fieldValues.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: _cardDecor(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Specifications', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                            const SizedBox(height: 14),
                            ...fieldValues.asMap().entries.map((e) {
                              final fv = e.value;
                              final isLast = e.key == fieldValues.length - 1;
                              return Column(
                                children: [
                                  _InfoRow(Icons.label_outline_rounded, fv['fieldName'] as String? ?? '', fv['value'] as String? ?? '—'),
                                  if (!isLast) const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, color: Color(0xFFEDE7DD))),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Maintenance history
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: _cardDecor(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('Maintenance History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFFEEE8DF), borderRadius: BorderRadius.circular(8)),
                                child: Text('${taskHistory.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4A4540))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (taskHistory.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(child: Text('No maintenance tasks recorded yet.', style: TextStyle(fontSize: 13, color: Color(0xFF8C8278)))),
                            )
                          else
                            ...taskHistory.asMap().entries.map((e) {
                              final task = e.value;
                              final isLast = e.key == taskHistory.length - 1;
                              final ts = task['status'] as String? ?? '';
                              final dt = DateTime.tryParse(task['scheduledTime'] ?? '')?.toLocal();
                              final dateStr = dt != null ? '${dt.day}/${dt.month}/${dt.year}' : '—';
                              final isDone = ts == 'Completed';
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 36, height: 36,
                                        decoration: BoxDecoration(
                                          color: isDone ? const Color(0xFFEBF2ED) : const Color(0xFFEEE8DF),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          isDone ? Icons.check_circle_rounded : Icons.schedule_rounded,
                                          size: 18,
                                          color: isDone ? const Color(0xFF2D6B4F) : const Color(0xFF8C8278),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(task['title'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1714))),
                                            Text('${task['assignedToName'] ?? '—'}  ·  $dateStr', style: const TextStyle(fontSize: 12, color: Color(0xFF8C8278))),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isDone ? const Color(0xFFEBF2ED) : const Color(0xFFEEE8DF),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(ts, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDone ? const Color(0xFF2D6B4F) : const Color(0xFF8C8278))),
                                      ),
                                    ],
                                  ),
                                  if (!isLast) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFEDE7DD))),
                                ],
                              );
                            }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // QR tap banner
                    GestureDetector(
                      onTap: _showQrDialog,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF2ED),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF2D6B4F).withValues(alpha: 0.2)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.qr_code_2_rounded, color: Color(0xFF1E3D2F), size: 28),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('View Asset QR Code', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3D2F), fontSize: 15)),
                                  SizedBox(height: 2),
                                  Text('Tap to display the QR code for scanning', style: TextStyle(fontSize: 12, color: Color(0xFF2D6B4F))),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: Color(0xFF2D6B4F)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecor() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [BoxShadow(color: const Color(0xFF1A1714).withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4))],
  );
}

class _Header extends StatelessWidget {
  final String title;
  const _Header({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E3D2F),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.canPop() ? context.pop() : null,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, size: 19, color: const Color(0xFF1E3D2F)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF8C8278), fontWeight: FontWeight.w500)),
              const SizedBox(height: 3),
              Text(value, style: const TextStyle(fontSize: 15, color: Color(0xFF1A1714), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
