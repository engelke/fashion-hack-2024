import 'package:flutter/material.dart';

class Logo extends StatelessWidget {
  final double size;
  final Color color;

  const Logo({
    super.key,
    this.size = 32,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final emojiSize = size * 0.875; // 28/32 ratio from original
    final textSize = size * 0.5625; // 18/32 ratio from original

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(size * 0.25),
              ),
              padding: EdgeInsets.all(size * 0.1875), // 6/32 ratio
              child: Text(
                '👕',
                style: TextStyle(fontSize: emojiSize),
              ),
            ),
            SizedBox(width: size * 0.1875), // 6/32 ratio
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(size * 0.25),
              ),
              padding: EdgeInsets.all(size * 0.1875),
              child: Text(
                '👗',
                style: TextStyle(fontSize: emojiSize),
              ),
            ),
          ],
        ),
        SizedBox(height: size * 0.25), // 8/32 ratio
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Fashion',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: textSize,
                fontWeight: FontWeight.w300,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(width: size * 0.09375), // 3/32 ratio
            Text(
              'Hack',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: textSize,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
