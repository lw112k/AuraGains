import 'package:flutter/material.dart';

class SaveCountButton extends StatelessWidget {
  final bool isSaved;
  final int saveCount;
  final Future<void> Function() onTap;

  final double iconSize;
  final double fontSize;
  final double gap;

  const SaveCountButton({
    super.key,
    required this.isSaved,
    required this.saveCount,
    required this.onTap,

    this.iconSize = 24,
    this.fontSize = 14,
    this.gap = 6,
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
            isSaved ? Icons.bookmark : Icons.bookmark_border,

            size: iconSize,

            color: isSaved ? Colors.cyanAccent : Colors.white,
          ),

          SizedBox(width: gap),

          Text(
            '$saveCount',

            style: TextStyle(
              fontSize: fontSize,

              color: isSaved ? Colors.cyanAccent : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}