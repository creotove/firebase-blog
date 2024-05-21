import 'package:blog/theme/app_pallete.dart';
import 'package:flutter/material.dart';

class ChatSendFile extends StatelessWidget {
  final IconData icon;
  final String text;
  final void Function()? onPressed;

  ChatSendFile(
      {super.key,
      required this.icon,
      required this.text,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          color: AppPallete.gradient2),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            IconButton(
              icon: Icon(icon),
              color: Colors.white,
              onPressed: onPressed,
            ),
            Text(
              text,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
