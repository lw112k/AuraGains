import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:auragains/features/workout_management/models/workout_model.dart';
import 'package:auragains/features/workout_management/view_models/workout_view_model.dart';

class WorkoutLogView extends StatefulWidget {
  final Workout workout; 
  const WorkoutLogView({super.key, required this.workout});
  
  @override
  State<WorkoutLogView> createState() => _WorkoutLogViewState();
}

class _WorkoutLogViewState extends State<WorkoutLogView> {
  final Color _cardColor = const Color(0xFF1E1E1E);
  final Color _bgColor = const Color(0xFF121212);
  final Color _accentColor = const Color(0xFF00E5FF); 
  final Color _textPrimary = Colors.white;
  final Color _textSecondary = Colors.grey;

  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<ActiveExercise> _activeExercises = [];
  bool _isStarted = false; 

  late Stopwatch _stopwatch;
  Timer? _timer; 
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    
    final viewModel = Provider.of<WorkoutViewModel>(context, listen: false);

    // CHECK IF WE ARE RESUMING A WORKOUT
    if (viewModel.isWorkoutActive && viewModel.currentActiveWorkout?.workoutId == widget.workout.workoutId) {
      _activeExercises = viewModel.activeExercises;
      _startTime = viewModel.workoutStartTime;
      _stopwatch = viewModel.workoutStopwatch;
      _isStarted = true;
      _isLoading = false;

      // Restart the UI tick
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) setState(() {});
      });
    } else {
      // FRESH START
      _stopwatch = Stopwatch(); 
      _fetchWorkoutExercises();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Dispose all TextEditingControllers here — NOT in the button handlers.
    // If controllers are disposed before Navigator.pop(), the navigation
    // transition still renders TextFields with disposed controllers
    // which triggers the _dependents.isEmpty assertion.
    for (var exercise in _activeExercises) {
      for (var set in exercise.sets) {
        set.dispose();
      }
    }
    // We do NOT stop the stopwatch here so it keeps running in the background.
    super.dispose();
  }

  void _startWorkout() {
    setState(() {
      _isStarted = true;
      _startTime = DateTime.now(); 
      _stopwatch.start();
      
      Provider.of<WorkoutViewModel>(context, listen: false)
          .setWorkoutActiveState(isActive: true, workout: widget.workout);
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  String _getFormattedTime() {
    if (!_isStarted) return "00:00:00"; 
    
    final duration = _stopwatch.elapsed;
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return hours == "00" ? "$minutes:$seconds" : "$hours:$minutes:$seconds";
  }

  Future<void> _fetchWorkoutExercises() async {
    try {
      final protoId = widget.workout.workoutId;
      final userId = _supabase.auth.currentUser?.id;

      final response = await _supabase
          .from('protocol_workout')
          .select('workout (workout_id, workout_name)')
          .eq('train_proto_id', protoId);

      final List<ActiveExercise> fetchedExercises = [];
      
      for (var row in response) {
        final workoutNode = row['workout'];
        if (workoutNode != null) {
          fetchedExercises.add(
            ActiveExercise(
              workoutId: workoutNode['workout_id'],
              exerciseName: workoutNode['workout_name'] ?? 'Unknown Exercise',
              sets: [
                ActiveSet(setNum: 1, initialKg: '', initialReps: '10'),
                ActiveSet(setNum: 2, initialKg: '', initialReps: '10'),
                ActiveSet(setNum: 3, initialKg: '', initialReps: '10'),
              ],
            ),
          );
        }
      }

      if (userId != null) {
        for (var exercise in fetchedExercises) {
          try {
            final prData = await _supabase
                .from('workout_log')
                .select('weight, workout_session!inner(user_id)') 
                .eq('workout_session.user_id', userId)
                .eq('workout_id', exercise.workoutId)
                .order('weight', ascending: false) 
                .limit(1) 
                .maybeSingle(); 

            if (prData != null && prData['weight'] != null) {
              double weight = (prData['weight'] as num).toDouble();
              String formattedWeight = weight % 1 == 0 ? weight.toInt().toString() : weight.toString();
              exercise.pr = '${formattedWeight}kg'; 
            }
          } catch (e) {
            debugPrint('Could not fetch PR: $e');
          }
        }
      }

      setState(() {
        _activeExercises = fetchedExercises;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching exercises: $e");
      setState(() => _isLoading = false);
    }
  }

  void _toggleSetCompletion(ActiveExercise exercise, ActiveSet set) {
    if (!_isStarted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please click Start to begin your workout first!')),
      );
      return;
    }

    final double? kg = double.tryParse(set.kgController.text);
    final int? reps = int.tryParse(set.repsController.text);

    if (kg == null || reps == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numbers for KG and Reps.')),
      );
      return;
    }

    setState(() {
      set.isCompleted = !set.isCompleted; 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _buildAppBar(),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: _accentColor))
        : GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(), 
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildWorkoutTitle(),
                  const SizedBox(height: 24),
                  _buildTimerRow(),
                  const SizedBox(height: 24),
                  
                  if (_activeExercises.isEmpty)
                    const Text('No exercises found for this protocol.', style: TextStyle(color: Colors.grey))
                  else
                    ..._activeExercises.map((exercise) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _buildExerciseCard(exercise),
                      );
                    }),
                ],
              ),
            ),
          ),
    );
  }

  // Back arrow always shows arrow_back.
  // When a workout is active, tapping it opens the cancel dialog.
  // When not started, it simply pops the screen.
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _bgColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: _textPrimary, size: 24),
        onPressed: _isStarted ? _showCancelDialog : () => Navigator.pop(context),
      ),
      actions: const [],
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        title: const Text('Cancel Workout?', style: TextStyle(color: Colors.white)),
        content: const Text('All current progress will be lost.', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          TextButton(
            onPressed: () {
              // Controllers are disposed by dispose() after the route exits —
              // do not dispose them here or the exit animation will assert.
              Provider.of<WorkoutViewModel>(context, listen: false).setWorkoutActiveState(isActive: false);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close workout view
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutTitle() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Text(
          widget.workout.workoutName, 
          style: TextStyle(color: _textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          widget.workout.targetMuscles?.map((m) => m.name).join(' • ') ?? 'Custom Routine',
          style: TextStyle(color: _textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTimerRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Timer: ${_getFormattedTime()}', 
          style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        ElevatedButton(
          onPressed: () async {
            if (!_isStarted) {
              _startWorkout(); 
            } else {
              _stopwatch.stop();
              _timer?.cancel();
              final endTime = DateTime.now(); 

              final userId = _supabase.auth.currentUser?.id;
              if (userId == null) return;

              List<Map<String, dynamic>> logsToSave = [];
              
              for (var exercise in _activeExercises) {
                for (var set in exercise.sets) {
                  if (set.isCompleted) {
                    logsToSave.add({
                      'workout_id': exercise.workoutId,
                      'set': set.setNum,
                      'weight': double.tryParse(set.kgController.text) ?? 0,
                      'reps': int.tryParse(set.repsController.text) ?? 0,
                    });
                  }
                }
              }

              // Capture the ViewModel reference before popping so we can
              // safely call async methods after the widget is gone from the tree.
              // Controllers are disposed by the widget's own dispose() method
              // after the route's exit animation completes — do NOT dispose them
              // here or the TextField animation frames will assert.
              final vm = Provider.of<WorkoutViewModel>(context, listen: false);
              vm.setWorkoutActiveState(isActive: false);

              if (logsToSave.isNotEmpty && _startTime != null) {
                // Pop immediately — the save continues in the background.
                // The ViewModel will refresh stats after saving without
                // touching this widget's context.
                Navigator.pop(context);

                try {
                  await vm.saveWorkoutSessionWithLogs(
                    protocolId: widget.workout.workoutId,
                    userId: userId,
                    startTime: _startTime!,
                    endTime: endTime,
                    logs: logsToSave,
                  );
                  // Refresh active session badge on the WorkoutView card list
                  await vm.fetchActiveSession();
                } catch (e) {
                  debugPrint('Error saving workout session: $e');
                }
              } else {
                Navigator.pop(context);
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _accentColor,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            _isStarted ? 'Finish' : 'Start', 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseCard(ActiveExercise exercise) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exercise.exerciseName,
            style: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(flex: 1, child: Center(child: _buildHeaderText('SET'))),
                Expanded(flex: 2, child: Center(child: _buildHeaderText('KG'))),
                Expanded(flex: 2, child: Center(child: _buildHeaderText('REPS'))),
                Expanded(flex: 1, child: Center(child: _buildHeaderText('PR'))),
                Expanded(flex: 1, child: Center(child: Icon(Icons.check, color: _accentColor, size: 16))),
              ],
            ),
          ),

          ...exercise.sets.map((set) => _buildSetRow(exercise, set)),

          const SizedBox(height: 12),
          
          Center(
            child: TextButton.icon(
              onPressed: () {
                if (!_isStarted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please click Start to begin your workout first!')),
                  );
                  return;
                }
                setState(() {
                  exercise.sets.add(ActiveSet(
                    setNum: exercise.sets.length + 1, 
                    initialKg: '', 
                    initialReps: '10'
                  ));
                });
              },
              icon: Icon(Icons.add, color: _textSecondary, size: 16),
              label: Text('Add Set', style: TextStyle(color: _textSecondary, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderText(String text) {
    return Text(
      text,
      style: TextStyle(color: _accentColor, fontSize: 12, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSetRow(ActiveExercise exercise, ActiveSet set) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), 
      decoration: BoxDecoration(
        color: set.isCompleted ? _accentColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1, 
            child: Center(child: Text(set.setNum.toString(), style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold)))
          ),
          
          Expanded(
            flex: 2, 
            child: Center(
              child: SizedBox(
                width: 50,
                child: TextField(
                  controller: set.kgController,
                  enabled: !set.isCompleted && _isStarted, 
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: set.isCompleted ? _textSecondary : _textPrimary, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '-',
                    hintStyle: TextStyle(color: _textSecondary.withOpacity(0.5)),
                  ),
                ),
              ),
            )
          ),
          
          Expanded(
            flex: 2, 
            child: Center(
              child: SizedBox(
                width: 50,
                child: TextField(
                  controller: set.repsController,
                  enabled: !set.isCompleted && _isStarted, 
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: set.isCompleted ? _textSecondary : _textPrimary, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '-',
                    hintStyle: TextStyle(color: _textSecondary.withOpacity(0.5)),
                  ),
                ),
              ),
            )
          ),
          
          Expanded(
            flex: 1, 
            child: Center(
              child: Text(
                exercise.pr, 
                style: TextStyle(
                  color: exercise.pr == '-' ? _textSecondary : _accentColor, 
                  fontWeight: exercise.pr == '-' ? FontWeight.normal : FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ) 
          ),
          
          Expanded(
            flex: 1, 
            child: GestureDetector(
              onTap: () => _toggleSetCompletion(exercise, set),
              child: Center(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: set.isCompleted ? _accentColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: set.isCompleted ? _accentColor : _textSecondary.withOpacity(0.5),
                      width: 2,
                    )
                  ),
                  child: set.isCompleted 
                      ? const Icon(Icons.check, color: Colors.black, size: 18) 
                      : null,
                ),
              ),
            )
          ),
        ],
      ),
    );
  }
}