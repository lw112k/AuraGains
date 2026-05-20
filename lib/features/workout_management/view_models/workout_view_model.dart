// --- workout_view_model.dart ---
import 'package:auragains/features/workout_management/models/target_muscle_model.dart';
import 'package:auragains/features/workout_management/models/workout_log_model.dart';
import 'package:auragains/features/workout_management/models/workout_model.dart';
import 'package:auragains/features/workout_management/repositories/workout_repository.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';



class ActiveExercise {
  final int workoutId; 
  final String exerciseName;
  final List<ActiveSet> sets;
  String pr;

  ActiveExercise({required this.workoutId, required this.exerciseName, required this.sets, this.pr = '-'});
}

class ActiveSet {
  final int setNum;
  TextEditingController kgController;
  TextEditingController repsController;
  bool isCompleted;

  ActiveSet({
    required this.setNum,
    required String initialKg,
    required String initialReps,
    this.isCompleted = false,
  })  : kgController = TextEditingController(text: initialKg),
        repsController = TextEditingController(text: initialReps);

  void dispose() {
    kgController.dispose();
    repsController.dispose();
  }
}

class WorkoutViewModel extends ChangeNotifier {
  final IWorkoutRepository _repository;
  bool _disposed = false;

  WorkoutViewModel({required IWorkoutRepository repository}) : _repository = repository;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Safe wrapper — never calls notifyListeners() after dispose().
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  // --- QUICK STATS VARIABLES ---
  int _totalWorkouts = 0;
  double _totalVolume = 0;
  bool _hasProgressiveOverload = false;

  // --- LAST LOGGED PROTOCOL ---
  // Holds the most recently trained protocol so the hero button can open it directly.
  Workout? _lastLoggedWorkout;
  Workout? get lastLoggedWorkout => _lastLoggedWorkout;

  // --- BACKGROUND WORKOUT STATE ---
  bool _isWorkoutActive = false;
  Workout? _currentActiveWorkout;
  DateTime? _workoutStartTime;
  Stopwatch _workoutStopwatch = Stopwatch();
  List<ActiveExercise> _activeExercises = [];

  // --- PERSISTED ACTIVE SESSION (from Supabase) ---
  // Holds the train_proto_id of any workout_session row where end_time IS NULL.
  // This survives app restarts unlike the in-memory _isWorkoutActive flag.
  int? _activeProtoId;
  int? get activeProtoId => _activeProtoId;

  bool get isWorkoutActive => _isWorkoutActive;
  Workout? get currentActiveWorkout => _currentActiveWorkout;
  DateTime? get workoutStartTime => _workoutStartTime;
  Stopwatch get workoutStopwatch => _workoutStopwatch;
  List<ActiveExercise> get activeExercises => _activeExercises;
  

  // Getters for the UI
  int get totalWorkouts => _totalWorkouts;
  double get totalVolume => _totalVolume;
  bool get hasProgressiveOverload => _hasProgressiveOverload;

  // State Variables
  bool _isLoading = false;
  String? _errorMessage;
  
  List<Workout> _workouts = [];
  List<WorkoutLog> _recentLogs = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Workout> get workouts => _workouts;
  List<WorkoutLog> get recentLogs => _recentLogs;
  
