import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:auragains/core/widgets/clickable_avatar.dart';
import 'package:auragains/features/user_profile/views/user_profile_view.dart';

import 'package:auragains/features/post_feed/models/comment_model.dart';

import 'package:auragains/features/post_feed/view_models/post_detail/comment_viewmodel.dart';

import 'package:auragains/features/post_feed/views/widgets/common/report_button.dart';
import 'package:auragains/features/post_feed/views/widgets/common/like_count_button.dart';

class CommentCountButton extends StatelessWidget {

  final int postId;
  final String currentUserId;
  final int commentCount;

  final double iconSize;
  final double fontSize;
  final double gap;

  const CommentCountButton({
    super.key,
    required this.postId,
    required this.currentUserId,
    required this.commentCount,

    this.iconSize = 24,
    this.fontSize = 14,
    this.gap = 6,
  });

  @override
  Widget build(BuildContext context) { // Comment Icon and total comment

    return InkWell(
      borderRadius: BorderRadius.circular(999),

      onTap: () { // on tap action
        showModalBottomSheet(
          context: context,

          isScrollControlled: true,

          backgroundColor: Color.fromARGB(255, 51, 51, 51),

          builder: (_) {

            return ChangeNotifierProvider(
              create: (_) =>
                  CommentViewModel(
                    postId: postId,
                    currentUserId: currentUserId,
                  )..loadComments(),

              child: _CommentBottomSheet(),
            );
          },
        );
      },

      child: Row( // icon and count
        children: [

          Icon(
            Icons.comment_outlined,

            size: iconSize,
            color: Colors.white,
          ),

          SizedBox(width: gap),

          Text(
            '$commentCount',

            style: TextStyle(
              fontSize: fontSize,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentBottomSheet extends StatefulWidget {
  @override
  State<_CommentBottomSheet> createState() =>
      _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<_CommentBottomSheet> {

  final TextEditingController _controller = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  int? replyingToCommentId;
  String? replyingToUsername;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {

    final vm = context.read<CommentViewModel>();

    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 200) { // if want to load earlier, increase the number
      vm.loadMore();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final vm = context.watch<CommentViewModel>();

    return SafeArea(
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.82,

        padding: const EdgeInsets.only(
          top: 14,
        ),

        child: Column(
          children: [

            // ===================================
            // TOP HANDLE (above the "comment" title)
            // ===================================
            Container(
              width: 42,
              height: 5,

              decoration: BoxDecoration(
                color: Colors.grey.shade700,

                borderRadius: BorderRadius.circular(999),
              ),
            ),

            const SizedBox(height: 14),

            // ===================================
            // TITLE
            // ===================================
            const Text(
              'Comments',

              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 18),

            // ===================================
            // COMMENT LIST
            // ===================================
            Expanded(
              child: vm.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )

                  : ListView.builder(
                      controller: _scrollController,

                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),

                      itemCount: vm.commentList.length + (vm.isFetchingMore ? 1 : 0), // + 1 for loading indicator, if is fetching more

                      itemBuilder: (context, index) {
                        if (index >= vm.commentList.length) { // show loading indicator at the end of the list when fetching more
                          return const Padding(
                            padding: EdgeInsets.all(16),

                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final comment = vm.commentList[index]; // get comment data from the list base on index

                        return _CommentCard(
                          comment: comment,

                          onReply: () {
                            setState(() {
                              replyingToCommentId = comment.commentId;

                              replyingToUsername = comment.username;
                            });
                          },
                        );
                      },
                    ),
            ),

            // ===================================
            // REPLYING LABEL
            // ===================================
            if (replyingToUsername != null)

              Container(
                width: double.infinity,

                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),

                color: Colors.grey.shade900,

                child: Row(
                  children: [

                    Expanded(
                      child: Text(
                        'Replying to @$replyingToUsername',

                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTap: () {

                        setState(() {
                          replyingToCommentId = null;
                          replyingToUsername = null;
                        });
                      },

                      child: const Icon(
                        Icons.close,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),

            // ===================================
            // INPUT
            // ===================================
            Container(
              padding: const EdgeInsets.fromLTRB(
                16,
                12,
                16,
                18,
              ),

              child: Row(
                children: [

                  Expanded(
                    child: TextField(
                      controller: _controller,

                      style: const TextStyle(
                        color: Colors.white,
                      ),

                      decoration: InputDecoration(
                        hintText: 'Write a comment...',

                        hintStyle: const TextStyle(
                          color: Colors.white54,
                        ),

                        filled: true,

                        fillColor:Colors.grey.shade900,

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),

                          borderSide: BorderSide.none
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  IconButton(
                    onPressed: () async { // submit comment action

                      final text = _controller.text.trim();

                      if (text.isEmpty) return;

                      await vm.submitComment(
                        text: text,
                        parentId: replyingToCommentId,
                      );

                      _controller.clear();

                      setState(() {
                        replyingToCommentId = null;
                        replyingToUsername = null;
                      });
                    },

                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.cyanAccent,
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
}

class _CommentCard extends StatelessWidget {

  final CommentModel comment;
  final VoidCallback? onReply; // callback when tap the "Reply" button

  final bool isReply; // to determine if this comment card is a reply (second level comment), default is false (first level comment)

  const _CommentCard({
    required this.comment,
    this.onReply,
    this.isReply = false,
  });

  String get timeAgo {

    final diff = DateTime.now().difference(comment.createDate);

    if (diff.inMinutes < 1) {
      return 'now';
    }

    if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    }

    if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    }

    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CommentViewModel>();

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 24,
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              ClickableAvatar( // CREATOR AVATAR on left
                radius: 18,
                profilePicUrl: comment.profilePicUrl,
                username: comment.username,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileView(
                        targetUserId: comment.userId,
                        currentUserId: vm.currentUserId,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(width: 12),

              Expanded( // USERNAME, DATE AGO, COMMENT CONTENT, REPLY BUTTON on right
                child: Column( 
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Row(
                      children: [

                        Text( // USERNAME
                          comment.username,

                          maxLines: 1,

                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(width: 8),

                        Text( // DATE AGO
                          timeAgo,

                          style: TextStyle(
                            color:Colors.white,

                            fontSize: 11,
                          ),
                        ),

                        const Spacer(),

                        ReportButton( // REPORT BUTTON 
                          reportBy: vm.currentUserId,
                          targetType: 'comment',
                          targetId: comment.commentId,
                        ),

                        SizedBox(width: 4),
                      
                        LikeCountButton(
                          isLiked: comment.isLiked,
                          likeCount: comment.likeCount,

                          iconSize: 20,
                          fontSize: 14,
                          gap: 6,

                          onTap: () async {
                            await vm.toggleCommentLike(comment);
                          }
                        )
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      comment.text,

                      style: const TextStyle(
                        color: Colors.white,
                        height: 1.45
                      ),
                    ),

                    const SizedBox(height: 8),

                    if (!isReply) // only show the "Reply" button for first level comment, but not for second level comment (reply comment)
                      GestureDetector(
                        onTap: onReply,

                        child: Text(
                          'Reply',

                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.bold
                            
                          ),
                        ),
                      ),

                    if (!isReply && comment.replyCount > 0) // only show the "View replies" button for first level comment(must have replies), but not for second level comment (reply comment)
                      GestureDetector(
                        onTap: () {
                          vm.loadReplies(comment);
                        },

                        child: Text(
                          comment.repliesLoaded ? 'Hide replies' : 'View ${comment.replyCount} replies',

                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.bold
                            
                          ),
                        ),
                      ),

                    // ===================================
                    // REPLIES DISPLAY (only display the replies when user click the "View replies" button, and also only display the first level comment's replies, but not display the second level comment's replies because user cannot reply for the second level comment)
                    // ===================================
                    if (comment.replies.isNotEmpty && comment.showReplies)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 7
                        ),

                        child: Column(
                          children: comment.replies.map(
                            (reply) {

                              return _CommentCard(
                                comment: reply,
                                isReply: true,
                              );
                            },
                          ).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

