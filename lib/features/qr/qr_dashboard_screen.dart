import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/session_service.dart';
import '../../core/session/session_manager.dart';
import '../attendance/attendance_checkin_screen.dart';
import 'qr_scanner_screen.dart';

class QrDashboardScreen extends StatefulWidget {
  const QrDashboardScreen({super.key});

  @override
  State<QrDashboardScreen> createState() => _QrDashboardScreenState();
}

class _QrDashboardScreenState extends State<QrDashboardScreen> {
  String? _lastScanned;
  DateTime? _lastScannedAt;

  Future<void> _openScanner() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const QrScannerScreen(title: 'Scan QR Code'),
        fullscreenDialog: true,
      ),
    );
    if (result != null && mounted) {
      HapticFeedback.mediumImpact();
      setState(() {
        _lastScanned = result;
        _lastScannedAt = DateTime.now();
      });
      _showResultSheet(result);
    }
  }

  void _showResultSheet(String code) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ScanResultSheet(
        code: code,
        onViewTasks: () { Navigator.pop(context); context.push('/tasks'); },
        onViewAssets: () { Navigator.pop(context); context.push('/assets'); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEE8DF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1A1714)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text('QR Scanner', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Padding(
                    padding: EdgeInsets.only(left: 54),
                    child: Text('Verify location and start tasks instantly', style: TextStyle(fontSize: 14, color: Color(0xFF8C8278))),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    // Main scan button card
                    GestureDetector(
                      onTap: _openScanner,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3D2F),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E3D2F).withValues(alpha: 0.35),
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // QR frame icon
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Icon(Icons.qr_code_rounded, size: 60, color: Colors.white.withValues(alpha: 0.9)),
                                  ),
                                  for (final corner in [Alignment.topLeft, Alignment.topRight, Alignment.bottomLeft, Alignment.bottomRight])
                                    Align(
                                      alignment: corner,
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        margin: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            top:    (corner == Alignment.topLeft    || corner == Alignment.topRight)    ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
                                            bottom: (corner == Alignment.bottomLeft || corner == Alignment.bottomRight) ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
                                            left:   (corner == Alignment.topLeft    || corner == Alignment.bottomLeft)  ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
                                            right:  (corner == Alignment.topRight   || corner == Alignment.bottomRight) ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 26),
                            const Text('Tap to Start Scanning', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(
                              'Point your camera at a QR code\nposted at any facility location',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, height: 1.5),
                            ),
                            const SizedBox(height: 26),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF1E3D2F), size: 22),
                                  SizedBox(width: 10),
                                  Text('Open Camera', style: TextStyle(color: Color(0xFF1E3D2F), fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Attendance check-in card
                    _AttendanceCard(),

                    const SizedBox(height: 22),

                    // Last scan result
                    if (_lastScanned != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF1A1714).withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.history_rounded, size: 16, color: Color(0xFF8C8278)),
                                SizedBox(width: 6),
                                Text('Last Scanned', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF8C8278), letterSpacing: 0.5)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF2D6B4F), size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_lastScanned!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1714)), overflow: TextOverflow.ellipsis),
                                      if (_lastScannedAt != null) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          'Scanned at ${_lastScannedAt!.hour.toString().padLeft(2,'0')}:${_lastScannedAt!.minute.toString().padLeft(2,'0')}',
                                          style: const TextStyle(fontSize: 13, color: Color(0xFF8C8278)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                    ],

                    // How it works
                    _HowItWorksCard(),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Attendance Check-In Card ───────────────────────────────────────────────────

class _AttendanceCard extends StatefulWidget {
  @override
  State<_AttendanceCard> createState() => _AttendanceCardState();
}

class _AttendanceCardState extends State<_AttendanceCard> {
  bool _hasSession = false;
  double? _distance;

  @override
  void initState() {
    super.initState();
    SessionService().addListener(_onSessionChange);
    _hasSession = SessionService().hasSession;
    _distance = SessionService().lastDistanceMetres;
  }

