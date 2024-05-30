import 'package:flutter/material.dart';

class CustomCircularImage extends StatelessWidget {
  final double size;
  final String userName;
  final String avatar;

  const CustomCircularImage(
      {super.key,
      required this.size,
      required this.userName,
      required this.avatar});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: avatar.isEmpty ? Colors.grey : Colors.transparent,
          image: !avatar.isEmpty
              ? null
              : DecorationImage(image: NetworkImage(avatar))),
      child: avatar.isEmpty
          ? const SizedBox()
          : Center(
              child: Text(userName[0].toUpperCase()),
            ),
    );
  }
}
