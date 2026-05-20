import 'package:auragains/core/widgets/clickable_avatar.dart';
import 'package:auragains/features/auth/view_models/auth_viewmodel.dart';
import 'package:auragains/features/user_profile/views/user_profile_view.dart';
import 'package:auragains/features/workout_management/views/add_workout_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProtocolCreationView extends StatefulWidget {
  const ProtocolCreationView({super.key});

  @override
  State<ProtocolCreationView> createState() => _ProtocolCreationViewState();
}


class _ProtocolCreationViewState extends State<ProtocolCreationView> {
  // ==========================================
  // 🎨 THEME
  // ==========================================
  final Color _cardColor = const Color(0xFF1E1E1E);
  final Color _bgColor = const Color(0xFF121212);
  final Color _fieldColor = const Color(0xFF2A2A2A);
  final Color _accentColor = const Color(0xFF00E5FF);
  final Color _textPrimary = Colors.white;
  final Color _textSecondary = Colors.grey;

  int _currentIndex = 2;

  // ==========================================
  // 🗄️ STATE
  // ==========================================
  final _supabase = Supabase.instance.client;
  final TextEditingController _nameController = TextEditingController();

  List<Map<String, dynamic>> _targetMuscles = [];
  List<Map<String, dynamic>> _workoutLevels = [];

  // Multi-select muscles
  final List<Map<String, dynamic>> _selectedMuscles = [];
  Map<String, dynamic>? _selectedLevel;

  // Public / Private — true = Public
  bool _isPublic = true;

  final List<Map<String, String>> _addedExercises = [];
  bool _isLoadingDropdowns = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ==========================================
  // 🌐 FETCH
  // ==========================================

  Future<void> _fetchDropdownData() async {
    try {
      final results = await Future.wait([
        _supabase.from('target_muscle').select('tar_musc_id, name').order('name'),
        _supabase.from('level').select('level_id, name').order('name'),
      ]);
      setState(() {
        _targetMuscles = (results[0] as List).cast<Map<String, dynamic>>();
        _workoutLevels = (results[1] as List).cast<Map<String, dynamic>>();
        _isLoadingDropdowns = false;
      });
    } catch (e) {
      debugPrint('Error fetching dropdowns: $e');
      setState(() => _isLoadingDropdowns = false);
    }
  }

  // ==========================================
  // 💾 SAVE
  // ==========================================

