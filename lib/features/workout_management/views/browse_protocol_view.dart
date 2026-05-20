import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'protocol_detail_view.dart'; // Ensure this file exists in your project
import 'package:provider/provider.dart';
import 'package:auragains/features/workout_management/models/workout_model.dart';
import 'package:auragains/features/workout_management/models/target_muscle_model.dart';
import 'package:auragains/features/workout_management/view_models/workout_view_model.dart';

class BrowseProtocolView extends StatefulWidget {
  const BrowseProtocolView({super.key});

  @override
  State<BrowseProtocolView> createState() => _BrowseProtocolViewState();
}

class _BrowseProtocolViewState extends State<BrowseProtocolView> {
  // ==========================================
  // 🎨 THEME VARIABLES
  // ==========================================
  final Color _bgColor = const Color(0xFF121212);
  final Color _cardColor = const Color(0xFF1A1A1A);
  final Color _tagColor = const Color(0xFF2A2A2A);
  final Color _accentColor = const Color(0xFF00E5FF); // Neon Blue
  final Color _textPrimary = Colors.white;
  final Color _textSecondary = const Color(0xFF9E9E9E);

  // ==========================================
  // 🗄️ SUPABASE STATE VARIABLES
  // ==========================================
  final _supabase = Supabase.instance.client;
  
  bool _isLoading = true;
  List<dynamic> _protocols = [];
  List<dynamic> _filteredProtocols = [];
  List<dynamic> _targetMuscles = [];

  // Filter State
  String _selectedMuscleName = "All Muscles";// Null means 'All'
  dynamic _selectedMuscleId;

  @override
  void initState() {
    super.initState();
    _fetchDatabaseData();
  }

  //FETCH DATA FROM SUPABASE
  Future<void> _fetchDatabaseData() async {
    try {
      // 1. Fetch Target Muscles for the filter dropdown
      final muscleResponse = await _supabase.from('target_muscle').select();
      
      // 2. Fetch Training Protocols with deep nested joins
      // This goes: Protocol -> protocol_workout -> workout -> workout_target_muscle -> target_muscle
      // Only fetch PUBLIC protocols — private ones belong only to the creator's workout_view
      final protocolResponse = await _supabase.from('training_protocol').select('''
        *,
        user!training_protocol_create_by_fkey ( username ),
        protocol_workout (
          workout (
            workout_id,
            workout_name,
            workout_target_muscle (
              tar_musc_id
            )
          )
        )
      ''').eq('is_public', true);
      

      setState(() {
        _targetMuscles = muscleResponse;
        _protocols = protocolResponse;
        _filteredProtocols = protocolResponse; // Show all initially
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error fetching data: $error');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $error')),
        );
      }
    }
  }


  void _applyFilter(dynamic muscleId, String muscleName) {
    setState(() {
      _selectedMuscleId = muscleId;
      _selectedMuscleName = muscleName;
  
      if (muscleId == null) {
        _filteredProtocols = _protocols;
      } else {
        _filteredProtocols = _protocols.where((protocol) {
          final goal = protocol['goal']?.toString().toLowerCase() ?? '';
          return goal.contains(muscleName.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _buildAppBar(),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))) // Show loader
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Browse Training Protocols',
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // The Prominent Filter Button
                        _buildProminentFilterButton(),
                        
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                
                // Main List of Protocols from Supabase
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: _filteredProtocols.isEmpty
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: Text(
                              'No protocols found for this filter.',
                              style: TextStyle(color: _textSecondary),
                            ),
                          ),
                        )
                      : SliverList.builder(
                          itemCount: _filteredProtocols.length,
                          itemBuilder: (context, index) {
                            final protocol = _filteredProtocols[index];
                            final userData = protocol['user'];
                            final authorName = userData != null ? userData['username'] : 'Unknown User';
                            // Extract all unique muscle names from the nested data for the UI tags
                            Set<String> uniqueMuscles = {};
                            final protocolWorkouts = protocol['protocol_workout'] as List<dynamic>? ?? [];
                            for (var pw in protocolWorkouts) {
                              final workout = pw['workout'];
                              if (workout != null) {
                                final pivots = workout['workout_target_muscle'] as List<dynamic>? ?? [];
                                for (var pivot in pivots) {
                                  final tarMuscId = pivot['tar_musc_id'];  // ✅ flat ID
                                  // Find the name from the already-fetched _targetMuscles list
                                  final match = _targetMuscles.firstWhere(
                                    (m) => m['tar_musc_id']?.toString() == tarMuscId?.toString(),
                                    orElse: () => null,
                                  );
                                  if (match != null) uniqueMuscles.add(match['name']);
                                }
                              }
                            }
                            // Map database fields to UI
                            return _buildProtocolCard(
                              title: protocol['proto_title'] ?? 'Untitled Protocol',
                              // UUIDs aren't pretty, so you'd normally join a Users table here to get the username
                              author: authorName, 
                              // Map goals or description to tags
                              tags: uniqueMuscles.isNotEmpty ? uniqueMuscles.toList() : [protocol['goal'] ?? 'General'],
                              themeColor: const Color(0xFF1E3A1E), // You can randomize or generate this dynamically later
                              protocolData: protocol, // Pass full object if needed for detail view
                            );
                          },
                        ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
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
    );
  }


  Widget _buildProminentFilterButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showFilterBottomSheet,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _accentColor.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _accentColor.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ]
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.tune, color: _accentColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TARGET MUSCLE',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedMuscleName,
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.keyboard_arrow_down_rounded, color: _textSecondary, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProtocolCard({
    required String title,
    required String author,
    required List<String> tags,
    required Color themeColor,
    required dynamic protocolData,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProtocolDetailView(protocolData: protocolData),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias, 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [themeColor, _cardColor],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _accentColor,  
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'COMMUNITY PROTOCOL',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Bottom Content Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'by $author',
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: tags.map((tag) => _buildTag(tag)).toList(),
                        ),
                      ],
                    ),
                  ),
                  
                  // 🗑️ The Row containing the copy IconButton was completely removed from here!
                  
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _tagColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: _textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ==========================================
  // ⚙️ SUPABASE BOTTOM SHEET 
  // ==========================================

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Select Target Muscle',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // Option to reset filter
                    _buildFilterListTile(null, "All Muscles"),
                    
                    // Options from Database
                    ..._targetMuscles.map((muscle) {
                      return _buildFilterListTile(
                        muscle['tar_musc_id'], // Adjust to your actual primary key name
                        muscle['name'],
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterListTile(dynamic muscleId, String muscleName) {
    final isSelected = muscleId?.toString() == _selectedMuscleId?.toString();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
      title: Text(
        muscleName,
        style: TextStyle(
          color: isSelected ? _accentColor : _textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 16,
        ),
      ),
      trailing: isSelected 
        ? Icon(Icons.check_circle, color: _accentColor) 
        : const Icon(Icons.circle_outlined, color: Colors.grey),
      onTap: () {
        _applyFilter(muscleId, muscleName);
        Navigator.pop(context); // Close the sheet on tap
      },
    );
  }
}
