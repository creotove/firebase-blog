// import 'package:flutter/material.dart';
// import 'package:blog/authentication.dart';
// import 'package:blog/features/screens/chat/call/audio_signaling.dart';

// class CallPage extends StatefulWidget {
//   final AuthenticationBloc authBloc;
//   final String avatar;
//   final String receiverName;
//   final String roomId;
//   final String currentUserId;
//   final String receiverUserId;

//   const CallPage({
//     Key? key,
//     required this.authBloc,
//     required this.avatar,
//     required this.receiverName,
//     required this.roomId,
//     required this.currentUserId,
//     required this.receiverUserId,
//   }) : super(key: key);

//   @override
//   _CallPageState createState() => _CallPageState();
// }

// class _CallPageState extends State<CallPage> {
//   final AudioSignaling signaling = AudioSignaling();
//   bool _isMuted = false;
//   bool _isSpeakerOn = false;
//   bool _callActive = false;
//   bool _isHangingUp = false; // Prevent multiple calls to hangUp

//   @override
//   void initState() {
//     super.initState();
//     signaling.onAddRemoteStream = (stream) {
//       setState(() {
//         _callActive = true;
//       });
//     };
//     _checkCallTimeout();
//   }

//   @override
//   void dispose() {
//     if (!_isHangingUp) {
//       signaling.hangUp(widget.roomId);
//     }
//     super.dispose();
//   }

//   void _checkCallTimeout() {
//     Future.delayed(const Duration(seconds: 60), () {
//       if (!_callActive) {
//         print("Call timeout. Hanging up.");
//         _hangUp();
//       }
//     });
//   }

//   Future<void> _hangUp() async {
//     if (!_isHangingUp) {
//       _isHangingUp = true;
//       await signaling.hangUp(widget.roomId);
//       Navigator.pop(context);
//     }
//   }

//   void _toggleMute() {
//     setState(() {
//       _isMuted = !_isMuted;
//       signaling.localStream?.getAudioTracks()[0].enabled = !_isMuted;
//       print("Mic is now: ${_isMuted ? "Muted" : "Unmuted"}");
//     });
//   }

//   void _toggleSpeaker() {
//     setState(() {
//       _isSpeakerOn = !_isSpeakerOn;
//       print("Speaker is now: ${_isSpeakerOn ? "On" : "Off"}");
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.receiverName),
//         automaticallyImplyLeading: false,
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircleAvatar(
//               backgroundImage: NetworkImage(widget.avatar),
//               radius: 50,
//             ),
//             const SizedBox(height: 20),
//             Text(
//               widget.receiverName,
//               style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 20),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 IconButton(
//                   icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
//                   onPressed: _toggleMute,
//                   color: _isMuted ? Colors.red : Colors.black,
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.call_end),
//                   onPressed: _hangUp,
//                   color: Colors.red,
//                 ),
//                 IconButton(
//                   icon: Icon(_isSpeakerOn ? Icons.volume_up : Icons.hearing),
//                   onPressed: _toggleSpeaker,
//                   color: _isSpeakerOn ? Colors.green : Colors.black,
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:blog/authentication.dart';
import 'package:blog/features/screens/chat/call/audio_signaling.dart';
import 'dart:async';

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
  final AudioSignaling signaling = AudioSignaling();
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _callActive = false;
  bool _isHangingUp = false; // Prevent multiple calls to hangUp
  bool _userJoined = false; // Track if the user has joined the call
  int _secondsElapsed = 0; // Timer for call duration
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    signaling.onAddRemoteStream = (stream) {
      setState(() {
        _callActive = true;
        _userJoined = true;
      });
      _startTimer();
    };
    signaling.openUserMedia(); // Ensure user media is open
    signaling.joinRoom(widget.roomId);
    _checkCallTimeout();
  }

  @override
  void dispose() {
    if (!_isHangingUp) {
      signaling.hangUp(widget.roomId);
    }
    _timer?.cancel();
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

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
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
            Text(
              _userJoined
                  ? 'Call Duration: ${_formatDuration(_secondsElapsed)}'
                  : 'Ringing...',
              style: const TextStyle(fontSize: 20, color: Colors.grey),
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
