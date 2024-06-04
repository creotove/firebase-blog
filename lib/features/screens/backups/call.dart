// ignore_for_file: library_private_types_in_public_api, avoid_print

import 'package:flutter/material.dart';
import 'package:blog/authentication.dart';
import 'package:blog/features/screens/chat/call/audio_signaling.dart';

class CallPage extends StatefulWidget {
  final AuthenticationBloc authBloc;
  final String avatar;
  final String receiverName;
  final String roomId;
  final String currentUserId;
  final String receiverUserId;

  const CallPage({
    super.key,
    required this.authBloc,
    required this.avatar,
    required this.receiverName,
    required this.roomId,
    required this.currentUserId,
    required this.receiverUserId,
  });

  @override
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final AudioSignaling signaling = AudioSignaling();
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isHangingUp = false; // Prevent multiple calls to hangUp

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    if (!_isHangingUp) {
      // signaling.hangUp(widget.roomId);
    }
    super.dispose();
  }

  Future<void> _hangUp() async {
    if (!_isHangingUp) {
      _isHangingUp = true;
      // await signaling.hangUp(widget.roomId);
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      signaling.localStream?.getAudioTracks()[0].enabled = !_isMuted;
      print("Mic is now: ${_isMuted ? "Muted" : "Unmuted"}");
    });
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
      print("Speaker is now: ${_isSpeakerOn ? "On" : "Off"}");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.avatar),
              radius: 50,
            ),
            const SizedBox(height: 20),
            Text(
              widget.receiverName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
                  onPressed: _toggleMute,
                  color: _isMuted ? Colors.red : Colors.black,
                ),
                IconButton(
                  icon: const Icon(Icons.call_end),
                  onPressed: _hangUp,
                  color: Colors.red,
                ),
                IconButton(
                  icon: Icon(_isSpeakerOn ? Icons.volume_up : Icons.hearing),
                  onPressed: _toggleSpeaker,
                  color: _isSpeakerOn ? Colors.green : Colors.black,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
