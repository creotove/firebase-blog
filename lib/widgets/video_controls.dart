// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoControls extends StatefulWidget {
  final VideoPlayerController controller;

  const VideoControls({super.key, required this.controller});

  @override
  _VideoControlsState createState() => _VideoControlsState();
}

class _VideoControlsState extends State<VideoControls> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(
                widget.controller.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
              onPressed: () {
                setState(() {
                  if (widget.controller.value.isPlaying) {
                    widget.controller.pause();
                  } else {
                    widget.controller.play();
                  }
                });
              },
            ),
            IconButton(
              icon: Icon(widget.controller.value.volume == 0
                  ? Icons.volume_off
                  : Icons.volume_up),
              onPressed: () {
                setState(() {
                  widget.controller.setVolume(
                      widget.controller.value.volume == 0 ? 1.0 : 0.0);
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.fast_rewind),
              onPressed: () {
                widget.controller.seekTo(Duration(
                    seconds: widget.controller.value.position.inSeconds - 10));
              },
            ),
            IconButton(
              icon: const Icon(Icons.fast_forward),
              onPressed: () {
                widget.controller.seekTo(Duration(
                    seconds: widget.controller.value.position.inSeconds + 10));
              },
            ),
          ],
        ),
        VideoProgressIndicator(
          widget.controller,
          allowScrubbing: true,
          colors: const VideoProgressColors(
            playedColor: Colors.red,
            bufferedColor: Colors.grey,
            backgroundColor: Colors.black,
          ),
        ),
      ],
    );
  }
}
