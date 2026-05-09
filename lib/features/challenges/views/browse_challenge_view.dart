import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:path/path.dart' as p; 

import '../view_models/challenge_viewmodel.dart';
import '../models/challenge_model.dart';

class BrowseChallengeView extends StatefulWidget {
  const BrowseChallengeView({super.key});

  @override
  State<BrowseChallengeView> createState() => _BrowseChallengeViewState();
}

class _BrowseChallengeViewState extends State<BrowseChallengeView> {
  Timer? _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Fetch the daily challenges the moment this tab loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChallengeViewModel>().fetchChallenges();
    });

    // Start the countdown timer
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _updateTimeLeft();
    // Initial call
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimeLeft();
    });
  }

  void _updateTimeLeft() {
    if (!mounted) return;

    final viewModel = context.read<ChallengeViewModel>();
    final now = viewModel.trueNow;
    DateTime targetDate;

    if (viewModel.currentFilter == 'Daily') {
      // Next midnight
      targetDate = DateTime(now.year, now.month, now.day + 1);
    } else {
      // Next Monday midnight (Weekly reset)
      int daysUntilMonday = 8 - now.weekday;
      targetDate = DateTime(now.year, now.month, now.day + daysUntilMonday);
    }

    setState(() {
      _timeLeft = targetDate.difference(now);
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours.remainder(24));
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inDays > 0) {
      return "${duration.inDays}d ${hours}h ${minutes}m";
    }
    return "${hours}h ${minutes}m ${seconds}s";
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChallengeViewModel>();

    return Column(
      children: [
        // --- FILTER & TIMER ROW ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Dynamic Timer Display
              Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    color: Colors.cyanAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Resets in: ${_formatDuration(_timeLeft)}',
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),

              // Filter Dropdown
              Row(
                children: [
                  const Text(
                    'Filter By: ',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: viewModel.currentFilter,
                        dropdownColor: Colors.grey[800],
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 16,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            viewModel.setFilter(newValue);
                            _updateTimeLeft(); // Force timer update when swapped
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: 'Daily',
                            child: Text('Daily'),
                          ),
                          DropdownMenuItem(
                            value: 'Weekly',
                            child: Text('Weekly'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // --- CHALLENGE LIST ---
        Expanded(
          child: viewModel.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.cyanAccent),
                )
              : viewModel.browseChallenges.isEmpty
              ? const Center(
                  child: Text(
                    "No challenges found.",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: viewModel.browseChallenges.length,
                  itemBuilder: (context, index) {
                    final challenge = viewModel.browseChallenges[index];
                    return _buildChallengeCard(context, challenge);
                  },
                ),
        ),
      ],
    );
  }

  // --- INDIVIDUAL CARD WIDGET ---
  Widget _buildChallengeCard(BuildContext context, ChallengeModel challenge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x14FFFFFF), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Challenge Title
          Text(
            challenge.name,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 8),

          // 2. Challenge Description
          Text(
            challenge.description,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),

          // 3. Points & Button Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // The "REWARD" stack
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REWARD',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '+${challenge.pointReward} pts',
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),

              // The Submit Button
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: challenge.isCompleted
                      ? null
                      : () => _showSubmitModal(context, challenge),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: challenge.isCompleted
                        ? Colors.grey[800]
                        : Colors.cyanAccent,
                    foregroundColor: challenge.isCompleted
                        ? Colors.grey[500]
                        : Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    challenge.isCompleted ? 'Submitted' : 'Submit Quest',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- MEDIA SUBMISSION MODAL ---
  void _showSubmitModal(BuildContext context, ChallengeModel challenge) {
    Uint8List? selectedMediaBytes;
    String? selectedFileName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final viewModel = context.watch<ChallengeViewModel>();

            return Container(
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.cyanAccent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+${challenge.pointReward} PTS',
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    challenge.name,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    challenge.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),

                  // Media Upload Box Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SUBMIT PROOF:',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                      const Text(
                        'Limit: 50MB',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 💡 1. THE FILE PICKER AREA
                  GestureDetector(
                    onTap: viewModel.isSubmitting
                        ? null
                        : () async {
                            final ImagePicker picker = ImagePicker();
                            final XFile? media = await picker.pickMedia(
                              imageQuality: 80,
                            );

                            if (media != null) {
                              final bytes = await media.readAsBytes();
                              setModalState(() {
                                selectedMediaBytes = bytes;
                                selectedFileName = media.name;
                              });
                            }
                          },
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(16),
                        border: selectedMediaBytes != null
                            ? Border.all(color: Colors.cyanAccent, width: 2)
                            : null,
                      ),
                      child: selectedMediaBytes == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.perm_media_outlined,
                                  color: Colors.grey[400],
                                  size: 48,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to select 1 Image or Video',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.cyanAccent,
                                  size: 48,
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: Text(
                                    selectedFileName ?? 'File Selected',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Ready to upload',
                                  style: TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  if (viewModel.lastErrorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.redAccent.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          viewModel.lastErrorMessage!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // 💡 2. THE SUBMIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      // Disable button if submitting OR if no file has been picked yet
                      onPressed:
                          (viewModel.isSubmitting || selectedMediaBytes == null)
                          ? null
                          : () async {
                              // Extract the true extension from the picked filename
                              final String extension = p
                                  .extension(selectedFileName!)
                                  .toLowerCase();

                              // Call the ViewModel with the 3 required parameters
                              final success = await viewModel.submitChallenge(
                                challenge.challId,
                                selectedMediaBytes!,
                                extension,
                              );

                              // Trigger UI updates on success
                              if (success && context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Challenge submitted successfully!',
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: viewModel.isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Submit Challenge',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
