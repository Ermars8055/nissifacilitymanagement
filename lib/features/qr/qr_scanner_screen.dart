import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class QrScannerScreen extends StatefulWidget {
  final String? expectedCode;
  final String? title;

  const QrScannerScreen({super.key, this.expectedCode, this.title});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  MobileScannerController? _controller;
  bool _hasScanned = false;
  bool _showManualEntry = false;
  bool _torchOn = false;
  bool _permissionGranted = false;
  bool _checkingPermission = true;
  String? _errorMessage;
  final _manualController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    try {
      var status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
      }
      if (!mounted) return;
      if (status.isGranted) {
        final ctrl = MobileScannerController(
          detectionSpeed: DetectionSpeed.normal,
          facing: CameraFacing.back,
        );
        setState(() {
          _controller = ctrl;
          _permissionGranted = true;
          _checkingPermission = false;
        });
      } else {
        setState(() {
          _permissionGranted = false;
          _checkingPermission = false;
          _errorMessage = status.isPermanentlyDenied
              ? 'Camera access is permanently denied.\nPlease enable it in App Settings.'
              : 'Camera permission is required to scan QR codes.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _checkingPermission = false;
        _permissionGranted = false;
        _errorMessage = 'Failed to request camera permission: $e';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _manualController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    _handleCode(barcode!.rawValue!);
  }

  void _handleCode(String code) {
    if (_hasScanned) return;

    if (widget.expectedCode != null && code != widget.expectedCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('Wrong QR code. Expected: ${widget.expectedCode}')),
          ]),
          backgroundColor: const Color(0xFF9B2020),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _hasScanned = true);
    _controller?.stop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(children: [
          Icon(Icons.check_circle, color: Colors.white),
          SizedBox(width: 8),
          Text('QR Code verified!', style: TextStyle(fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: Color(0xFF2D6B4F),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) Navigator.of(context).pop(code);
    });
  }

  String _errorLabel(MobileScannerErrorCode code) {
    switch (code) {
      case MobileScannerErrorCode.permissionDenied:
        return 'Camera permission denied.\nTap "Open Settings" to enable it.';
      case MobileScannerErrorCode.unsupported:
        return 'This device does not support\ncamera-based QR scanning.';
      default:
        return 'Camera failed to start.\nError code: ${code.name}';
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── Permission checking ───────────────────────────────────────────────
    if (_checkingPermission) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    // ── Permission denied ─────────────────────────────────────────────────
    if (!_permissionGranted || _controller == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _CircleBtn(icon: Icons.close_rounded, onTap: () => Navigator.of(context).pop(null)),
                ),
              ),
              const Spacer(),
              const Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 64),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage ?? 'Camera permission required.',
                  style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () async {
                  await openAppSettings();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3D2F),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text('Open Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Camera feed ──────────────────────────────────────────────────
          MobileScanner(
            controller: _controller!,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return Container(
                color: Colors.black,
                child: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _CircleBtn(icon: Icons.close_rounded, onTap: () => Navigator.of(context).pop(null)),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 56),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorLabel(error.errorCode),
                          style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (error.errorCode == MobileScannerErrorCode.permissionDenied) ...[
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: openAppSettings,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                            decoration: BoxDecoration(color: const Color(0xFF1E3D2F), borderRadius: BorderRadius.circular(12)),
                            child: const Text('Open Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                      const Spacer(),
                    ],
                  ),
                ),
              );
            },
          ),

          // ── Dark vignette overlay ────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.85,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),

          // ── UI Overlay ───────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      _CircleBtn(
                        icon: Icons.close_rounded,
                        onTap: () => Navigator.of(context).pop(null),
                      ),
                      Expanded(
                        child: Text(
                          widget.title ?? 'Scan QR Code',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                      _CircleBtn(
                        icon: _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        onTap: () {
                          _controller?.toggleTorch();
                          setState(() => _torchOn = !_torchOn);
                        },
                        active: _torchOn,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Scan frame ───────────────────────────────────────────────
                Column(
                  children: [
                    const Text(
                      'Align QR code within the frame',
                      style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: Stack(
                        children: [
                          // Dimmed frame border
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          // Corner accents — forest green
                          for (final a in [
                            Alignment.topLeft,
                            Alignment.topRight,
                            Alignment.bottomLeft,
                            Alignment.bottomRight,
                          ])
                            Align(
                              alignment: a,
                              child: _CornerAccent(alignment: a),
                            ),
                          // Center icon
                          if (_hasScanned)
                            Center(
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2D6B4F),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // ── Manual entry ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
                  child: _showManualEntry
                      ? _ManualEntryPanel(
                          controller: _manualController,
                          onCancel: () => setState(() => _showManualEntry = false),
                          onConfirm: () {
                            if (_manualController.text.isNotEmpty) {
                              _handleCode(_manualController.text.trim());
                            }
                          },
                        )
                      : GestureDetector(
                          onTap: () => setState(() => _showManualEntry = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.keyboard_rounded, color: Colors.white70, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Enter code manually',
                                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Corner Accent ─────────────────────────────────────────────────────────────

class _CornerAccent extends StatelessWidget {
  final Alignment alignment;
  const _CornerAccent({required this.alignment});

  @override
  Widget build(BuildContext context) {
    final isTop    = alignment == Alignment.topLeft    || alignment == Alignment.topRight;
    final isLeft   = alignment == Alignment.topLeft    || alignment == Alignment.bottomLeft;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        border: Border(
          top:    isTop  ? const BorderSide(color: Color(0xFF2D6B4F), width: 4) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: Color(0xFF2D6B4F), width: 4) : BorderSide.none,
          left:   isLeft  ? const BorderSide(color: Color(0xFF2D6B4F), width: 4) : BorderSide.none,
          right:  !isLeft ? const BorderSide(color: Color(0xFF2D6B4F), width: 4) : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft:     alignment == Alignment.topLeft     ? const Radius.circular(6) : Radius.zero,
          topRight:    alignment == Alignment.topRight    ? const Radius.circular(6) : Radius.zero,
          bottomLeft:  alignment == Alignment.bottomLeft  ? const Radius.circular(6) : Radius.zero,
          bottomRight: alignment == Alignment.bottomRight ? const Radius.circular(6) : Radius.zero,
        ),
      ),
    );
  }
}

// ── Circle Button ─────────────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  const _CircleBtn({required this.icon, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF2D6B4F).withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

// ── Manual Entry Panel ────────────────────────────────────────────────────────

class _ManualEntryPanel extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _ManualEntryPanel({
    required this.controller,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(fontSize: 15, color: Color(0xFF1A1714)),
            decoration: const InputDecoration(
              hintText: 'Enter QR code...',
              hintStyle: TextStyle(color: Color(0xFFAA9F94)),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.qr_code_rounded, color: Color(0xFF8C8278), size: 20),
              prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
              contentPadding: EdgeInsets.symmetric(vertical: 16),
            ),
            onSubmitted: (v) { if (v.isNotEmpty) onConfirm(); },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onCancel,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Center(
                    child: Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: onConfirm,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3D2F),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
