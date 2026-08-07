import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import 'package:intl/intl.dart';

class AssetScanResultScreen extends StatefulWidget {
  final String qrCode;
  
  const AssetScanResultScreen({super.key, required this.qrCode});

  @override
  State<AssetScanResultScreen> createState() => _AssetScanResultScreenState();
}

class _AssetScanResultScreenState extends State<AssetScanResultScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _asset;
  List<dynamic> _tasks = [];

  @override
  void initState() {
    super.initState();
    _fetchAssetData();
  }

  Future<void> _fetchAssetData() async {
    try {
      final response = await ApiClient.get('/Assets/by-qr/${widget.qrCode}');
      if (response != null && response['asset'] != null) {
        setState(() {
          _asset = response['asset'];
          _tasks = response['tasks'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Asset not found for this QR code.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load asset details: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EC),
      appBar: AppBar(
        title: const Text('Asset Context', style: TextStyle(color: Color(0xFF1A1714), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1714)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2D6B4F)));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 64),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Color(0xFF4A4540))),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3D2F)),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (_asset == null) return const SizedBox.shrink();

    final todayTasks = _tasks.where((t) {
      if (t['scheduledTime'] == null) return false;
      final date = DateTime.parse(t['scheduledTime']).toLocal();
      final now = DateTime.now();
      return date.year == now.year && date.month == now.month && date.day == now.day;
    }).toList();

    final historyTasks = _tasks.where((t) {
      if (t['scheduledTime'] == null) return false;
      final date = DateTime.parse(t['scheduledTime']).toLocal();
      final now = DateTime.now();
      return date.isBefore(DateTime(now.year, now.month, now.day));
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAssetHeader(),
          const SizedBox(height: 24),
          if (todayTasks.isNotEmpty) ...[
            const Text("Today's Tasks", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
            const SizedBox(height: 12),
            ...todayTasks.map((t) => _buildTaskCard(t, true)).toList(),
            const SizedBox(height: 24),
          ],
          const Text("Maintenance History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
          const SizedBox(height: 12),
          if (historyTasks.isEmpty)
            const Text("No past maintenance records.", style: TextStyle(color: Color(0xFF8C8278), fontStyle: FontStyle.italic))
          else
            ...historyTasks.map((t) => _buildTaskCard(t, false)).toList(),
        ],
      ),
    );
  }

  Widget _buildAssetHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(_asset!['name'] ?? 'Unknown Asset', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1714)))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _asset!['status'] == 'Active' ? const Color(0xFFEBF2ED) : const Color(0xFFFDE8E8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _asset!['status'] ?? 'Unknown',
                  style: TextStyle(
                    color: _asset!['status'] == 'Active' ? const Color(0xFF2D6B4F) : Colors.red[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_asset!['category'] ?? 'Uncategorized', style: const TextStyle(fontSize: 14, color: Color(0xFF8C8278), fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.pin_drop_rounded, '${_asset!['building'] ?? ''} - ${_asset!['room'] ?? ''}'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.qr_code_2_rounded, _asset!['qrCode'] ?? ''),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.tag_rounded, 'S/N: ${_asset!['serialNumber'] ?? 'N/A'}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF8C8278)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF4A4540)))),
      ],
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, bool isToday) {
    final dt = task['scheduledTime'] != null ? DateTime.parse(task['scheduledTime']).toLocal() : null;
    final dateStr = dt != null ? DateFormat('MMM dd, yyyy - hh:mm a').format(dt) : 'Unknown Time';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isToday ? const Color(0xFFF2F6F8) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isToday ? const Color(0xFF1E5080).withOpacity(0.2) : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(task['title'] ?? 'Task', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1714)))),
              _buildTaskStatus(task['status'] ?? 'Pending'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF8C8278)),
              const SizedBox(width: 6),
              Text(dateStr, style: const TextStyle(fontSize: 13, color: Color(0xFF8C8278))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person_rounded, size: 14, color: Color(0xFF8C8278)),
              const SizedBox(width: 6),
              Text(task['assignedToName']?.isNotEmpty == true ? task['assignedToName'] : 'Unassigned', 
                style: const TextStyle(fontSize: 13, color: Color(0xFF4A4540), fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskStatus(String status) {
    Color bg, text;
    switch (status) {
      case 'Completed': bg = const Color(0xFFEBF2ED); text = const Color(0xFF2D6B4F); break;
      case 'In Progress': bg = const Color(0xFFFFF7E6); text = const Color(0xFFD97706); break;
      case 'Missed': bg = const Color(0xFFFDE8E8); text = Colors.red[700]!; break;
      default: bg = const Color(0xFFF1F3F5); text = const Color(0xFF495057); break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
