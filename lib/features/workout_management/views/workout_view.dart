import 'package:auragains/features/challenges/views/challenge_view.dart';
import 'package:auragains/features/workout_management/views/workout_log_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auragains/features/workout_management/view_models/workout_view_model.dart';

import 'protocol_creation_view.dart';
import 'browse_protocol_view.dart';

class WorkoutView extends StatefulWidget {
  final VoidCallback? onNavigateToChallenge;

  const WorkoutView({super.key, this.onNavigateToChallenge});

  @override
  State<WorkoutView> createState() => _WorkoutViewState();
}

class _WorkoutViewState extends State<WorkoutView> {
  final GlobalKey _protocolsKey = GlobalKey();

  // ==========================================
  // 🎨 MASTER THEME VARIABLES
  // ==========================================
  final Color _bgColor = const Color(0xFF121212);
  final Color _boxColor = const Color(0xFF1E1E1E);
  final Color _fieldColor = const Color(0xFF2A2A2A);
  final Color _accentColor = const Color(0xFF00E5FF);
  final Color _textPrimary = Colors.white;
  final Color _textSecondary = Colors.grey;
  final Color _textHint = const Color(0xFF616161);
  final Color _buttonText = Colors.black;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<WorkoutViewModel>(context, listen: false);
      viewModel.fetchSavedProtocols();
      viewModel.fetchUserQuickStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroCard(),
            const SizedBox(height: 32),
            _buildQuickStats(),
            const SizedBox(height: 32),
            _buildChallengeBanner(context),
            const SizedBox(height: 32),
            _buildTrainingProtocols(context),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 🦸 HERO CARD
  // ==========================================

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            '// LET\'S CRUSH IT TODAY',
            style: TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          const Text(
            'READY TO TRAIN?',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 20),
          Consumer<WorkoutViewModel>(
            builder: (context, viewModel, child) {
              final hasProtocols = viewModel.workouts.isNotEmpty;

              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (viewModel.isWorkoutActive) {
                      final activeWorkout = viewModel.currentActiveWorkout;
                      if (activeWorkout != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WorkoutLogView(workout: activeWorkout),
                          ),
                        );
                      }
                    } else if (hasProtocols) {
                      final lastWorkout =
                          viewModel.lastLoggedWorkout ?? viewModel.workouts.first;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkoutLogView(workout: lastWorkout),
                        ),
                      );
                    } else {
                      if (_protocolsKey.currentContext != null) {
                        Scrollable.ensureVisible(
                          _protocolsKey.currentContext!,
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOut,
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    hasProtocols ? 'Resume Schedule Log' : 'Start a Schedule Log',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 📊 QUICK STATS
  // ==========================================

  Widget _buildQuickStats() {
    return Consumer<WorkoutViewModel>(
      builder: (context, viewModel, child) {
        final formattedVolume = viewModel.totalVolume >= 1000
            ? '${(viewModel.totalVolume / 1000).toStringAsFixed(1)}k kg'
            : '${viewModel.totalVolume.toInt()} kg';

        return Row(
          children: [
            Expanded(
              child: _statBox('Workouts', viewModel.totalWorkouts.toString(), Icons.fitness_center),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _statBox('Total Volume', formattedVolume, Icons.assessment),
            ),
          ],
        );
      },
    );
  }

  Widget _statBox(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF00E5FF), size: 28),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: _boxColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              )),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
    );
  }

  Widget _buildProgressiveOverloadBanner() {
    return Consumer<WorkoutViewModel>(
      builder: (context, viewModel, child) {
        if (!viewModel.hasProgressiveOverload) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 24.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00E5FF), Color(0xFF007799)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                child: const Icon(Icons.local_fire_department, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Progressive Overload!",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 4),
                    Text(
                      "You lifted more volume in your last session than the one before. Keep growing!",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // 🏆 CHALLENGE BANNER
  // ==========================================

  Widget _buildChallengeBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _boxColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentColor.withOpacity(0.3), width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.workspace_premium, color: _accentColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Community Challenges',
                    style: TextStyle(
                        color: _textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Push your limits & earn rewards.',
                    style: TextStyle(color: _textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    backgroundColor: const Color(0xFF121212),
                    appBar: AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      leading: const BackButton(color: Colors.white),
                    ),
                    body: const ChallengeView(),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: _buttonText,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('View', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 🗓️ TRAINING PROTOCOLS LIST
  // ==========================================

  Widget _buildTrainingProtocols(BuildContext context) {
    final workoutVM = context.watch<WorkoutViewModel>();
    final savedWorkouts = workoutVM.workouts;

    return Column(
      key: _protocolsKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Training Protocols',
              style: TextStyle(
                  color: _textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Row(
              children: [
                _buildSmallIconButton(Icons.add, () async {
                  // Refresh after creation so newly created protocol appears
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProtocolCreationView()),
                  );
                  if (result == true && mounted) {
                    Provider.of<WorkoutViewModel>(context, listen: false)
                        .fetchSavedProtocols();
                  }
                }),
                const SizedBox(width: 8),
                _buildSmallIconButton(Icons.explore, () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BrowseProtocolView()),
                  );
                  // Refresh after returning — user may have copied a protocol
                  if (context.mounted) {
                    Provider.of<WorkoutViewModel>(context, listen: false)
                        .fetchSavedProtocols();
                  }
                }),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (savedWorkouts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: _boxColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _fieldColor),
            ),
            child: Column(
              children: [
                Icon(Icons.fitness_center, size: 40, color: _textHint),
                const SizedBox(height: 16),
                Text('No Protocols Yet',
                    style: TextStyle(
                        color: _textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  'Add a routine to track your progress and manage your volume.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _textSecondary, fontSize: 13),
                ),
              ],
            ),
          )
        else
          Column(
            children: savedWorkouts.map((workout) {
              final String tags = workout.targetMuscles != null
                  ? workout.targetMuscles!.map((m) => m.name).join(' • ')
                  : 'Custom Routine';

              // 🔴 LIVE session: open workout_session row (end_time IS NULL)
              final bool isLive =
                  workoutVM.activeProtoId == workout.workoutId ||
                  (workoutVM.isWorkoutActive &&
                      workoutVM.currentActiveWorkout?.workoutId == workout.workoutId);

              // 🔵 RESUME indicator: last completed session OR live session
              final bool isResumeTarget =
                  !isLive &&
                  (workoutVM.lastLoggedWorkout?.workoutId == workout.workoutId);

              final bool isHighlighted = isLive || isResumeTarget;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _boxColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLive
                        ? _accentColor
                        : isResumeTarget
                            ? _accentColor.withOpacity(0.5)
                            : _accentColor.withOpacity(0.2),
                    width: isLive ? 1.5 : isResumeTarget ? 1.2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    // 🔴 LIVE — currently training banner
                    if (isLive)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: _accentColor.withOpacity(0.12),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(11),
                            topRight: Radius.circular(11),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildPulsingDot(),
                            const SizedBox(width: 8),
                            Text(
                              'CURRENTLY TRAINING',
                              style: TextStyle(
                                color: _accentColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // 🔵 RESUME — last trained protocol banner
                    if (isResumeTarget)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A2A2A),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(11),
                            topRight: Radius.circular(11),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _accentColor.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'RESUME SCHEDULE LOG',
                              style: TextStyle(
                                color: _accentColor.withOpacity(0.8),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_upward,
                              color: _accentColor.withOpacity(0.6),
                              size: 12,
                            ),
                          ],
                        ),
                      ),

                    // Protocol content row
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  workout.workoutName,
                                  style: TextStyle(
                                    color: _textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(tags,
                                    style: TextStyle(color: _textSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.redAccent, size: 20),
                                onPressed: () {
                                  _showDeleteConfirmation(
                                      context, workoutVM, workout.workoutId);
                                },
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          WorkoutLogView(workout: workout),
                                    ),
                                  );
                                },
                                child: Icon(Icons.play_circle_fill,
                                    color: _accentColor, size: 36),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // ==========================================
  // 🟢 PULSING ACTIVE DOT
  // ==========================================

  Widget _buildPulsingDot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _accentColor.withOpacity(value),
            boxShadow: [
              BoxShadow(
                color: _accentColor.withOpacity(value * 0.6),
                blurRadius: 4 * value,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
      onEnd: () => setState(() {}), // re-trigger animation loop
    );
  }

  // ==========================================
  // 🗑️ DELETE CONFIRMATION
  // ==========================================

  void _showDeleteConfirmation(BuildContext context, WorkoutViewModel vm, int id) {
    final isPrivate = vm.isPrivateProtocol(id);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          isPrivate ? 'Delete Protocol?' : 'Remove Protocol?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          isPrivate
              ? 'This will permanently delete your private protocol and all its exercises. This cannot be undone.'
              : 'This will remove this protocol from your training list. It will remain visible in Browse for other users.',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await vm.removeProtocol(id);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to remove protocol: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Remove',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _fieldColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 18, color: _textPrimary),
      ),
    );
  }
}