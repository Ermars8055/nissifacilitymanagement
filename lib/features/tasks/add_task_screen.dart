import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/session/session_manager.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String? _selectedBuildingId;
  String? _selectedBuildingName;
  String? _selectedAssetId;
  String? _selectedAssetName;
  String? _selectedUserId;
  String? _selectedUserName;
  DateTime _scheduledTime = DateTime.now().add(const Duration(hours: 1));

  List<dynamic> _buildings = [];
  List<dynamic> _assets = [];
  List<dynamic> _users = [];

  bool _loadingBuildings = true;
  bool _loadingAssets = false;
  bool _loadingUsers = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill building from session if available
    final session = SessionManager();
    if (session.selectedBuildingId != null) {
      _selectedBuildingId = session.selectedBuildingId;
      _selectedBuildingName = session.selectedBuildingName;
    }
    _fetchData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    await Future.wait([_fetchBuildings(), _fetchUsers()]);
    if (_selectedBuildingId != null) {
      await _fetchAssets(_selectedBuildingId!);
    }
  }

  Future<void> _fetchBuildings() async {
    try {
      final clients = await ApiClient.get('/Hierarchy/clients');
      final List<dynamic> all = [];
      for (final client in clients) {
        final bList = await ApiClient.get('/Hierarchy/buildings/${client['id']}');
        all.addAll(bList);
      }
      if (mounted) setState(() { _buildings = all; _loadingBuildings = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingBuildings = false);
    }
  }

  Future<void> _fetchUsers() async {
    try {
      final data = await ApiClient.get('/Users');
      if (mounted) setState(() { _users = data; _loadingUsers = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  Future<void> _fetchAssets(String buildingId) async {
    setState(() { _loadingAssets = true; _selectedAssetId = null; _selectedAssetName = null; _assets = []; });
    try {
      final data = await ApiClient.get('/Assets/building/$buildingId');
      if (mounted) setState(() { _assets = data; _loadingAssets = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingAssets = false);
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1E3D2F),
            onPrimary: Colors.white,
            surface: Color(0xFFF7F3EC),
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledTime),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1E3D2F),
            onPrimary: Colors.white,
            surface: Color(0xFFF7F3EC),
          ),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    setState(() {
      _scheduledTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showError('Please enter a task title.');
      return;
    }
    if (_selectedBuildingId == null) {
      _showError('Please select a building.');
      return;
    }
    if (_selectedUserId == null) {
      _showError('Please assign this task to someone.');
      return;
    }

    setState(() => _submitting = true);

    final entityId = _selectedAssetId ?? _selectedBuildingId!;
    final entityType = _selectedAssetId != null ? 'Asset' : 'Building';
    final entityName = _selectedAssetName ?? _selectedBuildingName ?? '';

    try {
      await ApiClient.post('/Tasks', {
        'title': title,
        'description': _descController.text.trim(),
        'buildingId': _selectedBuildingId,
        'entityId': entityId,
        'entityType': entityType,
        'entityName': entityName,
        'assignedToName': _selectedUserName,
        'assignedToId': _selectedUserId,
        'scheduledTime': _scheduledTime.toUtc().toIso8601String(),
        'status': 'Pending',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Task created successfully!'),
          backgroundColor: const Color(0xFF1E3D2F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        _showError('Failed to create task. Please try again.');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF9B2020),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  ·  $h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EC),
      body: Column(
        children: [
          // ── Header ───────────────────────────────────────────────────
          Container(
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
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Create Task',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Form ─────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  _SectionLabel('Task Title'),
                  const SizedBox(height: 8),
                  _TextField(
                    controller: _titleController,
                    hint: 'e.g. HVAC filter replacement',
                    icon: Icons.title_rounded,
                  ),

                  const SizedBox(height: 18),

                  // Description
                  _SectionLabel('Description'),
                  const SizedBox(height: 8),
                  _TextField(
                    controller: _descController,
                    hint: 'Optional notes or instructions…',
                    icon: Icons.notes_rounded,
                    maxLines: 3,
                  ),

                  const SizedBox(height: 18),

                  // Building
                  _SectionLabel('Building'),
                  const SizedBox(height: 8),
                  _DropdownField(
                    value: _selectedBuildingId,
                    hint: _loadingBuildings ? 'Loading…' : 'Select building',
                    icon: Icons.apartment_rounded,
                    items: _buildings
                        .map((b) => DropdownMenuItem<String>(
                              value: b['id'] as String,
                              child: Text(b['name'] as String),
                            ))
                        .toList(),
                    onChanged: _loadingBuildings
                        ? null
                        : (v) {
                            final b = _buildings.firstWhere((x) => x['id'] == v, orElse: () => null);
                            setState(() {
                              _selectedBuildingId = v;
                              _selectedBuildingName = b?['name'] as String?;
                            });
                            if (v != null) _fetchAssets(v);
                          },
                  ),

                  const SizedBox(height: 18),

                  // Asset (optional)
                  _SectionLabel('Asset (optional)'),
                  const SizedBox(height: 8),
                  _DropdownField(
                    value: _selectedAssetId,
                    hint: _loadingAssets
                        ? 'Loading assets…'
                        : _selectedBuildingId == null
                            ? 'Select a building first'
                            : _assets.isEmpty
                                ? 'No assets in this building'
                                : 'Link to a specific asset',
                    icon: Icons.inventory_2_outlined,
                    items: _assets
                        .map((a) => DropdownMenuItem<String>(
                              value: a['id'] as String,
                              child: Text(
                                '${a['name']}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: _selectedBuildingId == null || _assets.isEmpty
                        ? null
                        : (v) {
                            final a = _assets.firstWhere((x) => x['id'] == v, orElse: () => null);
                            setState(() {
                              _selectedAssetId = v;
                              _selectedAssetName = a?['name'] as String?;
                            });
                          },
                  ),

                  const SizedBox(height: 18),

                  // Assign to
                  _SectionLabel('Assign To'),
                  const SizedBox(height: 8),
                  _DropdownField(
                    value: _selectedUserId,
                    hint: _loadingUsers ? 'Loading users…' : 'Select team member',
                    icon: Icons.person_outline_rounded,
                    items: _users
                        .map((u) => DropdownMenuItem<String>(
                              value: u['id'] as String,
                              child: Text('${u['name']} · ${u['role']}'),
                            ))
                        .toList(),
                    onChanged: _loadingUsers
                        ? null
                        : (v) {
                            final u = _users.firstWhere((x) => x['id'] == v, orElse: () => null);
                            setState(() {
                              _selectedUserId = v;
                              _selectedUserName = u?['name'] as String?;
                            });
                          },
                  ),

                  const SizedBox(height: 18),

                  // Scheduled time
                  _SectionLabel('Scheduled Time'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDateTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEE8DF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              color: Color(0xFF8C8278), size: 18),
                          const SizedBox(width: 12),
                          Text(
                            _formatDateTime(_scheduledTime),
                            style: const TextStyle(
                              fontSize: 14.5,
                              color: Color(0xFF1A1714),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.edit_outlined,
                              color: Color(0xFF8C8278), size: 16),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Submit button
                  GestureDetector(
                    onTap: _submitting ? null : _submit,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _submitting
                            ? const Color(0xFF1E3D2F).withValues(alpha: 0.5)
                            : const Color(0xFF1E3D2F),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _submitting
                            ? []
                            : [
                                BoxShadow(
                                  color: const Color(0xFF1E3D2F).withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                      ),
                      child: Center(
                        child: _submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline_rounded,
                                      color: Colors.white, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    'Create Task',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF4A4540),
        letterSpacing: 0.1,
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLines;

  const _TextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Color(0xFF1A1714), fontSize: 14.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFBBB3A8)),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(icon, color: const Color(0xFF8C8278), size: 18),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: const Color(0xFFEEE8DF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1E3D2F), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String? value;
  final String hint;
  final IconData icon;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?>? onChanged;

  const _DropdownField({
    required this.value,
    required this.hint,
    required this.icon,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEEE8DF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8C8278), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: value,
                hint: Text(
                  hint,
                  style: const TextStyle(color: Color(0xFFBBB3A8), fontSize: 14.5),
                ),
                style: const TextStyle(color: Color(0xFF1A1714), fontSize: 14.5),
                dropdownColor: const Color(0xFFF7F3EC),
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF8C8278), size: 20),
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
