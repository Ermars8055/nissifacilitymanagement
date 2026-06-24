import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/network/api_client.dart';
import '../../core/services/offline_queue.dart';

class ChecklistExecutionScreen extends StatefulWidget {
  final String taskId;
  const ChecklistExecutionScreen({super.key, required this.taskId});

  @override
  State<ChecklistExecutionScreen> createState() => _ChecklistExecutionScreenState();
}

class _ChecklistExecutionScreenState extends State<ChecklistExecutionScreen> {
  Map<String, dynamic>? task;
  List<Map<String, dynamic>> items = [];
  final Map<int, dynamic> answers = {};
  final Map<int, TextEditingController> textControllers = {};
  final Map<int, File> photoFiles = {};        // local File selected for photo items
  final Map<int, String> photoUrls = {};       // uploaded URL after upload
  final Map<int, bool> photoUploading = {};    // upload-in-progress per item
  bool isLoading = true;
  bool isSubmitting = false;
  String scannedQr = '';
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra;
    if (extra is String && scannedQr.isEmpty) {
      scannedQr = extra;
    }
  }

  @override
  void dispose() {
    for (final c in textControllers.values) { c.dispose(); }
    super.dispose();
  }

  Future<void> _loadTask() async {
    try {
      final tasks = await ApiClient.get('/Tasks');
      final found = (tasks as List).firstWhere(
        (t) => t['id'] == widget.taskId,
        orElse: () => null,
      );
      if (found == null) {
        setState(() => isLoading = false);
        return;
      }
      task = found as Map<String, dynamic>;

      final templateId = task!['checklistTemplateId'] as String?;
      if (templateId != null && templateId.isNotEmpty) {
        try {
          final template = await ApiClient.get('/Checklists/$templateId');
          final rawItems = jsonDecode(template['itemsJson'] ?? '[]') as List;
          items = rawItems.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } catch (_) {
          items = _defaultItems();
        }
      } else {
        items = _defaultItems();
      }

      for (int i = 0; i < items.length; i++) {
        if (items[i]['type'] == 'text' || items[i]['type'] == 'number') {
          textControllers[i] = TextEditingController();
        }
      }
    } catch (_) {
      items = _defaultItems();
    }
    setState(() => isLoading = false);
  }

  List<Map<String, dynamic>> _defaultItems() {
    return [
      {'id': '1', 'text': 'Location inspected', 'type': 'checkbox'},
      {'id': '2', 'text': 'Task completed as described', 'type': 'checkbox'},
      {'id': '3', 'text': 'Additional notes', 'type': 'text'},
    ];
  }

  bool get _allAnswered {
    for (int i = 0; i < items.length; i++) {
      final type = items[i]['type'] as String? ?? 'checkbox';
      if (type == 'checkbox' && answers[i] == null) return false;
      if ((type == 'text' || type == 'number') && (textControllers[i]?.text.isEmpty ?? true)) return false;
      if (type == 'photo' && photoUrls[i] == null) return false;
    }
    return true;
  }

  Future<void> _pickAndUploadPhoto(int index) async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1280,
      );
      if (picked == null) return;

      final file = File(picked.path);
      setState(() {
        photoFiles[index] = file;
        photoUploading[index] = true;
      });

      final url = await ApiClient.uploadPhoto(file);
      setState(() {
        photoUrls[index] = url;
        photoUploading[index] = false;
      });
    } catch (_) {
      setState(() => photoUploading[index] = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo upload failed. Try again.'), backgroundColor: Color(0xFF9B2020)),
        );
      }
    }
  }

  Future<void> _submit() async {
    setState(() => isSubmitting = true);
    try {
      final noteParts = <String>[];
      for (int i = 0; i < items.length; i++) {
        final type = items[i]['type'] as String? ?? 'checkbox';
        final label = items[i]['text'] as String? ?? '';
        if (type == 'checkbox') {
          noteParts.add('$label: ${answers[i] == true ? "Pass" : "Fail"}');
        } else if (type == 'text' || type == 'number') {
          noteParts.add('$label: ${textControllers[i]?.text ?? ""}');
        } else if (type == 'photo') {
          noteParts.add('$label: ${photoUrls[i] ?? "No photo"}');
        }
      }

      final payload = {
        'qrCodeScanned': scannedQr,
        'notes': noteParts.join(' | '),
        'isVerified': true,
      };

      final online = await ApiClient.isConnected();
      if (online) {
        await ApiClient.put('/Tasks/${widget.taskId}/complete', payload);
      } else {
        // Queue for later sync when back online
        await OfflineQueue().enqueue('PUT', '/Tasks/${widget.taskId}/complete', payload);
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.white,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(color: Color(0xFFEBF2ED), shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Color(0xFF2D6B4F), size: 44),
                ),
                const SizedBox(height: 18),
                const Text('Task Complete!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1714))),
                const SizedBox(height: 8),
                FutureBuilder<bool>(
                  future: ApiClient.isConnected(),
                  builder: (ctx, snap) {
                    final msg = (snap.data == false)
                        ? 'Saved offline. Will sync automatically when you reconnect.'
                        : 'Checklist submitted and task marked as completed.';
                    return Text(
                      msg,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF8C8278), fontSize: 14, height: 1.4),
                    );
                  },
                ),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: () { Navigator.of(context).pop(); context.go('/tasks'); },
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(color: const Color(0xFF1E3D2F), borderRadius: BorderRadius.circular(14)),
                    child: const Center(
                      child: Text('Back to Tasks', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit. Please try again.'), backgroundColor: Color(0xFF9B2020)),
        );
      }
    }
    setState(() => isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F3EC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1E3D2F))),
      );
    }

    final answered = answers.length + textControllers.values.where((c) => c.text.isNotEmpty).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF1A1714)),
          onPressed: () => context.pop(),
        ),
        title: const Text('Execute Checklist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A1714))),
        actions: [
          if (scannedQr.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 14, color: Color(0xFF2D6B4F)),
                    SizedBox(width: 4),
                    Text('QR Verified', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2D6B4F))),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Task title bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task?['title'] ?? 'Task Checklist',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1714)),
                ),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF8C8278)),
                  const SizedBox(width: 4),
                  Text(
                    '${task?['entityName']} (${task?['entityType']})',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF8C8278)),
                  ),
                ]),
              ],
            ),
          ),

          // Progress bar
          LinearProgressIndicator(
            value: items.isEmpty ? 0 : answered / items.length,
            backgroundColor: const Color(0xFFEEE8DF),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF1E3D2F)),
            minHeight: 3,
          ),

          // Checklist items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final type = item['type'] as String? ?? 'checkbox';
                final text = item['text'] as String? ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: const Color(0xFF1A1714).withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 3))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(color: const Color(0xFFEBF2ED), borderRadius: BorderRadius.circular(8)),
                          child: Center(
                            child: Text('${index + 1}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3D2F))),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1714)))),
                        _typeIcon(type),
                      ]),

                      const SizedBox(height: 16),

                      if (type == 'checkbox')
                        Row(children: [
                          Expanded(
                            child: _AnswerButton(
                              label: 'Pass',
                              icon: Icons.check_rounded,
                              selected: answers[index] == true,
                              color: const Color(0xFF2D6B4F),
                              onTap: () => setState(() => answers[index] = true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _AnswerButton(
                              label: 'Fail',
                              icon: Icons.close_rounded,
                              selected: answers[index] == false,
                              color: const Color(0xFF9B2020),
                              onTap: () => setState(() => answers[index] = false),
                            ),
                          ),
                        ])
                      else if (type == 'photo')
                        _PhotoPicker(
                          index: index,
                          file: photoFiles[index],
                          url: photoUrls[index],
                          uploading: photoUploading[index] ?? false,
                          onPick: () => _pickAndUploadPhoto(index),
                        )
                      else
                        TextField(
                          controller: textControllers[index],
                          keyboardType: type == 'number' ? TextInputType.number : TextInputType.text,
                          style: const TextStyle(color: Color(0xFF1A1714), fontSize: 15),
                          decoration: InputDecoration(
                            hintText: type == 'number' ? 'Enter number...' : 'Enter value...',
                            hintStyle: const TextStyle(color: Color(0xFFBBB3A8)),
                            filled: true,
                            fillColor: const Color(0xFFEEE8DF),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E3D2F), width: 1.5)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Submit bar
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEDE7DD))),
            ),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('$answered of ${items.length} answered',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF8C8278))),
                  if (!_allAnswered)
                    const Text('Complete all items to submit', style: TextStyle(fontSize: 13, color: Color(0xFFA05A10))),
                ]),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _allAnswered && !isSubmitting ? _submit : null,
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      color: _allAnswered && !isSubmitting ? const Color(0xFF1E3D2F) : const Color(0xFFDDD5C8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: isSubmitting
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(
                              'Submit Checklist',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _allAnswered ? Colors.white : const Color(0xFF8C8278),
                              ),
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

  Widget _typeIcon(String type) {
    switch (type) {
      case 'text':   return const Icon(Icons.text_fields_rounded, size: 16, color: Color(0xFF8C8278));
      case 'number': return const Icon(Icons.pin_rounded, size: 16, color: Color(0xFF8C8278));
      case 'photo':  return const Icon(Icons.camera_alt_rounded, size: 16, color: Color(0xFF8C8278));
      default:       return const Icon(Icons.check_box_outlined, size: 16, color: Color(0xFF8C8278));
    }
  }
}

class _PhotoPicker extends StatelessWidget {
  final int index;
  final File? file;
  final String? url;
  final bool uploading;
  final VoidCallback onPick;

  const _PhotoPicker({
    required this.index,
    required this.file,
    required this.url,
    required this.uploading,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    if (uploading) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFEEE8DF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator(color: Color(0xFF1E3D2F))),
      );
    }

    if (file != null && url != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(file!, height: 180, width: double.infinity, fit: BoxFit.cover),
          ),
          Positioned(
            top: 8, right: 8,
            child: GestureDetector(
              onTap: onPick,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3D2F),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text('Uploaded', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFEEE8DF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDD5C8)),
        ),
        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.camera_alt_rounded, size: 32, color: Color(0xFF8C8278)),
          SizedBox(height: 8),
          Text('Tap to take photo', style: TextStyle(color: Color(0xFF8C8278), fontSize: 14, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _AnswerButton({required this.label, required this.icon, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 50,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : const Color(0xFFF7F3EC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : const Color(0xFFDDD5C8), width: selected ? 2 : 1),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 18, color: selected ? color : const Color(0xFF8C8278)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: selected ? color : const Color(0xFF8C8278))),
        ]),
      ),
    );
  }
}
