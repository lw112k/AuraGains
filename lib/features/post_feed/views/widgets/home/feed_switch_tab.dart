import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auragains/features/post_feed/view_models/home/fyp_feed_viewmodel.dart';
import 'package:auragains/features/auth/view_models/auth_viewmodel.dart';

class FeedSwitchTab extends StatelessWidget {
  const FeedSwitchTab({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FypFeedViewModel>();

    final authVm = context.read<AuthViewModel>();
    final userId = authVm.currentUser!.id;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 10,
      ),

      child: Row(
        children: [

          Expanded(
            child: _TabButton(
              text: 'For You Page',

              isSelected: vm.selectedTab == 0,

              onPressed: () async {

                // 已经在 FYP
                if (vm.selectedTab == 0) {

                  await vm.refreshFeed(
                    userId: userId,
                  );

                  return;
                }

                vm.changeTab(0);
              },
            ),
          ),

          Expanded(
            child: _TabButton(
              text: 'Categories',

              isSelected: vm.selectedTab == 1,

              onPressed: () {
                vm.changeTab(1);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onPressed;

  const _TabButton({
    required this.text,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),

        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 2,
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // TEXT
              AnimatedDefaultTextStyle(
                duration:
                    const Duration(milliseconds: 220),

                style: TextStyle(
                  color: isSelected
                      ? Colors.cyanAccent
                      : Colors.white70,

                  fontSize: 16,

                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,

                  letterSpacing: 0.3,
                ),

                child: Text(text),
              ),

              const SizedBox(height: 8),

              // UNDERLINE
              AnimatedContainer(
                duration:
                    const Duration(milliseconds: 250),

                curve: Curves.easeOut,

                height: 3,

                width: isSelected ? 90 : 0,

                decoration: BoxDecoration(
                  color: Colors.cyanAccent,

                  borderRadius:
                      BorderRadius.circular(99),

                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            blurRadius: 12,
                            color: Colors.cyanAccent
                                .withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ]
                      : [],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}