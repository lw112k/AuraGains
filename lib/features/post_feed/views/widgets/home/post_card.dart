import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auragains/features/auth/view_models/auth_viewmodel.dart';
import 'package:auragains/features/post_feed/models/post_preview_model.dart';
import 'package:auragains/features/post_feed/view_models/post_detail/post_detail_viewmodel.dart';
import 'package:auragains/features/post_feed/views/pages/post_detail/post_detail_view.dart';
import 'package:auragains/core/widgets/clickable_avatar.dart';
import 'package:auragains/features/user_profile/views/user_profile_view.dart';

class PostCard extends StatelessWidget {
  final PostPreviewModel post;

  const PostCard({
    super.key,
    required this.post,
  });

  // ===================================
  // IMAGE RULES
  // ===================================
  bool get hasThumbnail {
    return post.thumbnailUrl != null &&
        post.thumbnailUrl!.isNotEmpty;
  }

  bool get hasPictureMedia {
    return post.firstMediaType == 'picture' &&
        post.firstMediaUrl != null &&
        post.firstMediaUrl!.isNotEmpty;
  }

  // if the post is a video(first media) or it doesn't have valid thumbnail, 
  // then we will use text fallback as preview, otherwise we will use the thumbnail or picture(first media) media as preview
  bool get shouldUseTextFallback { 
    return (post.firstMediaType == 'video' && !hasThumbnail) ||
        (!hasThumbnail && !hasPictureMedia);
  }

  String get previewImage {
    if (hasThumbnail) {
      return post.thumbnailUrl!;
    }

    if (hasPictureMedia) {
      return post.firstMediaUrl!;
    }

    return '';
  }

  // ===================================
  // RANDOM BACKGROUND COLOR (Text Fallback only)
  // ===================================
  Color get randomColor {
    final colors = [
      Colors.deepPurple,
      Colors.blue,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.indigo,
    ];

    final random = Random(post.postId);

    return colors[random.nextInt(colors.length)];
  }

  // ===================================
  // TIME AGO CALCULATION
  // ===================================  
  String get timeAgo {
    final now = DateTime.now();

    final difference =
        now.difference(post.createDate);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    }

    return '${post.createDate.day}/${post.createDate.month}/${post.createDate.year}';
  }

  // ===================================
  // TEXT FALLBACK WIDGET
  // ===================================
  Widget buildTextFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            randomColor.withValues(
              alpha: 0.95,
            ),
            randomColor.withValues(
              alpha: 0.55,
            ),
          ],
        ),
      ),

      alignment: Alignment.center,

      padding: const EdgeInsets.all(22),

      child: Text(
        post.title,

        style: const TextStyle(
          color: Color.fromARGB(255, 226, 226, 226),
          fontSize: 14,
          height: 1.3,
        ),

        textAlign: TextAlign.center,

        maxLines: 5,

        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ===================================
  // BUILD METHOD
  // ===================================
  @override
  Widget build(BuildContext context) {
    final authVm = context.read<AuthViewModel>();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        splashColor: Colors.cyanAccent,

        onTap: () { // when user tap on the post card, navigate to the post detail view and pass the post id
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider(
                create: (context) {

                  final authVm = context.read<AuthViewModel>();

                  return PostDetailViewModel(
                    postId: post.postId,
                    currentUserId: authVm.currentUser!.id
                  )..loadPost();
                },

                child: const PostDetailView()
              )
            )
          );
        },

        child: Container(
          margin: const EdgeInsets.all(8),

          decoration: BoxDecoration(
            color: const Color.fromARGB(153, 0, 0, 0),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 8),
                color: const Color.fromARGB(255, 95, 95, 95).withValues(alpha: 0.25),
              ),
            ],
          ),

          clipBehavior: Clip.antiAlias, // clip the content to prevent it from overflowing the border radius

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              // ===================================
              // MEDIA AREA
              // ===================================
              Stack( // use stack to show the media preview, user info at top and like count and time ago info at bottom of the media preview
                children: [

                  // IMAGE / TEXT FALLBACK
                  AspectRatio(
                    aspectRatio: 0.82,

                    child: !shouldUseTextFallback  // if post has valid media or thumbnail picture, show it as preview
                        ? Image.network(
                            previewImage,

                            fit: BoxFit.cover,

                            // IMAGE ERROR FALLBACK (if the image url is invalid or failed to load, then we will show the text fallback instead)
                            errorBuilder: (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return buildTextFallback();
                            },
                          )

                        // ===================================
                        // TEXT FALLBACK (Text as preview thumnail for videos or posts without valid media(text post))
                        // ===================================
                        : buildTextFallback()
                  ),

                  // ===================================
                  // TOP DARK OVERLAY 
                  // ===================================
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.center,
                          colors: [
                            Colors.black.withValues(alpha: 0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ===================================
                  // USER INFO 
                  // ===================================
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,

                    child: Row(
                      children: [

                        ClickableAvatar(
                          radius: 15,
                          profilePicUrl: post.creatorProfileUrl,
                          username: post.creatorUsername,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserProfileView(
                                  targetUserId: post.creatorId,
                                  currentUserId: authVm.currentUser!.id,
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(width: 10), // spacing between avatar and username

                        Expanded(
                          child: Text(
                            post.creatorUsername,

                            maxLines: 1,

                            overflow: TextOverflow.ellipsis,

                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // VIDEO ICON at top right corner if the post is a video for first media
                        if (post.firstMediaType == 'video')
                          Container(
                            padding: const EdgeInsets.all(5),

                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.25),

                              shape: BoxShape.circle,
                            ),

                            child: const Icon(
                              Icons.play_arrow_rounded, // video icon

                              color:
                                  Colors.white,

                              size: 14,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ===================================
                  // BOTTOM INFO (like count and time ago)
                  // ===================================
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,

                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,

                      children: [

                        Row(
                          children: [
                            const Icon(
                              Icons.favorite_border, // Like icon
                              color:Colors.white,
                              size: 15,
                            ),

                            const SizedBox(width: 5),

                            Text(
                              '${post.likeCount}', // total like number

                              style: const TextStyle(
                                color: Colors.white,

                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        Text(
                          timeAgo, // Time ago text

                          style: const TextStyle(
                            color:Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ===================================
              // TITLE
              // ===================================
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),

                child: Center(
                  child: Text(
                    post.title,

                    textAlign:
                        TextAlign.center,

                    maxLines: 2,

                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      color: Colors.white
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
      )
    );
  }
}

