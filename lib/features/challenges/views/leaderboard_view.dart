import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../view_models/challenge_viewmodel.dart';

class LeaderboardView extends StatelessWidget {
  const LeaderboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final leaderboard = context.watch<ChallengeViewModel>().leaderboard;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    if (leaderboard.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.cyanAccent),
      );
    }

    final myIndex = leaderboard.indexWhere(
      (e) => e['user_id'] == currentUserId,
    );
    final myData = myIndex != -1 ? leaderboard[myIndex] : null;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            _buildPremiumPodium(leaderboard),
            const SizedBox(height: 30),
            // Rank 4+ List
            ...leaderboard.asMap().entries.where((e) => e.key >= 3).map((e) {
              return _buildModernTile(
                rank: e.key + 1,
                data: e.value,
                isMe: e.value['user_id'] == currentUserId,
              );
            }),
          ],
        ),

        // THE GLASS STICKY CARD
        if (myData != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildGlassUserCard(myIndex + 1, myData),
          ),
      ],
    );
  }

  // --- PREMIUM PODIUM (Gradients & Glows) ---
  Widget _buildPremiumPodium(List<Map<String, dynamic>> data) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (data.length > 1)
          Expanded(
            child: _podiumBlock(data[1], 2, 110, const Color(0xFFC0C0C0)),
          ), // Silver
        if (data.isNotEmpty)
          Expanded(
            child: _podiumBlock(data[0], 1, 150, const Color(0xFFFFD700)),
          ), // Gold
        if (data.length > 2)
          Expanded(
            child: _podiumBlock(data[2], 3, 90, const Color(0xFFCD7F32)),
          ), // Bronze
      ],
    );
  }

  Widget _podiumBlock(
    Map<String, dynamic> user,
    int rank,
    double height,
    Color medalColor,
  ) {
    return Column(
      children: [
        _avatarWithGlow(
          user['profile_pic_url'],
          user['username'],
          medalColor,
          rank == 1 ? 32 : 26,
        ),
        const SizedBox(height: 10),
        Text(
          user['username'] ?? '',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        Text(
          '${user['total_points']} PTS',
          style: TextStyle(
            color: medalColor,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: medalColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Center(
            // 💡 2. Changed text color to black87 for high contrast against the bright solid backgrounds
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 44,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- MODERN LIST TILES ---
  Widget _buildModernTile({
    required int rank,
    required Map<String, dynamic> data,
    bool isMe = false,
    bool isFooter = false,
  }) {
    return Container(
      // If it's the footer, we don't want a bottom margin pushing it off-center
      margin: EdgeInsets.only(bottom: isFooter ? 0 : 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.cyanAccent.withOpacity(0.05)
            : const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isMe ? Colors.cyanAccent : Colors.white10),
        boxShadow: isMe
            ? [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.1),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      //
      child: Row(
        children: [
          _avatarWithGlow(
            data['profile_pic_url'],
            data['username'],
            isMe ? Colors.cyanAccent : Colors.grey,
            20,
            badge: rank,
          ),
          const SizedBox(width: 15),
          Text(
            data['username'] ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const Spacer(),
          Text(
            '${data['total_points']}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 4),
          const Text('pts', style: TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  // --- HELPER: AVATAR WITH NEON GLOW ---
  Widget _avatarWithGlow(
    String? url,
    String? username,
    Color color,
    double radius, {
    int? badge,
  }) {
    // 💡 Safely calculate the initial
    final initial = (username != null && username.isNotEmpty)
        ? username[0].toUpperCase()
        : '?';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: Colors.blueAccent,
          backgroundImage: (url != null && url.isNotEmpty)
              ? NetworkImage(url)
              : null,
          child: (url == null || url.isEmpty)
              ? Text(
                  initial,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: radius * 0.8,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        if (badge != null)
          Positioned(
            top: -8,
            left: -8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$badge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // --- HELPER: THE GLASS STICKY FOOTER ---
  Widget _buildGlassUserCard(int rank, Map<String, dynamic> data) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          // Changed padding to symmetric so it is perfectly centered vertically
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            border: const Border(
              top: BorderSide(color: Colors.cyanAccent, width: 0.5),
            ),
          ),
          // Passed isFooter: true
          child: _buildModernTile(
            rank: rank,
            data: data,
            isMe: true,
            isFooter: true,
          ),
        ),
      ),
    );
  }
}
