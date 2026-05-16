import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:photo_view/photo_view.dart';

import 'package:auragains/features/post_feed/models/post_media_model.dart';
import 'package:auragains/features/post_feed/models/post_detail_model.dart';
import 'package:auragains/features/post_feed/view_models/post_detail/post_detail_viewmodel.dart';
import 'package:auragains/core/widgets/clickable_avatar.dart';
import 'package:auragains/features/user_profile/views/user_profile_view.dart';
import 'package:auragains/features/post_feed/views/widgets/common/report_bottom_sheet.dart';
import 'package:auragains/features/post_feed/repositories/report_repository.dart';

class PostDetailView extends StatelessWidget {
  const PostDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PostDetailViewModel>();

    final reportRepo = ReportRepository();

    if (vm.isLoading || vm.post == null) { // show loading indicator while fetching post details
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final PostDetailModel post = vm.post!;

    return Scaffold(
      // ===================================
      // FIXED BOTTOM INTERACTION BAR (Like, Save, Comment + Post Date)
      // ===================================
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),

        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          border: Border(
            top: BorderSide(
              color: Colors.cyanAccent,
            ),
          ),
        ),

        child: SafeArea( // interaction buttons + post date
          top: false,

          child: Row(
            children: [

              Icon( // LIKE BUTTON
                post.isLiked
                    ? Icons.favorite
                    : Icons.favorite_border,

                color:
                    post.isLiked ? Colors.cyanAccent : Colors.white,
              ),

              const SizedBox(width: 6),

              Text(
                '${post.likeCount}',

                style: TextStyle(
                  color: post.isLiked ? Colors.cyanAccent : Colors.white,
                ),
              ),

              const SizedBox(width: 24),

              Icon( // SAVE BUTTON
                post.isSaved
                    ? Icons.bookmark
                    : Icons.bookmark_border,

                color: post.isSaved ? Colors.cyanAccent : Colors.white,
              ),

              const SizedBox(width: 6),

              Text(
                '${post.totalSave}',

                style: TextStyle(
                  color: post.isSaved ? Colors.cyanAccent : Colors.white,
                ),
              ),

              const SizedBox(width: 24),

              const Icon( // COMMENT BUTTON
                Icons.comment_outlined,
                color: Colors.white,
              ),

              const SizedBox(width: 6),

              Text(
                '${post.totalComment}',

                style: TextStyle(
                  color: Colors.white,
                ),
              ),

              const Spacer(),

              Text( // POST DATE
                '${post.createDate.day}/${post.createDate.month}/${post.createDate.year}',

                style: TextStyle(
                  color: Colors.grey.shade400
                ),
              ),
            ],
          ),
        ),
      ),

      body: SafeArea(
        child: Stack(
          children: [

            // ===================================
            // SCROLLABLE CONTENT (Post detail main content)
            // ===================================
            SingleChildScrollView(
              child: Column(
                children: [

                  // ===================================
                  // MEDIA SECTION
                  // ===================================
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.5, // 50% of screen height

                    child: _MediaSection(
                      post: post,
                    ),
                  ),

                  // ===================================
                  // CONTENT SECTION (title, description, tags, creator info, report button)
                  // ===================================
                  Container(
                    width: double.infinity,

                    padding: const EdgeInsets.all(18),

                    color: const Color.fromARGB(115, 0, 0, 0),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        // ===================================
                        // CREATOR ROW 
                        // ===================================
                        Row(
                          children: [

                            ClickableAvatar( // CREATOR AVATAR
                              radius: 18,
                              profilePicUrl: post.creatorProfileUrl,
                              username: post.creatorUsername,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserProfileView(
                                      targetUserId: post.creatorId,
                                      currentUserId: vm.currentUserId,
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(width: 12),

                            Expanded( // USERNAME
                              child: Text(
                                post.creatorUsername,

                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            IconButton( // REPORT BUTTON
                              onPressed: () {
                              showModalBottomSheet(
                                context: context,

                                builder: (_) {
                                  return ReportBottomSheet( // REPORT BOTTOM SHEET widget (inside pages/widgets/common/)

                                    onSubmit: (reason) async {

                                      await reportRepo.submitReport(
                                        reportBy: vm.currentUserId,
                                        targetType: 'post',
                                        targetId: post.postId,
                                        reason: reason,
                                      );
                                    },
                                  );
                                },
                              );
                            },

                              icon: const Icon(
                                Icons.flag_outlined,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // ===================================
                        // LINE DIVIDER
                        // ===================================
                        Container(
                            height: 1.2,

                            decoration: BoxDecoration(
                              color: Colors.white,

                              borderRadius: BorderRadius.circular(
                                999,
                              ),
                            ),
                          ),

                        const SizedBox(height: 18),

                        // ===================================
                        // TITLE
                        // ===================================
                        Text(
                          post.title,

                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ===================================
                        // DESCRIPTION
                        // ===================================
                        if (post.description != null &&
                            post.description!.isNotEmpty)
                          Text(
                            post.description!,

                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),

                        const SizedBox(height: 18),

                        // ===================================
                        // TAGS
                        // ===================================
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,

                          children:
                              post.tagList.map((tag) {

                            final isSystemTag =
                                tag.tagType == 'system';

                            return Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),

                              decoration: BoxDecoration(
                                color: isSystemTag
                                    ? Colors.cyanAccent
                                    : Colors.grey.shade800,

                                borderRadius:
                                    BorderRadius.circular(
                                  999,
                                ),
                              ),

                              child: Text(
                                tag.name,

                                style: TextStyle(
                                  color:
                                      isSystemTag
                                          ? Colors.black
                                          : Colors.white,

                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        // ===================================
                        // EXTRA BOTTOM SPACE
                        // ===================================
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ===================================
            // BACK BUTTON (Top left corner)
            // ===================================
            Positioned(
              top: 10,
              left: 10,

              child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(
                      alpha: 0.45,
                    ),

                    shape: BoxShape.circle,
                  ),

                  child: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },

                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaSection extends StatefulWidget { // handles media display (images/videos) with fallback to thumbnail or title if no media available
  final PostDetailModel post;

  const _MediaSection({
    required this.post,
  });

  @override
  State<_MediaSection> createState() =>
      _MediaSectionState();
}

class _MediaSectionState
    extends State<_MediaSection> {

  int currentIndex = 0;

  bool get hasMedia {
    return widget.post.mediaList.isNotEmpty;
  }

  bool get hasThumbnail {
    return widget.post.thumbnailUrl != null &&
        widget.post.thumbnailUrl!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {

    // ===================================
    // MEDIA PAGEVIEW
    // ===================================
    if (hasMedia) {
      return Stack(
        children: [

          PageView.builder(
            itemCount: widget.post.mediaList.length,

            onPageChanged: (index) { // update current index for page indicator
              setState(() {
                currentIndex = index;
              });
            },

            itemBuilder: (context, index) {

              final PostMediaModel media = widget.post.mediaList[index];

              // ===================================
              // IMAGE
              // ===================================
              if (media.mediaType == 'picture') {
                return Container(
                  color: Colors.black,

                  child: PhotoView(
                    imageProvider: NetworkImage(media.mediaUrl), // get image via the link from network

                    backgroundDecoration: const BoxDecoration(
                      color: Colors.black,
                    ),

                    minScale: PhotoViewComputedScale.contained,

                    maxScale: PhotoViewComputedScale.covered * 3, // allow zooming up to 3x

                    errorBuilder: // if image fails to load, show fallback (post title with dark background)
                        (_, __, ___) {
                      return _buildFallback();
                    },
                  ),
                );
              }

              // ===================================
              // VIDEO
              // ===================================
              return _VideoPlayerWidget( // else if it's a video, use the custom video player widget defined below
                videoUrl: media.mediaUrl,
              );
            },
          ),

          // ===================================
          // PAGE INDICATOR (Display dots at the bottom center if there are multiple media items)
          // ===================================
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,

            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,

              children: List.generate(
                widget.post.mediaList.length, (index) {

                  final isActive = currentIndex == index;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),

                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                    ),

                    width: isActive ? 18 : 8,
                    height: 8,

                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.cyanAccent
                          : const Color.fromARGB(39, 24, 255, 255),

                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
    }

    // ===================================
    // THUMBNAIL FALLBACK
    // ===================================
    if (hasThumbnail) {
      return Image.network(
        widget.post.thumbnailUrl!,

        fit: BoxFit.cover,

        width: double.infinity,

        errorBuilder: (_, __, ___) {
          return _buildFallback();
        },
      );
    }

    // ===================================
    // TEXT FALLBACK
    // ===================================
    return _buildFallback();
  }

  Widget _buildFallback() {
    return Container(
      width: double.infinity,

      color: const Color.fromARGB(
        255,
        66,
        66,
        66,
      ),

      alignment: Alignment.center,

      padding: const EdgeInsets.all(28),

      child: Text(
        widget.post.title,

        textAlign: TextAlign.center,

        style: const TextStyle(
          color: Colors.cyanAccent,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
      ),
    );
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const _VideoPlayerWidget({
    required this.videoUrl,
  });

  @override
  State<_VideoPlayerWidget> createState() =>
      _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {

  late VideoPlayerController _controller;

  bool isLoading = true;

  bool hasError = false;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );

    // ===================================
    // LISTENER
    // ===================================
    _controller.addListener(() {

      if (mounted) { // update UI when video player state changes (e.g. play/pause, buffering, etc.)
        setState(() {});
      }
    });

    // ===================================
    // INITIALIZE
    // ===================================
    _controller.initialize().then((_) {

      // auto play
      _controller.play();

      setState(() {
        isLoading = false;
      });

    }).catchError((error) {

      setState(() {
        isLoading = false;
        hasError = true;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    // ===================================
    // LOADING
    // ===================================
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // ===================================
    // ERROR
    // ===================================
    if (hasError) {
      return Container(
        color: Colors.black,

        alignment: Alignment.center,

        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Icon(
              Icons.error_outline,
              color: Colors.white54,
              size: 42,
            ),

            SizedBox(height: 12),

            Text(
              'Failed to load video',

              style: TextStyle(
                color: Colors.white54,
              ),
            ),
          ],
        ),
      );
    }

    // ===================================
    // VIDEO PLAYER
    // ===================================
    return Stack(
      alignment: Alignment.center,

      children: [

        // ===================================
        // VIDEO
        // ===================================
        Container(
          color: Colors.black,

          child: Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,

              child: VideoPlayer(
                _controller,
              ),
            ),
          ),
        ),

        // ===================================
        // TAP LAYER
        // ===================================
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,

            onTap: () { // toggle play/pause on tap

              if (_controller.value.isPlaying) {
                _controller.pause();
              }

              else {
                _controller.play();
              }
            },
          ),
        ),

        // ===================================
        // PLAY ICON OVERLAY, if video is paused, show a play icon in the center
        // ===================================
        if (!_controller.value.isPlaying)
          Container(
            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: Colors.black.withValues(
                alpha: 0.4,
              ),

              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.play_arrow,

              color: Colors.white,
              size: 40,
            ),
          ),
      ],
    );
  }
}