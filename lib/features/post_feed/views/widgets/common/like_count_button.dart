import 'package:flutter/material.dart';

class LikeCountButton extends StatelessWidget {

  final bool isLiked;
  final int likeCount;
  final Future<void> Function() onTap;

  final double iconSize;
  final double fontSize;
  final double gap;

  const LikeCountButton({
    super.key,
    required this.isLiked,
    required this.likeCount,
    required this.onTap,

    this.iconSize = 24, // default value suitable for post detail page
    this.fontSize = 14, // default value suitable for post detail page
    this.gap = 6,       // default value suitable for post detail page
  });

  @override
  Widget build(BuildContext context) {

    return InkWell(
      borderRadius: BorderRadius.circular(999),

      onTap: () async {
        await onTap();
      },

      child: Row(
        children: [

          Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,

            size: iconSize,

            color:isLiked ? Colors.cyanAccent : Colors.white,
          ),

          SizedBox(width: gap),

          Text(
            '$likeCount',

            style: TextStyle(
              fontSize: fontSize,

              color: isLiked ? Colors.cyanAccent : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}