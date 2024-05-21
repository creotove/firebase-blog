// import 'dart:io';

// import 'package:blog/features/screens/chat/message_sender_helper.dart';
// import 'package:flutter/material.dart';
// import 'package:blog/authentication.dart';
// import 'package:audioplayers/audioplayers.dart';

// class SendAudio extends StatefulWidget {
//   final File audio;
//   final AuthenticationBloc authBloc;
//   final String? receiverUserId;
//   final String? currentUserId;

//   const SendAudio({
//     super.key,
//     required this.audio,
//     required this.authBloc,
//     this.receiverUserId,
//     this.currentUserId,
//   });

//   @override
//   _SendAudioState createState() => _SendAudioState();
// }

// class _SendAudioState extends State<SendAudio> {
//   late AudioPlayer _audioPlayer;
//   bool _isPlaying = false;

//   @override
//   void initState() {
//     super.initState();
//     _audioPlayer = AudioPlayer();
//   }

//   @override
//   void dispose() {
//     _audioPlayer.dispose();
//     super.dispose();
//   }

//   void _playPauseAudio() async {
//     if (_isPlaying) {
//       await _audioPlayer.pause();
//     } else {
//       await _audioPlayer.play(widget.audio.path, isLocal: true);
//     }
//     setState(() {
//       _isPlaying = !_isPlaying;
//     });
//   }

//   void _sendAudio() {
//     MessageHelper().sendAudioMessage(
//       widget.audio,
//       widget.currentUserId!,
//       widget.receiverUserId!,
//     );
//     Navigator.pop(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Send Audio'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.send),
//             onPressed: _sendAudio,
//           ),
//         ],
//       ),
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           IconButton(
//             icon: Icon(
//               _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
//               size: 64,
//             ),
//             onPressed: _playPauseAudio,
//           ),
//           const SizedBox(height: 20),
//           const Text('Tap the icon to preview the audio.'),
//         ],
//       ),
//     );
//   }
// }

import 'dart:io';

import 'package:blog/features/screens/chat/message_sender_helper.dart';
import 'package:flutter/material.dart';
import 'package:blog/authentication.dart';

class SendAudio extends StatefulWidget {
  final File audio;
  final AuthenticationBloc authBloc;
  final String? receiverUserId;
  final String? currentUserId;

  const SendAudio({
    super.key,
    required this.audio,
    required this.authBloc,
    this.receiverUserId,
    this.currentUserId,
  });

  @override
  _SendAudioState createState() => _SendAudioState();
}

class _SendAudioState extends State<SendAudio> {
  void _sendAudio() {
    MessageHelper().sendAudioMessage(
      widget.audio,
      widget.currentUserId!,
      widget.receiverUserId!,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Audio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendAudio,
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 250,
            width: double.infinity,
            child: Icon(Icons.audiotrack, size: 100, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
