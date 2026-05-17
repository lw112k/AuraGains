import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:auragains/features/workout_management/models/workout_model.dart';
import 'package:auragains/features/workout_management/models/target_muscle_model.dart';
import 'package:auragains/features/workout_management/view_models/workout_view_model.dart';

// ==========================================
// 🗄️ DATA MODELS 
// ==========================================
class ExerciseData {
  final String exerciseName;
  final List<SetData> sets;

  ExerciseData({required this.exerciseName, required this.sets});
}

class SetData {
  final int setNumber;
  final int kg;
  final int reps;

  SetData({required this.setNumber, required this.kg, required this.reps});
}

// ==========================================
// 🎨 VIEW IMPLEMENTATION
// ==========================================
class ProtocolDetailView extends StatefulWidget {
  // 👇 1. ADD THIS: Require the protocol data to be passed in
  final dynamic protocolData;

  const ProtocolDetailView({super.key, required this.protocolData});

  @override
  State<ProtocolDetailView> createState() => _ProtocolDetailViewState();
}

class _ProtocolDetailViewState extends State<ProtocolDetailView> {
  // --- THEME VARIABLES ---
  final Color _cardColor = const Color(0xFF232323); 
  final Color _bgColor = const Color(0xFF121212);
  final Color _accentColor = const Color(0xFF00E5FF); 
  final Color _textPrimary = Colors.white;
  final Color _textSecondary = Colors.grey;

  // --- SUPABASE & STATE VARIABLES ---
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isAlreadySaved = false; // true when this protocol is in the user's saved_protocol
  List<ExerciseData> _protocolExercises = [];

  @override
  void initState() {
    super.initState();
    _fetchProtocolWorkouts();
    _checkIfAlreadySaved();
  }

  // Check whether this protocol is currently in the user's "My Training Protocols"
  // list (saved_protocol table). This drives the Copy / "Already Saved" button,
  // regardless of who created the protocol.
  Future<void> _checkIfAlreadySaved() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      final protoId = widget.protocolData['train_proto_id'];
      final row = await _supabase
          .from('saved_protocol')
          .select('train_proto_id')
          .eq('train_proto_id', protoId)
          .eq('saved_by', userId)
          .maybeSingle();
      if (mounted) setState(() => _isAlreadySaved = row != null);
    } catch (e) {
      debugPrint('Error checking saved state: $e');
    }
  }

  // 👇 2. FETCH THE WORKOUTS FROM SUPABASE 👇
  Future<void> _fetchProtocolWorkouts() async {
    try {
      final protoId = widget.protocolData['train_proto_id'];

      // Query the junction table and join the workout details
      final response = await _supabase
          .from('protocol_workout')
          .select('workout (workout_id, workout_name)')
          .eq('train_proto_id', protoId);

      // Parse the database response into our UI models
      final List<ExerciseData> fetchedExercises = [];
      
      for (var row in response) {
        final workoutNode = row['workout'];
        if (workoutNode != null) {
          final workoutName = workoutNode['workout_name'] ?? 'Unknown Exercise';
          
          // Generate mock sets (since sets/reps aren't in the DB schema yet)
          // If you add 'target_sets' to protocol_workout later, you'd pull it here!
          fetchedExercises.add(
            ExerciseData(
              exerciseName: workoutName,
              sets: [
                SetData(setNumber: 1, kg: 0, reps: 10),
                SetData(setNumber: 2, kg: 0, reps: 10),
                SetData(setNumber: 3, kg: 0, reps: 10),
              ],
            ),
          );
        }
      }

      setState(() {
        _protocolExercises = fetchedExercises;
        _isLoading = false;
      });

    } catch (e) {
      debugPrint("Error fetching protocol workouts: $e");
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load workouts.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: _accentColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  
                  // Handle empty state if no workouts are linked
                  if (_protocolExercises.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        "No exercises added to this protocol yet.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ..._protocolExercises.map((exercise) {
                      return _buildDynamicExerciseCard(exercise);
                    }),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // ==========================================
  // 🧩 WIDGET BUILDERS
  // ==========================================

  Widget _buildHeader() {
    // Dynamically read title and goals from the passed data
    final title = widget.protocolData['proto_title'] ?? 'Untitled Protocol';
    final goal = widget.protocolData['goal'] ?? 'General Fitness';

    final userNode = widget.protocolData['user'];
    final authorName = userNode != null ? userNode['username'] : 'Unknown User';

    // Determine whether the current user created this protocol (for label copy).
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final creatorId = widget.protocolData['create_by'] as String?;
    final bool isCreator = currentUserId != null && currentUserId == creatorId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            color: _textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          isCreator ? 'Created by you' : 'Created by $authorName',
          style: TextStyle(
            color: _textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          goal,
          style: TextStyle(
            color: _textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 20),

        // Show "In My Protocols" badge when already saved, Copy button otherwise.
        // This is based on saved_protocol membership — NOT on create_by — so
        // the user can re-add their own protocol after removing it from their list.
        if (_isAlreadySaved)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _accentColor.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, color: _accentColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  'In My Protocols',
                  style: TextStyle(
                    color: _accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
        // Copy / Add to My Protocols button
        ElevatedButton.icon(
          onPressed: () async {
            try {
              final protoId = widget.protocolData['train_proto_id'];
              final userId = Supabase.instance.client.auth.currentUser?.id;

              if (userId == null) {
                throw Exception("You must be logged in to save protocols.");
              }
              
              final copiedWorkout = Workout(
                workoutId: protoId, 
                workoutName: title,
                targetMuscles: [
                  TargetMuscle(tarMuscId: 0, name: goal), 
                ],
              );

              await Provider.of<WorkoutViewModel>(context, listen: false)
                  .saveProtocolToDatabase(copiedWorkout, protoId, userId);

              if (mounted) {
                setState(() => _isAlreadySaved = true); // update badge instantly
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Protocol added to your Training Protocols!'),
                    backgroundColor: Color(0xFF232323),
                  ),
                );
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            } catch (e) {
              if (mounted) {
                // 👇 FIX 2: Clean up the error message display 👇
                // Removes the "Exception: " text so it looks professional
                final cleanMessage = e.toString().replaceAll('Exception: ', '');
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(cleanMessage),
                    backgroundColor: Colors.orange, // Use orange for a warning instead of red
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.copy, size: 18, color: Colors.black),
          label: const Text(
            'Copy Protocol',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _accentColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }

  // 🌟 REUSABLE CARD WIDGET 🌟
  Widget _buildDynamicExerciseCard(ExerciseData exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exercise.exerciseName,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(child: Center(child: _buildHeaderText('SET'))),
              Expanded(child: Center(child: _buildHeaderText('KG'))),
              Expanded(child: Center(child: _buildHeaderText('REPS'))),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: _textSecondary.withOpacity(0.2), thickness: 1),
          const SizedBox(height: 8),
          
          ...exercise.sets.map((setData) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        setData.setNumber.toString(),
                        style: TextStyle(color: _textSecondary, fontSize: 14),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        setData.kg == 0 ? "-" : setData.kg.toString(),
                        style: TextStyle(color: _textSecondary, fontSize: 14),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        setData.reps.toString(),
                        style: TextStyle(color: _textSecondary, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeaderText(String text) {
    return Text(
      text,
      style: TextStyle(
        color: _accentColor,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );
  }
}