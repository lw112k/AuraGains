import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:auragains/features/post_feed/view_models/home/fyp_feed_viewmodel.dart';
import 'package:auragains/features/post_feed/views/widgets/home/post_card.dart';
import 'package:auragains/features/auth/view_models/auth_viewmodel.dart';

class FypFeedList extends StatelessWidget {
  const FypFeedList({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FypFeedViewModel>();

    final authVm = context.read<AuthViewModel>();
    final userId = authVm.currentUser!.id;

    if (vm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await vm.refreshFeed(
          userId: userId,
        );
      },

      child: GridView.builder(
        controller: vm.scrollController,

        physics: const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 10,
        ),

        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 0.63,
        ),

        itemCount: vm.posts.length + (vm.isFetchingMore ? 1 : 0),

        itemBuilder: (context, index) {
          if (index >= vm.posts.length) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final post = vm.posts[index];

          return PostCard(post: post);
        } 
      )
    );
  }
}