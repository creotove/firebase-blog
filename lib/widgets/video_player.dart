// ignore_for_file: library_private_types_in_public_api

import 'package:blog/features/screens/chat/show_send_video.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CompactVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const CompactVideoPlayer({super.key, required this.videoUrl});

  @override
  _CompactVideoPlayerState createState() => _CompactVideoPlayerState();
}

class _CompactVideoPlayerState extends State<CompactVideoPlayer> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  bool _showProgressIndicator = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayerFuture = _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    final fileInfo = await DefaultCacheManager().getSingleFile(widget.videoUrl);
    _controller = VideoPlayerController.file(fileInfo);
    await _controller.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Column(
            children: [
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _controller.pause();
                        setState(() {
                          _showProgressIndicator = true;
                        });
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullScreenVideoPlayer(
                              controller: _controller,
                            ),
                          ),
                        ).then((_) {
                          setState(() {
                            _showProgressIndicator = false;
                          });
                        });
                      },
                      child: VideoPlayer(_controller),
                    ),
                    if (_showProgressIndicator)
                      VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: Colors.red,
                          bufferedColor: Colors.grey,
                          backgroundColor: Colors.black,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      _controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_controller.value.isPlaying) {
                          _controller.pause();
                        } else {
                          _controller.play();
                        }
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.fullscreen),
                    onPressed: () {
                      _controller.pause();
                      setState(() {
                        _showProgressIndicator = true;
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenVideoPlayer(
                            controller: _controller,
                          ),
                        ),
                      ).then((_) {
                        setState(() {
                          _showProgressIndicator = false;
                        });
                      });
                    },
                  ),
                ],
              ),
            ],
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
