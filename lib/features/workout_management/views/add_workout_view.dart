import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddExerciseView extends StatefulWidget {
  const AddExerciseView({super.key});

  @override
  State<AddExerciseView> createState() => _AddExerciseViewState();
}

// ==========================================
// 🗄️ LOCAL DATA MODEL
// ==========================================

/// Represents a single row from the `workout` table,
/// with its associated target muscle names joined in.
class _WorkoutRow {
  final int workoutId;
  final String workoutName;
  final List<String> muscleNames; // from workout_target_muscle → target_muscle

  _WorkoutRow({
    required this.workoutId,
    required this.workoutName,
    required this.muscleNames,
  });

  String get muscleLabel =>
      muscleNames.isNotEmpty ? muscleNames.join(', ') : 'General';
}

class _AddExerciseViewState extends State<AddExerciseView> {
  // ==========================================
  // 🎨 THEME VARIABLES
  // ==========================================

  final Color _cardColor = const Color(0xFF1E1E1E);
  final Color _bgColor = const Color(0xFF121212);
  final Color _fieldColor = const Color(0xFF2A2A2A);
  final Color _accentColor = const Color(0xFF00E5FF);
  final Color _textPrimary = Colors.white;
  final Color _textSecondary = Colors.grey;

  // ==========================================
  // 🗄️ STATE VARIABLES
  // ==========================================

  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _errorMessage;

  /// All workouts fetched from the DB
  List<_WorkoutRow> _allWorkouts = [];

  /// Filtered list shown in the UI (after search + muscle filter)
  List<_WorkoutRow> _filteredWorkouts = [];

  /// IDs of workouts the user has selected
  final Set<int> _selectedIds = {};

  /// All target muscles for the filter chips
  List<Map<String, dynamic>> _targetMuscles = [];

  /// Currently active muscle filter (null = All)
  int? _selectedMuscleId;

  final TextEditingController _searchController = TextEditingController();

  // ==========================================
  // 🚀 LIFECYCLE
  // ==========================================

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================
  // 🌐 DATA FETCHING
  // ==========================================