  // Call this when you press Start or Cancel
  void setWorkoutActiveState({required bool isActive, Workout? workout}) {
    _isWorkoutActive = isActive;
    
    if (isActive && workout != null) {
      _currentActiveWorkout = workout; // Save to memory
    } else if (!isActive) {
      _currentActiveWorkout = null;    // Clear memory
    }
    _notify();
  }
  // Initialization
  Future<void> fetchInitialData(String userId) async {
    _setLoading(true);
    try {
      // Fetch data in parallel to save time
      final results = await Future.wait([
        _repository.getWorkouts(),
        _repository.getUserWorkoutLogs(userId),
      ]);
      
      _workouts = results[0] as List<Workout>;
      _recentLogs = results[1] as List<WorkoutLog>;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Action: Add a new set/rep log
  Future<void> addWorkoutLog({
    required int set,
    required int reps,
    required double weight,
    required int workoutId,
    required String userId,
  }) async {
    try {
      final newLog = WorkoutLog(
        workoutLogId: 0, // 0 or null depending on your DB auto-increment setup
        set: set,
        reps: reps,
        weight: weight,
        workoutId: workoutId,
        userId: userId,
      );


      final savedLog = await _repository.logWorkout(newLog);
      
      // Update local state without needing to refetch everything
      _recentLogs.insert(0, savedLog); 
      _notify();
    } catch (e) {
      _errorMessage = "Could not save log: ${e.toString()}";
      _notify();
    }
  }

  void copyWorkoutLocally(Workout workout) {
    _workouts.insert(0, workout); // Adds to the top of the list
    _notify(); // Tells the UI to update
  }

  // ✅ FIX: removeProtocol now deletes from Supabase first, then updates local state.
  // This prevents the "already copied" error on re-copy and stops it from
  // reappearing on refresh.
  /// Whether this protocol was created by the current user.
  /// Used by the UI to show the right delete dialog copy.
  bool isOwnedProtocol(int workoutId) {
    return _ownedProtocolIds.contains(workoutId);
  }

  // Tracks IDs of protocols the user created (populated by fetchSavedProtocols)
  final Set<int> _ownedProtocolIds = {};

  // Tracks IDs of owned protocols that are PRIVATE (is_public = false).
  // Private protocols are fetched directly from training_protocol, not via
  // saved_protocol, because saved_protocol may not allow saved_by = create_by.
  // On delete, private owned protocols are hard-deleted from the DB entirely.
  final Set<int> _privateOwnedProtocolIds = {};

  /// True when the protocol is private AND owned by the current user.
  /// Used by the delete dialog to decide between hard-delete vs list-removal.
  bool isPrivateProtocol(int workoutId) =>
      _privateOwnedProtocolIds.contains(workoutId);

  Future<void> removeProtocol(int workoutId) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      if (_privateOwnedProtocolIds.contains(workoutId)) {
        // PRIVATE OWNED → hard-delete from the database entirely.
        // Deletion order matters due to foreign key constraints:
        //   saved_protocol → training_protocol (FK: saved_protocol_train_proto_id_fkey)
        //   protocol_workout → training_protocol (FK)
        // Any saved_protocol rows referencing this ID must be removed first,
        // even if the protocol is private, because old code or backfill SQL
        // may have inserted rows there. Skipping this causes the FK violation.
        await supabase
            .from('saved_protocol')
            .delete()
            .eq('train_proto_id', workoutId);   // clear ALL references first
        await supabase
            .from('protocol_workout')
            .delete()
            .eq('train_proto_id', workoutId);
        await supabase
            .from('training_protocol')
            .delete()
            .eq('train_proto_id', workoutId)
            .eq('create_by', userId);
        _privateOwnedProtocolIds.remove(workoutId);
        _ownedProtocolIds.remove(workoutId);
      } else {
        // PUBLIC OWNED or SAVED FROM BROWSE → remove from saved_protocol only.
        // training_protocol is never touched, so Browse is unaffected.
        await supabase
            .from('saved_protocol')
            .delete()
            .eq('train_proto_id', workoutId)
            .eq('saved_by', userId);
        _ownedProtocolIds.remove(workoutId);
      }

      _workouts.removeWhere((w) => w.workoutId == workoutId);
      _notify();
    } catch (e) {
      debugPrint('Error removing protocol: $e');
      rethrow;
    }
  }

  // Internal helper to handle loading state
  void _setLoading(bool value) {
    _isLoading = value;
    _notify();
  }

