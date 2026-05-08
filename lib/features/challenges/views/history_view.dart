import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import '../view_models/challenge_viewmodel.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  @override
  void initState() {
    super.initState();
    // Fetch history using the current user's UUID on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
      context.read<ChallengeViewModel>().loadHistory(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChallengeViewModel>();
    final historyItems = viewModel.filteredHistory;

    return Column(
      children: [
        _buildFilterBar(viewModel),
        Expanded(
          child: historyItems.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: historyItems.length,
                  itemBuilder: (context, index) =>
                      _buildHistoryCard(historyItems[index], context),
                ),
        ),
      ],
    );
  }

  // =======================================================================
  // 1. FILTER BAR
  // =======================================================================
  Widget _buildFilterBar(ChallengeViewModel vm) {
    final filters = ['all', 'pending', 'approved', 'rejected'];
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: filters.map((status) {
          final isSelected = vm.historyFilter == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                status.toUpperCase(),
                style: const TextStyle(fontSize: 10),
              ),
              selected: isSelected,
              onSelected: (_) => vm.setHistoryFilter(status),
              selectedColor: Colors.cyanAccent.withOpacity(0.2),
              backgroundColor: Colors.transparent,
              labelStyle: TextStyle(
                color: isSelected ? Colors.cyanAccent : Colors.grey,
              ),
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected ? Colors.cyanAccent : Colors.white10,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // =======================================================================
  // 2. HISTORY LIST CARD
  // =======================================================================
  Widget _buildHistoryCard(Map<String, dynamic> item, BuildContext context) {
    final status = item['chall_status'].toString().toLowerCase();
    final isApproved = status == 'approved';

    final color = isApproved
        ? Colors.cyanAccent
        : (status == 'rejected' ? Colors.redAccent : Colors.amberAccent);

    // Strict logic: 0 points shown unless explicitly approved
    final displayedPoints = isApproved ? item['point_reward'] : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(
                item['challenge_name'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                item['submission_date'].toString().split('T')[0],
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white.withOpacity(0.03),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () =>
                        _showDetailsModal(context, item, color, status),
                    icon: Icon(Icons.info_outline, color: color, size: 16),
                    label: Text(
                      "View Details",
                      style: TextStyle(color: color, fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  Text(
                    "$displayedPoints PTS",
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, color: Colors.grey[800], size: 64),
          const SizedBox(height: 16),
          const Text(
            "No matches found in your history.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // =======================================================================
  // 3. THE DETAILS MODAL (Glassmorphism)
  // =======================================================================
  void _showDetailsModal(
    BuildContext context,
    Map<String, dynamic> item,
    Color color,
    String status,
  ) {
    final bool isDaily = item['is_daily'] == true;
    final String questType = isDaily ? "DAILY QUEST" : "WEEKLY QUEST";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF121212).withOpacity(0.9),
                border: Border(
                  top: BorderSide(color: color.withOpacity(0.5), width: 1),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            questType,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item['challenge_name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Submission ID: ${item['chall_submission_id']}",
                      style: TextStyle(color: Colors.grey[700], fontSize: 10),
                    ),

                    const Divider(color: Colors.white10, height: 30),

                    // Description & Metadata
                    const Text(
                      "Description",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['challenge_desc'] ?? 'No description provided.',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        _buildMetaItem(
                          "Submitted",
                          item['submission_date'].toString().split('T')[0],
                          Icons.calendar_today,
                        ),
                        const SizedBox(width: 40),
                        _buildMetaItem(
                          "Reward",
                          "${item['point_reward']} PTS",
                          Icons.bolt,
                          textColor: Colors.cyanAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Conditional: Rejected State
                    if (status == 'rejected' &&
                        item['reject_reason'] != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.redAccent.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Reason for Rejection",
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['reject_reason'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Conditional: Approved State
                    if (status == 'approved' && item['verify_by'] != null) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.verified_user,
                            color: Colors.cyanAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Verified By Admin ID: ${item['verify_by'].toString().substring(0, 8)}...",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Media Preview Trigger
                    if (item['vid_evidence_url'] != null)
                      GestureDetector(
                        onTap: () =>
                            _openMediaViewer(context, item['vid_evidence_url']),
                        child: Container(
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.play_circle_fill,
                                color: Colors.white,
                                size: 40,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Tap to view submission media",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetaItem(
    String title,
    String value,
    IconData icon, {
    Color textColor = Colors.white,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, color: textColor, size: 14),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // =======================================================================
  // 4. IN-APP MEDIA VIEWER (Smart Image & Video Parser)
  // =======================================================================
  void _openMediaViewer(BuildContext context, String url) {
    // 💡 Smarter parsing: extracts the path to avoid query parameters breaking the check
    final String path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
    final bool isVideo =
        path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.webm');

    // Default to image if it's not explicitly a video
    final bool isImage = !isVideo;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  color: const Color(0xFF121212),
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  child: isVideo
                      ? VideoPreviewPlayer(url: url)
                      : InteractiveViewer(
                          panEnabled: true,
                          minScale: 1.0,
                          maxScale: 4.0,
                          child: Image.network(
                            url,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.cyanAccent,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint("🖼️ Image Load Error: $error");
                              return const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      color: Colors.white54,
                                      size: 50,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Image failed to load",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.6),
                  radius: 18,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// =======================================================================
// 5. VIDEO PREVIEW PLAYER STATEFUL WIDGET
// =======================================================================
class VideoPreviewPlayer extends StatefulWidget {
  final String url;
  const VideoPreviewPlayer({super.key, required this.url});

  @override
  State<VideoPreviewPlayer> createState() => _VideoPreviewPlayerState();
}

class _VideoPreviewPlayerState extends State<VideoPreviewPlayer> {
  late VideoPlayerController _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize()
          .then((_) {
            if (mounted) {
              setState(() {});
              _controller.setLooping(true);
              _controller.play();
            }
          })
          .catchError((error) {
            // 💡 CRITICAL: This will print the EXACT reason the video failed in your VSCode terminal
            debugPrint("🎥 Video Player Error: $error");
            debugPrint("🎥 URL Attempted: ${widget.url}");
            if (mounted) {
              setState(() => _hasError = true);
            }
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
            SizedBox(height: 8),
            Text(
              "Error playing video",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Check VSCode terminal for details",
              style: TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
      );
    }

    return _controller.value.isInitialized
        ? Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          )
        : const Center(
            child: CircularProgressIndicator(color: Colors.cyanAccent),
          );
  }
}
