import 'package:flutter/material.dart';

class BrandButton extends StatelessWidget {
  const BrandButton({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
    required this.onPressed,
    required this.textSize,
    this.height = 40,
    this.width = 150,
  });

  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback onPressed;
  final double height;
  final double width;
  final double textSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: textSize * 1.2),
            const SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: textSize,
                    fontFamily: 'Roboto',
                    shadows: [
                      Shadow(blurRadius: 20, color: color, offset: Offset.zero),
                    ],
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
