// ignore_for_file: library_private_types_in_public_api, avoid_print

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class CompactAudioPlayerWidget extends StatefulWidget {
  final String audioUrl;

  const CompactAudioPlayerWidget({super.key, required this.audioUrl});

  @override
  _CompactAudioPlayerWidgetState createState() =>
      _CompactAudioPlayerWidgetState();
}

class _CompactAudioPlayerWidgetState extends State<CompactAudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          duration = newDuration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          position = newPosition;
        });
      }
    });

    _loadAudio();
  }

  Future<void> _loadAudio() async {
    try {
      if (widget.audioUrl.isEmpty) {
        return;
      }
      await _audioPlayer.setSourceUrl(widget.audioUrl);
    } catch (e) {
      print(e);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(widget.audioUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            color: Colors.white,
          ),
          onPressed: _togglePlayPause,
        ),
        Expanded(
          child: Slider(
            activeColor: Colors.white,
            inactiveColor: Colors.grey[400],
            min: 0,
            max: duration.inSeconds.toDouble(),
            value: position.inSeconds.toDouble(),
            onChanged: (value) async {
              final newPosition = Duration(seconds: value.toInt());
              await _audioPlayer.seek(newPosition);
            },
          ),
        ),
        Text(
          '${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')} / '
          '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