  Future<void> saveProtocolToDatabase(Workout copiedWorkout, int protocolId, String userId) async {
    try {
      final _supabase = Supabase.instance.client;

      // Block saving a protocol that is already in the user's list.
      // We check saved_protocol (not training_protocol.create_by) because
      // "My Training Protocols" is now entirely driven by saved_protocol.
      // The Copy button is already hidden for owned protocols in the UI,
      // but this guard prevents accidental double-saves from any path.
      final alreadySaved = await _supabase
          .from('saved_protocol')
          .select('train_proto_id')
          .eq('train_proto_id', protocolId)
          .eq('saved_by', userId)
          .maybeSingle();

      if (alreadySaved != null) {
        throw Exception('You already have this protocol in your Training Protocols!');
      }

      // Insert into saved_protocol — this is the only table "My Training
      // Protocols" reads from, so it immediately appears in the user's list.
      await _supabase.from('saved_protocol').insert({
        'train_proto_id': protocolId,
        'saved_by': userId,
      });

      // Instant UI update — only add if not already in the list
      final alreadyListed = _workouts.any((w) => w.workoutId == copiedWorkout.workoutId);
      if (!alreadyListed) {
        _workouts.insert(0, copiedWorkout);
      }
      _notify();

    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw Exception('You already have this protocol saved!');
      }
      throw Exception(error.message);
    } catch (e) {
      debugPrint("Error saving protocol: $e");
      rethrow;
    }
  }

  Future<void> fetchSavedProtocols() async {
    final _supabase = Supabase.instance.client;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _setLoading(true);

    final Set<int> seenIds = {};
    final List<Workout> loadedWorkouts = [];

    void addProtocol(Map<String, dynamic> p) {
      final id = p['train_proto_id'] as int?;
      if (id == null || seenIds.contains(id)) return;
      seenIds.add(id);
      loadedWorkouts.add(Workout(
        workoutId: id,
        workoutName: p['proto_title'] ?? 'Untitled Protocol',
        targetMuscles: [
          TargetMuscle(tarMuscId: 0, name: p['goal'] ?? 'General'),
        ],
      ));
    }

    // ── 1. PRIVATE owned protocols ────────────────────────────────────────
    // Private protocols are fetched directly from training_protocol.
    // They are intentionally NOT stored in saved_protocol because that table
    // may have a constraint/RLS preventing saved_by = create_by, and because
    // private protocols belong only to the creator — Browse never sees them.
    // Deleting a private protocol hard-deletes it from the DB entirely.
    _ownedProtocolIds.clear();
    _privateOwnedProtocolIds.clear();
    try {
      final privateOwned = await _supabase
          .from('training_protocol')
          .select('train_proto_id, proto_title, goal, is_public, create_by')
          .eq('create_by', userId)
          .eq('is_public', false);
      for (final p in privateOwned as List) {
        final proto = p as Map<String, dynamic>;
        final id = proto['train_proto_id'] as int?;
        if (id != null) {
          _ownedProtocolIds.add(id);
          _privateOwnedProtocolIds.add(id);
        }
        addProtocol(proto);
      }
      debugPrint('fetchSavedProtocols: privateOwned=${privateOwned.length}');
    } catch (e) {
      debugPrint('fetchSavedProtocols ERROR (private owned): $e');
    }

    // ── 2. PUBLIC owned + protocols saved from Browse ─────────────────────
    // Public owned protocols and any protocol the user saved from Browse
    // are both tracked in saved_protocol.  Removing them only deletes the
    // saved_protocol row — training_protocol (and Browse) stay untouched.
    try {
      final savedRows = await _supabase
          .from('saved_protocol')
          .select('train_proto_id')
          .eq('saved_by', userId);

      final List<int> savedIds = (savedRows as List)
          .map((r) => r['train_proto_id'] as int)
          .where((id) => !seenIds.contains(id)) // skip private owned already added
          .toList();

      debugPrint('fetchSavedProtocols: savedIds=$savedIds');

      if (savedIds.isNotEmpty) {
        final protocols = await _supabase
            .from('training_protocol')
            .select('train_proto_id, proto_title, goal, is_public, create_by')
            .inFilter('train_proto_id', savedIds);

        for (final p in protocols as List) {
          final proto = p as Map<String, dynamic>;
          // Track public owned protocols in _ownedProtocolIds for UI badges
          if (proto['create_by'] == userId) {
            final id = proto['train_proto_id'] as int?;
            if (id != null) _ownedProtocolIds.add(id);
          }
          addProtocol(proto);
        }
        debugPrint('fetchSavedProtocols: saved fetched=${protocols.length}');
      }
    } catch (e) {
      debugPrint('fetchSavedProtocols ERROR (saved_protocol): $e');
    }

    // ── 3. Active session check ────────────────────────────────────────────
    try {
      final activeSessions = await _supabase
          .from('workout_session')
          .select('train_proto_id')
          .eq('user_id', userId)
          .filter('end_time', 'is', null)
          .limit(1);
      _activeProtoId = (activeSessions as List).isNotEmpty
          ? activeSessions.first['train_proto_id'] as int?
          : null;
    } catch (e) {
      debugPrint('fetchSavedProtocols ERROR (active session): $e');
    }

    _workouts = loadedWorkouts;
    _isLoading = false;
    debugPrint('fetchSavedProtocols: total=${loadedWorkouts.length}');
    _notify();
  }

  /// Lightweight refresh of just the active session indicator.
  /// Call this after starting or finishing a workout session so the
  /// "Currently Training" badge updates immediately without a full reload.
  Future<void> fetchActiveSession() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('workout_session')
          .select('train_proto_id')
          .eq('user_id', userId)
          .filter('end_time', 'is', null)
          .limit(1);

      _activeProtoId = (response as List).isNotEmpty
          ? response.first['train_proto_id'] as int?
          : null;

      _notify();
    } catch (e) {
      debugPrint("Error fetching active session: $e");
    }
  }

  Future<void> saveWorkoutSessionLogs(List<Map<String, dynamic>> logs) async {
    try {
      final _supabase = Supabase.instance.client;
      
      // If there's nothing to save, just return
      if (logs.isEmpty) return;

      // Supabase allows you to insert a whole List of maps at once!
      await _supabase.from('workout_log').insert(logs);
      
      _notify();
    } catch (e) {
      debugPrint("Error batch saving workout logs: $e");
      throw Exception('Failed to save workout logs.');
    }
  }

  Future<void> saveWorkoutSessionWithLogs({
    required int protocolId,
    required String userId,
    required DateTime startTime,
    required DateTime endTime,
    required List<Map<String, dynamic>> logs,
  }) async {
    try {
      final _supabase = Supabase.instance.client;

      // 1. Create the Parent Session (Using .select() safely)
      final sessionResponse = await _supabase.from('workout_session').insert({
        'user_id': userId,
        'train_proto_id': protocolId,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
      }).select();

      // Get the ID from the first item returned
      final String sessionId = sessionResponse.first['session_id'];

      // 2. Attach the new session_id to every single set
      final List<Map<String, dynamic>> logsWithSession = logs.map((log) {
        return {
          'session_id': sessionId,      
          'workout_id': log['workout_id'],
          'set': log['set'],
          'weight': log['weight'],
          'reps': log['reps'],
        };
      }).toList();

      // 3. Batch Insert all sets at once
      if (logsWithSession.isNotEmpty) {
        await _supabase.from('workout_log').insert(logsWithSession);
      }
      await fetchUserQuickStats();
      _notify();
    } catch (e) {
      print("🚨 CRITICAL SAVE ERROR: $e");
      throw Exception('Failed to save workout session: $e');
    }
  }

  // Fetches Quick Stats & Calculates Progressive Overload
  Future<void> fetchUserQuickStats() async {
    try {
      final _supabase = Supabase.instance.client;
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // 1. Fetch all sessions AND join their associated logs using Supabase
      final response = await _supabase
          .from('workout_session')
          .select('start_time, workout_log(weight, reps)')
          .eq('user_id', userId)
          .order('start_time', ascending: true); // Oldest to newest

      int workouts = response.length;
      double lifetimeVolume = 0;
      List<double> volumePerSession = [];

      // 2. Calculate the volume (weight x reps) for every session
      for (var session in response) {
        double currentSessionVolume = 0;
        final logs = session['workout_log'] as List<dynamic>? ?? [];
        
        for (var log in logs) {
           final weight = (log['weight'] as num?)?.toDouble() ?? 0;
           final reps = (log['reps'] as num?)?.toInt() ?? 0;
           currentSessionVolume += (weight * reps);
        }
        
        lifetimeVolume += currentSessionVolume;
        volumePerSession.add(currentSessionVolume);
      }

      // 3. Progressive Overload Logic
      bool overloadAchieved = false;
      if (volumePerSession.length >= 2) {
        final lastSession = volumePerSession.last;
        final previousSession = volumePerSession[volumePerSession.length - 2];
        
        if (lastSession > previousSession && lastSession > 0) {
          overloadAchieved = true;
        }
      }

      // 4. Update the state
      _totalWorkouts = workouts;
      _totalVolume = lifetimeVolume;
      _hasProgressiveOverload = overloadAchieved;

      // 5. Also refresh the last logged protocol
      await _fetchLastLoggedProtocol();

      _notify();
    } catch (e) {
      debugPrint("Error fetching quick stats: $e");
    }
  }

  // Queries the most recent workout_session and matches it to a saved protocol
  // so the hero "Resume Schedule Log" button can open it directly.
  Future<void> _fetchLastLoggedProtocol() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Get the single most recent session for this user
      final response = await supabase
          .from('workout_session')
          .select('train_proto_id')
          .eq('user_id', userId)
          .order('start_time', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return;

      final int lastProtoId = response['train_proto_id'];

      // Match it against the locally loaded saved protocols
      final match = _workouts.where((w) => w.workoutId == lastProtoId).firstOrNull;

      if (match != null) {
        _lastLoggedWorkout = match;
      } else {
        // Protocol exists in sessions but isn't in saved list — fetch it directly
        final protoResponse = await supabase
            .from('training_protocol')
            .select('train_proto_id, proto_title, goal')
            .eq('train_proto_id', lastProtoId)
            .maybeSingle();

        if (protoResponse != null) {
          _lastLoggedWorkout = Workout(
            workoutId: protoResponse['train_proto_id'],
            workoutName: protoResponse['proto_title'] ?? 'Untitled Protocol',
            targetMuscles: [
              TargetMuscle(tarMuscId: 0, name: protoResponse['goal'] ?? 'General'),
            ],
          );
        }
      }
    } catch (e) {
      debugPrint("Error fetching last logged protocol: $e");
    }
  }
}