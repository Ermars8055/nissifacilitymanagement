import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/network/api_client.dart';
import '../../core/services/session_service.dart';
import '../../core/session/session_manager.dart';

class AttendanceCheckinScreen extends StatefulWidget {
  final String buildingId;
  final String buildingName;

  const AttendanceCheckinScreen({
    super.key,
    required this.buildingId,
    required this.buildingName,
  });

  @override
  State<AttendanceCheckinScreen> createState() => _AttendanceCheckinScreenState();
}

class _AttendanceCheckinScreenState extends State<AttendanceCheckinScreen> {
  bool _loading = false;
  String? _statusMessage;
  bool? _success;

  Future<void> _startCheckin() async {
    setState(() {
      _loading = true;
      _statusMessage = 'Getting your location...';
      _success = null;
    });

    try {
      // 1. Request location permission
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        _setError('Location permission required.\nGo to Settings → App Permissions → Location.');
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError('Please enable Location Services on your device and try again.');
        return;
      }

      setState(() => _statusMessage = 'Locking GPS position...');

      // 2. Get precise position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      // 3. Block fake GPS apps
      if (position.isMocked) {
        _setError('Fake GPS detected! Disable mock location apps and try again.');
        return;
      }

      setState(() => _statusMessage = 'Verifying location...');

      // 4. POST to backend — no QR needed, GPS only
      final workerId = SessionManager().currentUserId ?? '';
      final response = await ApiClient.post('/Sessions/start', {
        'workerId': workerId,
        'buildingId': widget.buildingId,
        'lobbyQrCode': '',
        'userLat': position.latitude,
        'userLng': position.longitude,
        'isMockLocation': false,
      }) as Map<String, dynamic>;

      SessionService().setSession(response);
      final dist = (response['distanceMetres'] as num?)?.toDouble() ?? 0;

      setState(() {
        _loading = false;
        _success = true;
        _statusMessage = 'You are verified on-site!\n${dist.toStringAsFixed(0)}m from building entrance.';
      });
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('outside_geofence')) {
        _setError('You are too far from ${widget.buildingName}.\nPlease be within 40m of the building to check in.');
      } else if (msg.contains('mock_location')) {
        _setError('Fake GPS detected! Disable mock location apps and try again.');
      } else {
        _setError('Check-in failed. Make sure you are at the building.\n$msg');
      }
    }
  }

  void _setError(String msg) {
    setState(() { _loading = false; _success = false; _statusMessage = msg; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF1A1714)),
          onPressed: () => Navigator.of(context).pop(_success == true),
        ),
        title: const Text('Attendance Check-In',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Building card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: const Color(0xFF1A1714).withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.business_rounded, color: Color(0xFF2D6B4F), size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.buildingName,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                          const SizedBox(height: 3),
                          const Text('Tap below to verify you are on-site',
                              style: TextStyle(fontSize: 13, color: Color(0xFF8C8278))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              _StepRow(step: '1', icon: Icons.location_on_outlined,   label: 'GPS captures your exact position automatically'),
              const SizedBox(height: 14),
              _StepRow(step: '2', icon: Icons.security_rounded,        label: 'Fake GPS apps are blocked automatically'),
              const SizedBox(height: 14),
              _StepRow(step: '3', icon: Icons.check_circle_outline_rounded, label: 'Server confirms you are within 40m of the building'),

              const Spacer(),

              if (_statusMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _success == true ? const Color(0xFFEBF2ED) : _success == false ? const Color(0xFFF9ECEC) : const Color(0xFFF3EFE9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _success == true ? const Color(0xFF2D6B4F) : _success == false ? const Color(0xFF9B2020) : const Color(0xFFDDD5C8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _success == true ? Icons.check_circle_rounded : _success == false ? Icons.error_rounded : Icons.info_outline_rounded,
                        color: _success == true ? const Color(0xFF2D6B4F) : _success == false ? const Color(0xFF9B2020) : const Color(0xFF8C8278),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_statusMessage!, style: TextStyle(
                        fontSize: 14, height: 1.4,
                        color: _success == true ? const Color(0xFF1E3D2F) : _success == false ? const Color(0xFF7A1515) : const Color(0xFF4A4540),
                      ))),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              if (_success == true)
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(true),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(color: const Color(0xFF2D6B4F), borderRadius: BorderRadius.circular(16)),
                    child: const Center(child: Text('Start Working', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold))),
                  ),
                )
              else
                GestureDetector(
                  onTap: _loading ? null : _startCheckin,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: _loading ? const Color(0xFF2D6B4F).withValues(alpha: 0.6) : const Color(0xFF1E3D2F),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _loading
                        ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)))
                        : const Center(child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.my_location_rounded, color: Colors.white, size: 22),
                              SizedBox(width: 10),
                              Text('Verify My Location', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                            ],
                          )),
                  ),
                ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String step;
  final IconData icon;
  final String label;
  const _StepRow({required this.step, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(step, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E3D2F)))),
        ),
        const SizedBox(width: 14),
        Icon(icon, size: 20, color: const Color(0xFF2D6B4F)),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF4A4540)))),
      ],
    );
  }
}