  @override
  void dispose() {
    SessionService().removeListener(_onSessionChange);
    super.dispose();
  }

  void _onSessionChange() {
    if (mounted) {
      setState(() {
        _hasSession = SessionService().hasSession;
        _distance = SessionService().lastDistanceMetres;
      });
    }
  }

  Future<void> _openCheckin() async {
    final buildingId = SessionManager().selectedBuildingId;
    final buildingName = SessionManager().selectedBuildingName ?? 'Building';
    if (buildingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a building first before checking in.'),
          backgroundColor: Color(0xFFA05A10),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AttendanceCheckinScreen(buildingId: buildingId, buildingName: buildingName),
    ));
    setState(() {
      _hasSession = SessionService().hasSession;
      _distance = SessionService().lastDistanceMetres;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _hasSession ? null : _openCheckin,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hasSession ? const Color(0xFF2D6B4F) : const Color(0xFFDDD5C8),
          ),
          boxShadow: [BoxShadow(color: const Color(0xFF1A1714).withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _hasSession ? const Color(0xFFEBF2ED) : const Color(0xFFF3EFE9),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                _hasSession ? Icons.verified_rounded : Icons.fingerprint_rounded,
                color: _hasSession ? const Color(0xFF2D6B4F) : const Color(0xFF8C8278),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hasSession ? 'Attendance Verified' : 'Attendance Check-In',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _hasSession ? const Color(0xFF1E3D2F) : const Color(0xFF1A1714),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _hasSession
                        ? 'Active session · ${_distance != null ? "${_distance!.toStringAsFixed(0)}m from entrance" : "GPS confirmed"}'
                        : 'Tap to verify you are on-site before starting tasks',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF8C8278)),
                  ),
                ],
              ),
            ),
            if (!_hasSession)
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF8C8278), size: 20),
          ],
        ),
      ),
    );
  }
}

// ── How it works ──────────────────────────────────────────────────────────────

class _HowItWorksCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1A1714).withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How It Works', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
          const SizedBox(height: 18),
          _Step(number: '1', icon: Icons.location_on_outlined,        title: 'Go to location',     subtitle: 'Walk to the room, floor, or asset assigned to your task'),
          const SizedBox(height: 14),
          _Step(number: '2', icon: Icons.qr_code_scanner_rounded,     title: 'Scan the QR code',  subtitle: 'Point your camera at the QR code posted at the location'),
          const SizedBox(height: 14),
          _Step(number: '3', icon: Icons.assignment_turned_in_rounded, title: 'Complete checklist', subtitle: 'Verified presence unlocks the task checklist for execution'),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String subtitle;

  const _Step({required this.number, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(number, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E3D2F)))),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1714))),
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF8C8278), height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Scan result bottom sheet ──────────────────────────────────────────────────

class _ScanResultSheet extends StatelessWidget {
  final String code;
  final VoidCallback onViewTasks;
  final VoidCallback onViewAssets;

  const _ScanResultSheet({required this.code, required this.onViewTasks, required this.onViewAssets});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFDDD5C8), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 22),
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(color: Color(0xFFEBF2ED), shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Color(0xFF2D6B4F), size: 36),
          ),
          const SizedBox(height: 16),
          const Text('QR Code Scanned!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFFEEE8DF), borderRadius: BorderRadius.circular(10)),
            child: Text(code, style: const TextStyle(fontSize: 14, color: Color(0xFF4A4540), fontFamily: 'monospace')),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _SheetAction(icon: Icons.assignment_rounded,  label: 'View Tasks',  color: const Color(0xFF1E3D2F), onTap: onViewTasks)),
              const SizedBox(width: 12),
              Expanded(child: _SheetAction(icon: Icons.devices_rounded,     label: 'View Assets', color: const Color(0xFF1E5080), onTap: onViewAssets)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Dismiss', style: TextStyle(color: Color(0xFF8C8278), fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SheetAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 7),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
