import 'package:flutter/material.dart';

/// A highly reusable, customizable avatar widget used across the application.
///
/// This widget automatically handles:
/// * Displaying network images safely.
/// * Falling back to a styled text initial if the user has no photo.
/// * Adding a glowing border for leaderboard podiums.
/// * Adding a camera icon for profile editing screens.
/// * Wrapping the avatar in a clickable area for navigation.
class ClickableAvatar extends StatelessWidget {
  /// The network URL of the user's profile picture. Can be null or empty.
  final String? profilePicUrl;

  /// The user's username. Used to generate the fallback text initial (e.g., 'D' for 'Daniel').
  final String? username;

  /// The size of the avatar.
  /// Suggested sizes: 16 (App Bar), 24 (Inbox), 32 (Leaderboard), 48 (Profile Page).
  final double radius;

  /// The function to execute when the avatar is tapped.
  /// If left null, the avatar will not be clickable.
  final VoidCallback? onTap;

  /// Set to true to display a small camera icon in the bottom right corner.
  /// Typically used on the logged-in user's profile editing page.
  final bool showCameraIcon;

  /// Set to true to add a glowing drop shadow behind the avatar.
  /// Typically used to highlight Top 3 ranks on a leaderboard.
  final bool showGlow;

  /// The color of the glow effect. Defaults to cyan, but can be changed for medals.
  /// Example: Color(0xFFFFD700) for Gold.
  final Color glowColor;

  const ClickableAvatar({
    // PARAMETERS TO INCLUDE
    super.key,
    required this.profilePicUrl, // MUST BE INCLUDED
    required this.username, // MUST BE INCLUDED
    this.radius = 20.0, // DESIGN OPTIONAL BUT THESE ARE DEFAULT VALUES
    this.onTap, // DESIGN OPTIONAL BUT THESE ARE DEFAULT VALUES
    this.showCameraIcon = false, // DESIGN OPTIONAL BUT THESE ARE DEFAULT VALUES
    this.showGlow = false, // DESIGN OPTIONAL BUT THESE ARE DEFAULT VALUES
    this.glowColor = Colors.cyanAccent, // DESIGN OPTIONAL BUT THESE ARE DEFAULT VALUES
  });

  @override
  Widget build(BuildContext context) {
    // 1. Safely calculate the initial for the fallback text
    final initial = (username != null && username!.isNotEmpty)
        ? username![0].toUpperCase()
        : '?';

    // 2. Build the Base Avatar
    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor:
          Colors.blueAccent, // Consistent fallback background color
      backgroundImage: (profilePicUrl != null && profilePicUrl!.isNotEmpty)
          ? NetworkImage(profilePicUrl!)
          : null,
      child: (profilePicUrl == null || profilePicUrl!.isEmpty)
          ? Text(
              initial,
              style: TextStyle(
                color: Colors.white,
                fontSize:
                    radius *
                    0.8, // Auto-scales text perfectly to fit the radius
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );

    // 3. Add Glow if requested (e.g., Leaderboard Podium)
    if (showGlow) {
      avatar = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: glowColor.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: avatar, // Wrap the base avatar inside the glowing container
      );
    }

    // 4. Add Camera Icon if requested (e.g., Profile Page)
    if (showCameraIcon) {
      avatar = Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          avatar, // The base (or glowing) avatar
          Container(
            padding: EdgeInsets.all(
              radius * 0.15,
            ), // Automatically scales with the avatar
            decoration: const BoxDecoration(
              color: Colors.cyanAccent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.camera_alt,
              color: Colors.black,
              size: radius * 0.4, // Automatically scales with the avatar
            ),
          ),
        ],
      );
    }

    // 5. Make it Clickable if an onTap action is provided
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }

    // Otherwise, return it as a static, non-clickable image
    return avatar;
  }
}
