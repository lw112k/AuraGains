import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:auragains/features/auth/view_models/auth_viewmodel.dart';

import 'package:auragains/features/post_feed/view_models/home/switch_tab_viewmodel.dart';
import 'package:auragains/features/post_feed/view_models/home/fyp_viewmodel.dart';

import 'package:auragains/features/post_feed/views/widgets/home/feed_switch_tab.dart';
import 'package:auragains/features/post_feed/views/widgets/home/fyp_feed_list.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.read<AuthViewModel>();
    final userId = authVm.currentUser!.id;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SwitchTabViewModel(),
        ),

        ChangeNotifierProvider(
          create: (_) => FypViewModel(userId)
            ..loadFeed(),
        ),
      ],

      child: const _HomeViewBody(),
    );
  }
}

class _HomeViewBody extends StatelessWidget {
  const _HomeViewBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        FeedSwitchTab(),

        Expanded(
          child: FypFeedList(),
        ),
      ],
    );
  }
}