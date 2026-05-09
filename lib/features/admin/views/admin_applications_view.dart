import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/admin_viewmodel.dart';
import '../widgets/admin_application_card.dart';
import 'admin_verify_view.dart';

const Color _kCard = Color(0xFF1E1E1E);
const Color _kBorder = Color(0xFF2A2A2A);
const Color _kAccent = Color(0xFF00E5FF);
const Color _kMuted = Color(0xFF9E9E9E);
const Color _kSuccess = Color(0xFF00E676);

class AdminApplicationsView extends StatefulWidget {
  const AdminApplicationsView({super.key});

  @override
  State<AdminApplicationsView> createState() => _AdminApplicationsViewState();
}

class _AdminApplicationsViewState extends State<AdminApplicationsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().loadApplications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const Center(child: CircularProgressIndicator(color: _kAccent));
        }

        return Column(
          children: [
            // ─ Status filter ────────────────────────────
            _StatusTabBar(
              current: vm.appStatusFilter,
              onChanged: vm.setAppStatusFilter,
            ),

            // ─ List ─────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: _kAccent,
                backgroundColor: _kCard,
                onRefresh: vm.loadApplications,
                child: vm.filteredApplications.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 80),
                          Center(
                            child: Text(
                              'No applications found.',
                              style: TextStyle(color: _kMuted),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: vm.filteredApplications.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final app = vm.filteredApplications[i];
                          return AdminApplicationCard(
                            application: app,
                            onTap: () => _openDetail(ctx, vm, vm.filteredApplications.indexOf(app)),  
                            onApprove: () => _onApprove(ctx, vm, app),
                            onReject: () => _onReject(ctx, vm, app),
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openDetail(BuildContext context, AdminViewModel vm, int index) {
    vm.selectApplication(vm.filteredApplications.isNotEmpty ? index : 0);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider<AdminViewModel>.value(
          value: vm,
          child: const AdminVerifyView(),
        ),
      ),
    );
  }

  Future<void> _onApprove(
      BuildContext context, AdminViewModel vm, dynamic app) async {
    final ok = await vm.approveApplication(app.applicationId, app.userId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Application approved!' : (vm.errorMessage ?? 'Error')),
          backgroundColor: ok ? _kSuccess : Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _onReject(
      BuildContext context, AdminViewModel vm, dynamic app) async {
    final ok = await vm.rejectApplication(app.applicationId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Application rejected.' : (vm.errorMessage ?? 'Error')),
          backgroundColor: ok ? _kCard : Colors.redAccent,
        ),
      );
    }
  }
}

class _StatusTabBar extends StatelessWidget {
  const _StatusTabBar({required this.current, required this.onChanged});

  final String? current;
  final void Function(String?) onChanged;

  static const _tabs = [
    (label: 'All', value: null),
    (label: 'Pending', value: 'pending'),
    (label: 'Approved', value: 'approved'),
    (label: 'Rejected', value: 'rejected'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: _tabs.map((t) {
          final active = current == t.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(t.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: active ? _kAccent.withValues(alpha: 0.15) : _kCard,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                      color: active ? _kAccent : _kBorder),
                ),
                child: Text(
                  t.label,
                  style: TextStyle(
                    color: active ? _kAccent : _kMuted,
                    fontSize: 12,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
