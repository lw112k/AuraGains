import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/admin_challenge_model.dart';
import '../view_models/admin_challenge_viewmodel.dart';
import 'package:auragains/features/admin/admin_palette.dart';

/// Single form for creating or editing a challenge.
/// Detects mode by whether [existingChallenge] is provided.
class AdminChallengeFormView extends StatefulWidget {
  const AdminChallengeFormView({
    super.key,
    this.existingChallenge,
  });

  final AdminChallengeModel? existingChallenge;

  bool get isEditing => existingChallenge != null;

  @override
  State<AdminChallengeFormView> createState() => _AdminChallengeFormViewState();
}

class _AdminChallengeFormViewState extends State<AdminChallengeFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _pointsCtrl;
  late bool _isDaily;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final c = widget.existingChallenge;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _descCtrl = TextEditingController(text: c?.description ?? '');
    _pointsCtrl = TextEditingController(
      text: c != null ? c.pointReward.toString() : '',
    );
    _isDaily = c?.isDaily ?? true;
    _isActive = c?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _pointsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminChallengeViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.card,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.isEditing ? 'Edit Challenge' : 'Create Challenge',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ─ Name ─────────────────────────────────────
            _SectionLabel('CHALLENGE NAME'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nameCtrl,
              hint: 'e.g. Hydration Station',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 20),

            // ─ Description ──────────────────────────────
            _SectionLabel('DESCRIPTION'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _descCtrl,
              hint: 'Describe the challenge...',
              maxLines: 4,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Description is required'
                  : null,
            ),
            const SizedBox(height: 20),

            // ─ Point Reward ─────────────────────────────
            _SectionLabel('POINT REWARD'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _pointsCtrl,
              hint: 'e.g. 100',
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Points are required';
                }
                final n = int.tryParse(v);
                if (n == null || n < 0) return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ─ Type toggle ──────────────────────────────
            _SectionLabel('CHALLENGE TYPE'),
            const SizedBox(height: 8),
            _ToggleRow(
              label: 'Daily Challenge',
              subtitle: 'Resets every day',
              value: _isDaily,
              onChanged: (v) => setState(() => _isDaily = v),
            ),
            const SizedBox(height: 12),
            _ToggleRow(
              label: 'Active',
              subtitle: 'Visible to users',
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 32),

            // ─ Submit ───────────────────────────────────
            FilledButton(
              onPressed: vm.isActionLoading
                  ? null
                  : () async => _onSubmit(context, vm),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: vm.isActionLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Text(
                      widget.isEditing ? 'Save Changes' : 'Create Challenge',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSubmit(
      BuildContext context, AdminChallengeViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'point_reward': int.parse(_pointsCtrl.text.trim()),
      'is_daily': _isDaily,
      'is_active': _isActive,
    };

    bool ok;
    if (widget.isEditing) {
      ok = await vm.updateChallenge(widget.existingChallenge!.challId, data);
    } else {
      ok = await vm.createChallenge(data);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? (widget.isEditing
                    ? 'Challenge updated!'
                    : 'Challenge created!')
                : (vm.errorMessage ?? 'Error'),
          ),
          backgroundColor: ok ? AppTheme.success : Colors.redAccent,
        ),
      );
      if (ok) Navigator.of(context).pop();
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppTheme.muted),
        filled: true,
        fillColor: AppTheme.card,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.accent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.error),
        ),
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.muted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.accent,
          ),
        ],
      ),
    );
  }
}
