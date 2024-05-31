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
    Key? key,
    required this.authBloc,
    required this.avatar,
    required this.receiverName,
    required this.roomId,
    required this.currentUserId,
    required this.receiverUserId,
  }) : super(key: key);

  @override
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final Signaling signaling = Signaling();
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _callActive = false;
  bool _isHangingUp = false;

  @override
  void initState() {
    super.initState();
    signaling.onAddRemoteStream = (stream) {
      setState(() {
        _callActive = true;
      });
    };
    // _startCall();
    _checkCallTimeout();
  }

  @override
  void dispose() {
    if (!_isHangingUp) {
      signaling.hangUp(widget.roomId);
    }
    super.dispose();
  }

  void _checkCallTimeout() {
    Future.delayed(const Duration(seconds: 60), () {
      if (!_callActive) {
        print("Call timeout. Hanging up.");
        _hangUp();
      }
    });
  }

  Future<void> _hangUp() async {
    if (!_isHangingUp) {
      _isHangingUp = true;
      await signaling.hangUp(widget.roomId);
      Navigator.pop(context);
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
