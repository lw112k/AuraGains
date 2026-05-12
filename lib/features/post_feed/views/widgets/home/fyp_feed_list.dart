import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:auragains/features/post_feed/view_models/home/home_viewmodel.dart';
import 'package:auragains/features/post_feed/views/widgets/home/post_card.dart';
class FypFeedList extends StatelessWidget {
  const FypFeedList({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    if (vm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(), // if vm status still loading show loading indicator and return, loading status is updated to false
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await vm.refreshFeed(); // when user pull to refresh, call refreshFeed method in viewmodel to refresh the feed
      },

      child: GridView.builder(
        controller: vm.scrollController,

        physics: const AlwaysScrollableScrollPhysics(),// 

        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 10,
        ),

        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // number of columns in the grid
          crossAxisSpacing: 4, // horizontal spacing between the grid items
          mainAxisSpacing: 4, // vertical spacing between the grid items
          childAspectRatio: 0.66, //size of the post card, the width is fixed by the screen size, so we can adjust the height by changing the aspect ratio
        ),

        itemCount: vm.posts.length + (vm.isFetchingMore ? 1 : 0), // add one more item to show loading indicator icon when fetching more, if vm is fetching more, then item count is posts length + 1, otherwise it's just posts length

        itemBuilder: (context, index) {
          if (index >= vm.posts.length) {
            return const Center(
              child: CircularProgressIndicator(), // if index is greater than or equal to posts length, then show loading indicator icon
            );
          }

          final post = vm.posts[index];

          return PostCard(post: post); // if index is less than posts length(in range of viewable content posts), then show the post card
        } 
      )
    );
  }
}