  Future<void> _fetchData() async {
    try {
      // Run both queries in parallel
      final results = await Future.wait([
        // 1. Fetch all workouts + their target muscles via the junction table
        _supabase.from('workout').select('''
          workout_id,
          workout_name,
          workout_target_muscle (
            target_muscle (
              tar_musc_id,
              name
            )
          )
        ''').order('workout_name'),

        // 2. Fetch all target muscles for the filter row
        _supabase.from('target_muscle').select('tar_musc_id, name').order('name'),
      ]);

      final workoutResponse = results[0] as List<dynamic>;
      final muscleResponse = results[1] as List<dynamic>;

      // Parse workouts
      final List<_WorkoutRow> parsed = workoutResponse.map((row) {
        final pivots = row['workout_target_muscle'] as List<dynamic>? ?? [];
        final muscles = pivots
            .map((p) => p['target_muscle'])
            .whereType<Map<String, dynamic>>()
            .map<String>((m) => m['name'] as String)
            .toList();

        return _WorkoutRow(
          workoutId: row['workout_id'] as int,
          workoutName: row['workout_name'] as String,
          muscleNames: muscles,
        );
      }).toList();

      setState(() {
        _allWorkouts = parsed;
        _filteredWorkouts = parsed;
        _targetMuscles = muscleResponse.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching exercises: $e');
      setState(() {
        _errorMessage = 'Failed to load exercises. Please try again.';
        _isLoading = false;
      });
    }
  }

  // ==========================================
  // 🔍 FILTER LOGIC
  // ==========================================

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredWorkouts = _allWorkouts.where((w) {
        // Muscle filter
        final passesMusclFilter = _selectedMuscleId == null ||
            w.muscleNames.any((m) {
              // Find the id for this muscle name and compare
              final match = _targetMuscles.firstWhere(
                (tm) => tm['name'] == m,
                orElse: () => {},
              );
              return match['tar_musc_id'] == _selectedMuscleId;
            });

        // Search filter
        final passesSearch =
            query.isEmpty || w.workoutName.toLowerCase().contains(query);

        return passesMusclFilter && passesSearch;
      }).toList();
    });
  }

  void _selectMuscleFilter(int? muscleId) {
    setState(() => _selectedMuscleId = muscleId);
    _applyFilters();
  }

  // ==========================================
  // 🏗️ BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _buildAppBar(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _accentColor))
          : _errorMessage != null
              ? _buildErrorState()
              : Column(
                  children: [
                    _buildSearchBar(),
                    _buildMuscleFilterRow(),
                    const SizedBox(height: 4),
                    Expanded(child: _buildExerciseList()),
                  ],
                ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  // ==========================================
  // 🧩 WIDGET BUILDERS
  // ==========================================

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _bgColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: _textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Add Exercise',
        style: TextStyle(
          color: _textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: _textPrimary),
        decoration: InputDecoration(
          hintText: 'Search exercises...',
          hintStyle: TextStyle(color: _textSecondary),
          prefixIcon: Icon(Icons.search, color: _textSecondary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: _textSecondary, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                )
              : null,
          filled: true,
          fillColor: _fieldColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  /// Horizontally scrollable muscle filter chips
  Widget _buildMuscleFilterRow() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // "All" chip
          _buildFilterChip(label: 'All', muscleId: null),
          ...(_targetMuscles.map((m) => _buildFilterChip(
                label: m['name'] as String,
                muscleId: m['tar_musc_id'] as int,
              ))),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required int? muscleId}) {
    final isSelected = _selectedMuscleId == muscleId;
    return GestureDetector(
      onTap: () => _selectMuscleFilter(muscleId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _accentColor : _fieldColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : _textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseList() {
    if (_filteredWorkouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fitness_center, size: 48, color: _textSecondary.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(
              'No exercises found',
              style: TextStyle(color: _textSecondary, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: _filteredWorkouts.length,
      itemBuilder: (context, index) {
        final workout = _filteredWorkouts[index];
        final isSelected = _selectedIds.contains(workout.workoutId);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedIds.remove(workout.workoutId);
              } else {
                _selectedIds.add(workout.workoutId);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 10.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isSelected
                  ? _accentColor.withOpacity(0.08)
                  : _cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? _accentColor : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Muscle icon badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _fieldColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: isSelected ? _accentColor : _textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),

                // Name + muscle tags
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.workoutName,
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        workout.muscleLabel,
                        style: TextStyle(
                          color: isSelected
                              ? _accentColor.withOpacity(0.8)
                              : _textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Selection indicator
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: isSelected
                      ? Icon(Icons.check_circle, color: _accentColor, size: 22,
                          key: const ValueKey('checked'))
                      : Icon(Icons.circle_outlined,
                          color: _textSecondary.withOpacity(0.3), size: 22,
                          key: const ValueKey('unchecked')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 48, color: _textSecondary),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: _textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _fetchData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.black,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _selectedIds.isEmpty
              ? null
              : () {
                  // Build the selected list in the same Map<String,String> shape
                  // that protocol_creation_view.dart already consumes
                  final selected = _allWorkouts
                      .where((w) => _selectedIds.contains(w.workoutId))
                      .map((w) => {
                            'workout_id': w.workoutId.toString(),
                            'name': w.workoutName,
                            'muscle': w.muscleLabel,
                          })
                      .toList();

                  Navigator.pop(context, selected);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: _accentColor,
            disabledBackgroundColor: _fieldColor,
            foregroundColor: Colors.black,
            disabledForegroundColor: _textSecondary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Text(
            _selectedIds.isEmpty
                ? 'Select Exercises'
                : 'Add ${_selectedIds.length} Exercise${_selectedIds.length == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}