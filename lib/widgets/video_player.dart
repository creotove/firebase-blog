import 'package:flutter/material.dart';

class MyVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const MyVideoPlayer({super.key, required this.videoUrl});

  @override
  State<MyVideoPlayer> createState() => _MyVideoPlayerState();
}

class _MyVideoPlayerState extends State<MyVideoPlayer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Video Player'),
    );
  }
}