  Future<void> _createProtocol() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) { _snack('Please enter a protocol name.'); return; }
    if (_addedExercises.isEmpty) { _snack('Please add at least one exercise.'); return; }

    setState(() => _isSaving = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('You must be logged in.');

      // Build goal string from selected muscles
      final goalLabel = _selectedMuscles.isNotEmpty
          ? _selectedMuscles.map((m) => m['name']).join(', ')
          : _selectedLevel?['name'] ?? 'General';

      // 1. Insert training_protocol
      final proto = await _supabase.from('training_protocol').insert({
        'proto_title': name,
        'create_by': userId,
        'goal': goalLabel,
        'proto_type_id': _selectedLevel?['level_id'],
        'is_public': _isPublic,
      }).select().single();

      final int protoId = proto['train_proto_id'];

      // 2. Insert protocol_workout junction rows
      final rows = _addedExercises.map((ex) => {
        'train_proto_id': protoId,
        'workout_id': int.parse(ex['workout_id']!),
      }).toList();
      if (rows.isNotEmpty) await _supabase.from('protocol_workout').insert(rows);

      // 3. Public protocols are tracked in saved_protocol so they appear in
      //    "My Training Protocols" and can be removed without touching Browse.
      //    Private protocols are fetched directly from training_protocol, so
      //    NO saved_protocol row is needed (and saved_by = create_by may be
      //    blocked by RLS anyway).
      if (_isPublic) {
        await _supabase.from('saved_protocol').insert({
          'train_proto_id': protoId,
          'saved_by': userId,
        });
      }

      if (mounted) {
        _snack('Protocol created!', color: const Color(0xFF232323));
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error creating protocol: $e');
      if (mounted) _snack(e.toString().replaceAll('Exception: ', ''), color: Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _snack(String msg, {Color? color}) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));

  // ==========================================
  // 🧩 MULTI-SELECT MUSCLE BOTTOM SHEET
  // ==========================================

  void _showMusclePicker() {
    final temp = List<Map<String, dynamic>>.from(_selectedMuscles);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Target Muscles',
                        style: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    if (temp.isNotEmpty)
                      GestureDetector(
                        onTap: () => setSheet(() => temp.clear()),
                        child: Text('Clear all',
                            style: TextStyle(color: _accentColor, fontSize: 13)),
                      ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),
              if (_targetMuscles.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('No muscles available.', style: TextStyle(color: _textSecondary)),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.45),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _targetMuscles.length,
                    itemBuilder: (_, i) {
                      final m = _targetMuscles[i];
                      final isSel = temp.any((s) => s['tar_musc_id'] == m['tar_musc_id']);
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                        title: Text(m['name'] as String,
                            style: TextStyle(
                              color: isSel ? _accentColor : _textPrimary,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              fontSize: 15,
                            )),
                        trailing: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 150),
                          child: isSel
                              ? Icon(Icons.check_circle, key: const ValueKey('y'), color: _accentColor)
                              : Icon(Icons.circle_outlined, key: const ValueKey('n'),
                                  color: _textSecondary.withOpacity(0.4)),
                        ),
                        onTap: () => setSheet(() {
                          if (isSel) {
                            temp.removeWhere((s) => s['tar_musc_id'] == m['tar_musc_id']);
                          } else {
                            temp.add(m);
                          }
                        }),
                      );
                    },
                  ),
                ),
              const Divider(color: Colors.white10, height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() { _selectedMuscles..clear()..addAll(temp); });
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      temp.isEmpty ? 'Confirm (none)' : 'Confirm  •  ${temp.length} selected',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 🧩 SINGLE-SELECT LEVEL BOTTOM SHEET
  // ==========================================

  void _showLevelPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Text('Workout Level',
                  style: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const Divider(color: Colors.white10, height: 16),
            if (_workoutLevels.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No levels available.', style: TextStyle(color: _textSecondary)),
              )
            else
              ..._workoutLevels.map((level) {
                final isSel = _selectedLevel?['level_id'] == level['level_id'];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  title: Text(level['name'] as String,
                      style: TextStyle(
                        color: isSel ? _accentColor : _textPrimary,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        fontSize: 15,
                      )),
                  trailing: isSel
                      ? Icon(Icons.check_circle, color: _accentColor)
                      : Icon(Icons.circle_outlined, color: _textSecondary.withOpacity(0.4)),
                  onTap: () {
                    setState(() => _selectedLevel = level);
                    Navigator.pop(ctx);
                  },
                );
              }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 🏗️ BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildProtocolNameField(),
            const SizedBox(height: 20),

            if (_isLoadingDropdowns)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: _accentColor, strokeWidth: 2),
                ),
              )
            else ...[
              // ── Target Muscles (multi-select chip pill) ──
              _buildMusclePill(),
              const SizedBox(height: 12),
              // ── Workout Level + Visibility side by side ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildDropdownPill(
                      label: 'Workout Level',
                      selectedValue: _selectedLevel?['name'] as String?,
                      onTap: _showLevelPicker,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildVisibilityToggle(),
                ],
              ),
            ],

            const SizedBox(height: 24),
            _buildAddExerciseButton(),
            const SizedBox(height: 16),

            if (_addedExercises.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No exercises added yet.',
                      style: TextStyle(color: _textSecondary)),
                ),
              )
            else
              ..._addedExercises.map((exercise) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildExerciseCard(exercise),
                  )),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ==========================================
  // 🧩 WIDGET BUILDERS
  // ==========================================

  AppBar _buildAppBar(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final user = authVM.currentUser;
    return AppBar(
      backgroundColor: _bgColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: Colors.white10, height: 1.0),
      ),
      title: Text('AURAGAINS',
          style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
      actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        Padding(
          padding: const EdgeInsets.only(right: 16, left: 8),
          child: PopupMenuButton<String>(
            offset: const Offset(0, 45),
            color: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'profile' && user != null) {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => UserProfileView(targetUserId: user.id, currentUserId: user.id)));
              } else if (value == 'logout') {
                authVM.logout();
                Navigator.popUntil(context, (r) => r.isFirst);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person_outline, color: Colors.white),
                  title: Text('Profile', style: TextStyle(color: Colors.white)),
                  contentPadding: EdgeInsets.zero)),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.redAccent),
                  title: Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  contentPadding: EdgeInsets.zero)),
            ],
            child: ClickableAvatar(
              profilePicUrl: user?.profilePicUrl,
              username: user?.username,
              radius: 16, onTap: null),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(Icons.arrow_back, color: _textPrimary, size: 24),
          ),
        ),
        const SizedBox(width: 12),
        Text('New Protocol',
            style: TextStyle(color: _textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
        const Spacer(),
        ElevatedButton(
          onPressed: _isSaving ? null : _createProtocol,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accentColor,
            foregroundColor: Colors.black,
            disabledBackgroundColor: _fieldColor,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: _isSaving
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
              : const Text('Create', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildProtocolNameField() {
    return TextField(
      controller: _nameController,
      style: TextStyle(color: _textPrimary, fontSize: 16),
      decoration: InputDecoration(
        hintText: 'Enter Protocol Name...',
        hintStyle: TextStyle(color: _textSecondary),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _fieldColor, width: 1.5)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        isDense: true,
      ),
    );
  }

  // ── Multi-select muscle pill ─────────────────────────────────────────────

  Widget _buildMusclePill() {
    final hasSel = _selectedMuscles.isNotEmpty;
    return GestureDetector(
      onTap: _showMusclePicker,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasSel ? _accentColor.withOpacity(0.5) : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TARGET MUSCLES',
                style: TextStyle(
                  color: hasSel ? _accentColor : _textSecondary,
                  fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.0,
                )),
            const SizedBox(height: 6),
            if (!hasSel)
              Row(children: [
                Expanded(child: Text('Select muscles...',
                    style: TextStyle(color: _textSecondary, fontSize: 14))),
                Icon(Icons.keyboard_arrow_down, color: _textSecondary, size: 18),
              ])
            else
              Wrap(
                spacing: 6, runSpacing: 6,
                children: [
                  ..._selectedMuscles.map((m) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _accentColor.withOpacity(0.4)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(m['name'] as String,
                          style: TextStyle(color: _accentColor, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => setState(() =>
                            _selectedMuscles.removeWhere((s) => s['tar_musc_id'] == m['tar_musc_id'])),
                        child: Icon(Icons.close, color: _accentColor, size: 13),
                      ),
                    ]),
                  )),
                  // Add more chip
                  GestureDetector(
                    onTap: _showMusclePicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: _fieldColor, borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.add, color: _textSecondary, size: 13),
                        const SizedBox(width: 2),
                        Text('Add', style: TextStyle(color: _textSecondary, fontSize: 12)),
                      ]),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ── Single-select level pill ─────────────────────────────────────────────

  Widget _buildDropdownPill({
    required String label,
    required String? selectedValue,
    required VoidCallback onTap,
  }) {
    final hasValue = selectedValue != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? _accentColor.withOpacity(0.5) : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: TextStyle(
                  color: hasValue ? _accentColor : _textSecondary,
                  fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.0,
                )),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(
                child: Text(hasValue ? selectedValue! : 'Select...',
                    style: TextStyle(
                      color: hasValue ? _textPrimary : _textSecondary,
                      fontSize: 14,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis),
              ),
              Icon(Icons.keyboard_arrow_down,
                  color: hasValue ? _accentColor : _textSecondary, size: 18),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Public / Private animated toggle ─────────────────────────────────────

  Widget _buildVisibilityToggle() {
    return GestureDetector(
      onTap: () => setState(() => _isPublic = !_isPublic),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _isPublic ? _accentColor.withOpacity(0.12) : _fieldColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isPublic ? _accentColor.withOpacity(0.5) : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('VISIBILITY',
                style: TextStyle(
                  color: _isPublic ? _accentColor : _textSecondary,
                  fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.0,
                )),
            const SizedBox(height: 4),
            Row(mainAxisSize: MainAxisSize.min, children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _isPublic ? Icons.public : Icons.lock_outline,
                  key: ValueKey(_isPublic),
                  color: _isPublic ? _accentColor : _textSecondary,
                  size: 15,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                _isPublic ? 'Public' : 'Private',
                style: TextStyle(
                  color: _isPublic ? _accentColor : _textSecondary,
                  fontSize: 14, fontWeight: FontWeight.w600,
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Add Exercise button ───────────────────────────────────────────────────

  Widget _buildAddExerciseButton() {
    return InkWell(
      onTap: () async {
        final List<Map<String, String>>? selected = await Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AddExerciseView()));
        if (selected != null && selected.isNotEmpty) {
          setState(() {
            for (final ex in selected) {
              if (!_addedExercises.any((e) => e['workout_id'] == ex['workout_id'])) {
                _addedExercises.add(ex);
              }
            }
          });
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: _fieldColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _fieldColor, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: _textSecondary, size: 20),
            const SizedBox(width: 8),
            Text('Add Exercise',
                style: TextStyle(color: _textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── Exercise card ─────────────────────────────────────────────────────────

  Widget _buildExerciseCard(Map<String, String> exercise) {
    return Container(
      decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise['name'] ?? 'Workout Title',
                        style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                    if ((exercise['muscle'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(exercise['muscle']!,
                          style: TextStyle(color: _accentColor.withOpacity(0.8), fontSize: 12)),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: _textSecondary, size: 20),
                constraints: const BoxConstraints(), padding: EdgeInsets.zero,
                onPressed: () => setState(() => _addedExercises.remove(exercise)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(children: [
              Expanded(flex: 1, child: Center(child: _headerText('SET'))),
              Expanded(flex: 2, child: Center(child: _headerText('KG'))),
              Expanded(flex: 2, child: Center(child: _headerText('REPS'))),
              Expanded(flex: 1, child: Center(child: _headerText('PR'))),
              Expanded(flex: 1, child: Center(child: Icon(Icons.check, color: _accentColor, size: 16))),
            ]),
          ),
          const SizedBox(height: 8),
          Divider(color: _fieldColor, thickness: 1),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(children: [
              Expanded(flex: 1, child: Center(child: Text('1', style: TextStyle(color: _textPrimary)))),
              Expanded(flex: 2, child: Center(child: Text('-', style: TextStyle(color: _textSecondary)))),
              Expanded(flex: 2, child: Center(child: Text('-', style: TextStyle(color: _textSecondary)))),
              Expanded(flex: 1, child: Center(child: Text('-', style: TextStyle(color: _textSecondary)))),
              Expanded(flex: 1, child: Center(child: Icon(Icons.circle_outlined, color: _textSecondary, size: 20))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _headerText(String text) => Text(text,
      style: TextStyle(color: _accentColor, fontSize: 12, fontWeight: FontWeight.bold));

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (i) => setState(() => _currentIndex = i),
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF1E1E1E),
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.workspace_premium_outlined), activeIcon: Icon(Icons.workspace_premium), label: 'Challenge'),
        BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), activeIcon: Icon(Icons.add_box), label: 'Post'),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Message'),
        BottomNavigationBarItem(icon: Icon(Icons.contact_support_outlined), activeIcon: Icon(Icons.contact_support), label: 'Expert'),
      ],
    );
  }
}