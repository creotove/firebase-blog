// ignore_for_file: library_private_types_in_public_api

import 'package:blog/widgets/video_controls.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

// class FullScreenVideoPlayer extends StatefulWidget {
//   final VideoPlayerController controller;

//   const FullScreenVideoPlayer({super.key, required this.controller});

//   @override
//   State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
// }

// class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
//   @override
//   void initState() {
//     super.initState();
//     widget.controller.play();
//   }

//   @override
//   void dispose() {
//     widget.controller.pause();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: AspectRatio(
//           aspectRatio: widget.controller.value.aspectRatio,
//           child: Stack(
//             alignment: Alignment.bottomCenter,
//             children: [
//               GestureDetector(
//                 onTap: () {
//                   Navigator.pop(context);
//                 },
//                 child: VideoPlayer(widget.controller),
//               ),
//               VideoControls(controller: widget.controller),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

class FullScreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;

  const FullScreenVideoPlayer({super.key, required this.controller});

  @override
  _FullScreenVideoPlayerState createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _listener = () {
      if (mounted) setState(() {});
    };
    widget.controller.addListener(_listener);
  }

  @override
  void dispose() {
    widget.controller.pause();
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) => didPop ? widget.controller.pause() : null,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Video Player'),
        ),
        body: Dismissible(
          key: Key(widget.controller.dataSource),
          direction: DismissDirection.down,
          onDismissed: (direction) {
            Navigator.of(context).pop();
          },
          child: Center(
            child: AspectRatio(
              aspectRatio: widget.controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: VideoPlayer(widget.controller),
                  ),
                  VideoControls(controller: widget.controller),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
